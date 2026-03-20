const express = require('express');
const router = express.Router();
const Document = require('../models/Document');
const DocumentType = require('../models/DocumentType');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const { upload } = require('../config/cloudinary');

// @desc    Create a new document request
// @route   POST /api/documents
// @access  Private (Student only)
router.post('/', protect, authorizeRoles('student'), upload.single('file'), async (req, res) => {
  try {
    const { title, description, category, priority, formData } = req.body;
    
    // Parse formData if it's stringified from the frontend
    let parsedFormData = formData;
    if (typeof formData === 'string') {
      try { parsedFormData = JSON.parse(formData); } catch (e) {}
    }
    
    // Fetch dynamic workflow from DocumentType model
    const flowDef = await DocumentType.findOne({ name: category, isActive: true });
    if (!flowDef) {
       return res.status(400).json({ message: `Workflow not defined for document type: ${category}` });
    }
    const workflow = flowDef.steps;

    console.log('Document creation attempt with category:', category);
    
    const document = new Document({
      studentId: req.user.id,
      title,
      description,
      category,
      priority,
      status: 'pending',
      formData: parsedFormData,
      workflow, // Array of roles from flowDef
      fileUrl: req.file ? (req.file.path.startsWith('http') ? req.file.path : `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`) : null,
    });

    const createdDoc = await document.save();
    console.log('Document created successfully with dynamic workflow:', createdDoc._id);
    res.status(201).json(createdDoc);
  } catch (error) {
    console.error('Document creation 500 error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @desc    Get documents for user (student sees theirs, others see queue/approved)
// @route   GET /api/documents
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    let docs;
    if (req.user.role === 'student') {
      docs = await Document.find({ studentId: req.user.id }).populate('studentId', 'name registerNo dept');
    } else {
      // Teachers/HODs/Principals see documents assigned to their workflow 
      // AND that they haven't approved yet
      docs = await Document.find({ 
        $and: [
          { $or: [
            { workflow: req.user.id },
            { workflow: req.user.name },
            { workflow: req.user.role },
          ]},
          { 'approvals.approverId': { $ne: req.user.id } }
        ]
      }).populate('studentId', 'name registerNo dept').populate('approvals.approverId', 'name role');
    }
    res.json(docs);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Add approval/rejection to document
// @route   POST /api/documents/:id/approve
// @access  Private
router.post('/:id/approve', protect, upload.single('signature'), async (req, res) => {
  try {
    const { action, comment, signatureUrl: bodySignatureUrl } = req.body;
    const document = await Document.findById(req.params.id);

    if (!document) {
      return res.status(404).json({ message: 'Document not found' });
    }

    let signatureUrl = null;
    if (req.file) {
      signatureUrl = req.file.path.startsWith('http') 
        ? req.file.path 
        : `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
    } else if (bodySignatureUrl) {
      signatureUrl = bodySignatureUrl;
    }

    // Create approval record
    const approvalRecord = {
      approverId: req.user.id,
      action,
      comment,
      signatureUrl: signatureUrl,
    };
    
    document.approvals.push(approvalRecord);

    // Determine new status
    if (action === 'rejected') {
      document.status = 'rejected';
      document.rejectionReason = comment;
    } else {
      // Check if all needed persons have signed
      if (document.approvals.length >= document.workflow.length) {
        document.status = 'final_approved';
      } else {
        document.status = 'partially_approved';
      }
    }

    const updatedDoc = await document.save();
    res.json(updatedDoc);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
