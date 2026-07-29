const express = require('express');
const User = require('../models/User');
const multer = require('multer');
const XLSX = require('xlsx');
const { upload } = require('../config/cloudinary');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const NotificationService = require('../services/notificationService');
const { callDriveDb, encodeSessionToken, sha256Hex } = require('../config/driveDb');

// Multer for in-memory Excel/CSV uploads (admin bulk import)
const memUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

const router = express.Router();

const generateToken = (user) => {
  return encodeSessionToken({
    _id: user._id || user.id,
    email: user.email,
    role: user.role,
    iat: Date.now(),
  });
};

// @desc    Get API Version
// @route   GET /api/auth/version
router.get('/version', (req, res) => {
  res.json({ version: '1.0.1', deployedAt: '2026-03-27' });
});

// @desc    Get user by ID (Admin only)
// @route   GET /api/auth/users/:id
router.get('/users/:id', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-password')
      .populate('departmentId', 'name')
      .populate('tutorId', 'name email');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Delete user with reassignment (Admin only)
// @route   DELETE /api/auth/users/:id
router.delete('/users/:id', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const userId = req.params.id;
    const reassignToId = req.query.reassignToId || req.body.reassignToId;
    const Document = require('../models/Document');
    const Department = require('../models/Department');

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (['tutor', 'hod', 'principal', 'office'].includes(user.role)) {
      if (!reassignToId) {
        return res.status(400).json({ message: `Staff account (${user.role.toUpperCase()}) requires a reassignment target.` });
      }
      const target = await User.findById(reassignToId);
      if (!target) return res.status(404).json({ message: 'Reassignment target user not found' });
      
      await Document.updateMany({ [`assigned.${user.role}.id`]: userId }, { $set: { [`assigned.${user.role}.id`]: target._id, [`assigned.${user.role}.name`]: target.name } });
      if (user.role === 'tutor') await User.updateMany({ tutorId: userId }, { $set: { tutorId: target._id } });
      if (user.role === 'hod') await Department.updateMany({ hodId: userId }, { $set: { hodId: target._id } });
    }
    await User.findByIdAndDelete(userId);
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Register a new user (ADMIN ONLY — public registration removed)
// @route   POST /api/auth/register
// @access  Private (Admin only)
router.post('/register', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { name, email, password, role, registerNo, dept, departmentId, tutorId, year, division } = req.body;

    const userExists = await User.findOne({ email });

    if (userExists) {
      console.log('Registration failed: User already exists', email);
      return res.status(400).json({ message: 'User already exists' });
    }

    // Security: Prevent public registration as 'admin' or 'principal'
    let finalRole = role === 'teacher' ? 'tutor' : role;
    if (finalRole === 'admin' || finalRole === 'principal') {
      finalRole = 'student'; // Silently downgrade
    }

    // Students are auto-approved; staff roles (tutor, HOD, office) require admin approval
    const isApproved = finalRole === 'student';

    const registerResult = await callDriveDb('auth_register', 'users', {
      name, email, password, role: finalRole,
      registerNo, dept, departmentId, tutorId, year, division,
      isApproved
    });
    const user = await User.findById(registerResult?.data?._id) || registerResult?.data;

    if (user) {
      res.status(201).json({
        _id: user._id, name: user.name, email: user.email, role: user.role, 
        dept: user.dept, departmentId: user.departmentId, tutorId: user.tutorId,
        year: user.year, division: user.division,
        signatureUrl: user.signatureUrl,
        isApproved: user.isApproved,
        delegatedTo: user.delegatedTo,
        token: generateToken(user),
      });

      // Notify Admin about new registration
      User.find({ role: 'admin' }).then(admins => {
        const message = `New user registration: ${user.name} (${user.role})`;
        admins.forEach(adminUser => {
          NotificationService.send(adminUser._id, message, 'info');
        });
      });
    } else {
      res.status(400).json({ message: 'Invalid user data' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Authenticate a user
// @route   POST /api/auth/login
// @access  Public
router.post('/login', async (req, res) => {
  try {
    console.log('Login attempt:', req.body.email);
    const { email, password } = req.body;
    let authResult;
    try {
      authResult = await callDriveDb('auth_login', 'users', { email, password });
    } catch (_) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const authUser = authResult?.user || {};
    const user = await User.findById(authUser._id) || await User.findOne({ email });

    if (user) {
      if (user.role === 'student' && !user.isApproved) {
        user.isApproved = true;
        await user.save();
      }
      if (!user.isApproved && user.role !== 'admin' && user.role !== 'student') {
        return res.status(401).json({ message: 'Your account is pending approval by an administrator.' });
      }
      res.json({
        _id: user._id, name: user.name, email: user.email, role: user.role,
        dept: user.dept, departmentId: user.departmentId, tutorId: user.tutorId,
        year: user.year, division: user.division,
        signatureUrl: user.signatureUrl,
        isApproved: user.isApproved,
        delegatedTo: user.delegatedTo,
        token: authResult?.token || generateToken(user),
      });
    } else {
      res.status(401).json({ message: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Get tutors by department
// @route   GET /api/auth/tutors?deptId=...
// @access  Public (Needed for registration)
router.get('/tutors', async (req, res) => {
  try {
    const { deptId } = req.query;
    console.log('DEBUG: Fetching tutors for dept:', deptId);
    const query = { role: 'tutor' }; 
    if (deptId) query.departmentId = deptId;
    
    const tutors = await User.find(query).select('name email _id');
    res.json(tutors);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Get user profile
// @route   GET /api/auth/profile
// @access  Private
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('departmentId', 'name')
      .populate('tutorId', 'name email')
      .populate('delegatedTo', 'name email role')
      .select('-password');
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
router.put('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const { name, email, departmentId, tutorId, year, division } = req.body;
    
    if (name) user.name = name;
    if (email) user.email = email;
    if (departmentId !== undefined) user.departmentId = departmentId;
    if (tutorId !== undefined) user.tutorId = tutorId;
    if (year !== undefined) user.year = year;
    if (division !== undefined) user.division = division;

    const updatedUser = await user.save();
    
    const populatedUser = await User.findById(updatedUser._id)
      .populate('departmentId', 'name')
      .populate('tutorId', 'name email')
      .populate('delegatedTo', 'name email role')
      .select('-password');
    
    res.json(populatedUser);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Change user password
// @route   PUT /api/auth/password
// @access  Private
router.put('/password', protect, async (req, res) => {
  try {
    const { oldPassword, newPassword } = req.body;
    const user = await User.findById(req.user._id);

    try {
      await callDriveDb('auth_login', 'users', { email: user.email, password: oldPassword });
    } catch (_) {
      return res.status(401).json({ message: 'Invalid old password' });
    }

    if (user) {
      user.password = sha256Hex(newPassword);
      await user.save();
      res.json({ message: 'Password updated successfully' });
    } else {
      res.status(401).json({ message: 'Invalid old password' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Upload digital signature
// @route   POST /api/auth/signature
// @access  Private
router.post('/signature', protect, upload.single('signature'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const fileUrl = req.file.path.startsWith('http') 
      ? req.file.path 
      : `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

    const user = await User.findById(req.user._id);
    user.signatureUrl = fileUrl;
    await user.save();

    res.json({ 
      message: 'Signature uploaded successfully',
      signatureUrl: fileUrl 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Get all users (Admin only)
// @route   GET /api/auth/users
router.get('/users', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const users = await User.find({})
      .select('-password')
      .populate('departmentId', 'name')
      .populate('tutorId', 'name email');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Get colleagues (same role) for delegation
// @route   GET /api/auth/colleagues
// @access  Private
router.get('/colleagues', protect, async (req, res) => {
  try {
    let query = { _id: { $ne: req.user._id }, isApproved: true };
    const userRole = req.user.role;

    if (userRole === 'tutor') {
      // Tutors can delegate to fellow tutors in same dept
      query.role = 'tutor';
      query.departmentId = req.user.departmentId;
    } else if (userRole === 'hod') {
      // HODs can delegate to ANY tutor
      query.role = 'tutor';
    } else if (userRole === 'principal') {
      // Principals can delegate to other Principals or Office
      query.role = { $in: ['principal', 'office'] };
    } else if (userRole === 'office') {
      // Office can delegate to other Office staff
      query.role = 'office';
    } else {
      // For other roles, they cannot delegate to anyone
      return res.status(403).json({ message: 'This role is not allowed to delegate' });
    }

    const users = await User.find(query).select('name email role');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Approve/Unapprove user (Admin only)
// @route   PUT /api/auth/users/:id/approve
router.put('/users/:id/approve', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { isApproved } = req.body;
    const user = await User.findById(req.params.id);
    if (user) {
      user.isApproved = isApproved;
      await user.save();
      
      if (isApproved) {
        await NotificationService.send(user._id, 'Your account has been approved! You can now log in and use the system.', 'ok');
      }
      
      res.json({ message: `User ${isApproved ? 'approved' : 'unapproved'} successfully` });
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Update user properties (Admin only)
// @route   PUT /api/auth/users/:id
router.put('/users/:id', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { role, dept, isApproved, departmentId, tutorId, year, division } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (role) {
      const finalRole = role === 'teacher' ? 'tutor' : role;
      if (finalRole === 'principal' && user.role !== 'principal' && user.role === 'student') {
        return res.status(400).json({ message: 'Students cannot be promoted directly to Principal. Promote to Tutor/HOD first.' });
      }
      user.role = finalRole;
    }
    if (dept !== undefined) user.dept = dept;
    if (isApproved !== undefined) user.isApproved = isApproved;
    
    if (user.role === 'principal' && user.isApproved === true) {
      await User.updateMany(
        { _id: { $ne: user._id }, role: 'principal' },
        { $set: { isApproved: false } }
      );
    }
    if (departmentId !== undefined) user.departmentId = departmentId;
    if (tutorId !== undefined) user.tutorId = tutorId;
    if (year !== undefined) user.year = year;
    if (division !== undefined) user.division = division;

    await user.save();
    res.json({ message: 'User updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Clear all students and document requests (Admin only)
// @route   DELETE /api/auth/clear-students-requests
router.delete('/clear-students-requests', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const Document = require('../models/Document');
    const Notification = require('../models/Notification');

    const docResult = await Document.deleteMany({});
    const studentResult = await User.deleteMany({ role: 'student' });
    await Notification.deleteMany({});

    res.json({
      message: 'Successfully cleared all student accounts and document requests.',
      deletedDocuments: docResult.deletedCount,
      deletedStudents: studentResult.deletedCount,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});



// ─────────────────────────────────────────────────────────────────────────
// ADMIN USER CREATION
// ─────────────────────────────────────────────────────────────────────────

// @desc    Create a single user (Admin only)
// @route   POST /api/auth/admin/create-user
// @access  Private (Admin only)
router.post('/admin/create-user', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { name, email, password, role, registerNo, dept, departmentId, tutorId, year, division } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({ message: 'name, email, password and role are required' });
    }

    const exists = await User.findOne({ email: email.toLowerCase().trim() });
    if (exists) return res.status(400).json({ message: `User with email ${email} already exists` });

    const finalRole = role === 'teacher' ? 'tutor' : role;

    const registerResult = await callDriveDb('auth_register', 'users', {
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role: finalRole,
      registerNo, dept, departmentId, tutorId, year, division,
      isApproved: true, // Admin-created users are pre-approved
    });
    const user = await User.findById(registerResult?.data?._id) || registerResult?.data;

    res.status(201).json({
      message: `User ${user.name} created successfully`,
      _id: user._id, name: user.name, email: user.email, role: user.role, isApproved: true,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Download Excel template for bulk import (Admin only)
// @route   GET /api/auth/admin/bulk-import-template
// @access  Public (or Private if token can be sent, but usually for download a public or query token is easier. Let's make it public for ease of download link, it only returns a blank template)
router.get('/admin/bulk-import-template', (req, res) => {
  try {
    const templateData = [
      {
        name: 'John Doe',
        email: 'john@simat.ac.in',
        password: 'password123',
        role: 'student',
        registerNo: 'SIM21CS001',
        dept: 'CSE',
        year: 3,
        division: 'A',
        tutorEmail: 'tutor@simat.ac.in',
        departmentId: '', // Optional
      }
    ];

    const ws = XLSX.utils.json_to_sheet(templateData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Users');

    const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

    res.setHeader('Content-Disposition', 'attachment; filename="DocTransit_Users_Template.xlsx"');
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.send(buffer);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Bulk import users from Excel/CSV (Admin only)
// @route   POST /api/auth/admin/bulk-import
// @access  Private (Admin only)
// Expected columns: name | email | password | role | registerNo | dept | year | division | departmentId | tutorEmail
router.post('/admin/bulk-import', protect, authorizeRoles('admin'), memUpload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded. Send file as multipart/form-data field named "file".' });

    // Parse workbook
    const workbook = XLSX.read(req.file.buffer, { type: 'buffer' });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = XLSX.utils.sheet_to_json(sheet, { defval: '' });

    if (!rows.length) return res.status(400).json({ message: 'File is empty or has no data rows.' });

    const results = { created: 0, skipped: 0, errors: [] };

    for (const [idx, row] of rows.entries()) {
      const rowNum = idx + 2; // Row 1 = header
      const name  = (row['name'] || row['Name'] || '').toString().trim();
      const email = (row['email'] || row['Email'] || '').toString().trim().toLowerCase();
      const password = (row['password'] || row['Password'] || '').toString().trim();
      const role  = (row['role'] || row['Role'] || 'student').toString().trim().toLowerCase();
      const registerNo = (row['registerNo'] || row['RegisterNo'] || row['register_no'] || '').toString().trim();
      const dept  = (row['dept'] || row['Dept'] || row['department'] || '').toString().trim();
      const year  = (row['year'] || row['Year'] || '').toString().trim();
      const division = (row['division'] || row['Division'] || '').toString().trim();
      const tutorEmail = (row['tutorEmail'] || row['TutorEmail'] || row['tutor_email'] || '').toString().trim();
      let departmentId = (row['departmentId'] || row['DepartmentId'] || '').toString().trim();

      if (!name || !email || !password) {
        results.errors.push(`Row ${rowNum}: name, email, and password are required.`);
        continue;
      }

      const exists = await User.findOne({ email });
      if (exists) { results.skipped++; continue; }

      // Resolve tutorEmail → tutorId
      let tutorId;
      if (tutorEmail) {
        const tutor = await User.findOne({ email: tutorEmail, role: { $in: ['tutor', 'teacher'] } });
        if (tutor) tutorId = tutor._id;
      }

      try {
        const finalRole = role === 'teacher' ? 'tutor' : role;

        await callDriveDb('auth_register', 'users', {
          name, email, password,
          role: finalRole, registerNo, dept, year, division,
          departmentId: departmentId || undefined,
          tutorId: tutorId || undefined,
          isApproved: true,
        });
        results.created++;
      } catch (e) {
        results.errors.push(`Row ${rowNum} (${email}): ${e.message}`);
      }
    }

    res.json({
      message: `Import complete: ${results.created} created, ${results.skipped} skipped (already exist), ${results.errors.length} errors.`,
      ...results,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ─────────────────────────────────────────────────────────────────────────

// @desc    Update FCM Token
// @route   POST /api/auth/fcm-token
// @access  Private
router.post('/fcm-token', protect, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(400).json({ message: 'Token is required' });

    await User.updateMany(
      { fcmTokens: token, _id: { $ne: req.user._id } },
      { $pull: { fcmTokens: token } }
    );

    const user = await User.findById(req.user._id);
    if (!user.fcmTokens.includes(token)) {
      user.fcmTokens.push(token);
      await user.save();
    }
    res.json({ message: 'FCM Token updated and synchronized successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Set/Clear Role Delegation (Vacation Mode)
// @route   PUT /api/auth/delegate
// @access  Private
router.put('/delegate', protect, async (req, res) => {
  try {
    const { delegatedToId } = req.body;
    const Document = require('../models/Document');

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (delegatedToId) {
      const delegate = await User.findById(delegatedToId);
      if (!delegate) return res.status(404).json({ message: 'Delegate user not found' });
      
      // Role validation logic (updated per user request)
      let isValid = false;
      const uRole = user.role;
      const dRole = delegate.role;

      if (uRole === 'tutor' && dRole === 'tutor' && String(delegate.departmentId || '') === String(user.departmentId || '')) {
        isValid = true;
      } else if (uRole === 'hod' && dRole === 'tutor') {
        // HOD can delegate to ANY tutor
        isValid = true;
      } else if (uRole === 'principal' && (dRole === 'principal' || dRole === 'office')) {
        // Principal can delegate to another Principal or Office
        isValid = true;
      } else if (uRole === 'office' && dRole === 'office') {
        isValid = true;
      } else if (uRole === 'admin') {
        isValid = true;
      }

      if (!isValid) {
        return res.status(400).json({ message: `Invalid delegate: ${uRole.toUpperCase()} cannot delegate to ${dRole.toUpperCase()}${uRole === 'tutor' ? ' in a different department' : ''}` });
      }

      user.delegatedTo = delegatedToId;

      // Transfer CURRENT pending requests
      const documents = await Document.find({ 
        [`assigned.${user.role}.id`]: user._id,
        status: { $in: ['pending', 'partially_approved'] }
      });

      console.log(`Delegation: Transferring ${documents.length} documents from ${user.name} to ${delegate.name}`);

      for (const doc of documents) {
        // Update the assignment to the delegate's info
        doc.assigned[user.role] = { id: delegatedToId, name: delegate.name };
        doc.markModified('assigned');
        
        doc.approvals.push({
          approverId: user._id,
          role: user.role,
          action: 'forwarded',
          comment: `System: Auto-delegated to ${delegate.name} (Vacation Mode).`,
        });
        
        await doc.save();
        // Notify the delegate
        await NotificationService.send(delegatedToId, `Action Required: Document "${doc.title}" delegated to you from ${user.name}.`, 'info');
      }
    } else {
      user.delegatedTo = undefined;
    }

    await user.save();
    res.json({ message: 'Delegation settings updated successfully', delegatedTo: user.delegatedTo });
  } catch (error) {
    console.error('Delegation error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
