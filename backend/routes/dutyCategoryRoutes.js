const express = require('express');
const router = express.Router();
const DutyCategory = require('../models/DutyCategory');
const User = require('../models/User');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');

// @desc    Get all duty leave categories
// @route   GET /api/duty-categories
// @access  Public / Private
router.get('/', async (req, res) => {
  try {
    const categories = await DutyCategory.find({ isActive: true })
      .populate('facultyInChargeId', 'name email role dept departmentId');
    res.json(categories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Get all duty leave categories (Admin including inactive)
// @route   GET /api/duty-categories/admin
// @access  Private (Admin only)
router.get('/admin', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const categories = await DutyCategory.find({})
      .populate('facultyInChargeId', 'name email role dept departmentId');
    res.json(categories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Create a new duty leave category
// @route   POST /api/duty-categories
// @access  Private (Admin only)
router.post('/', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { name, code, description, facultyInChargeId } = req.body;

    const existing = await DutyCategory.findOne({ 
      $or: [{ name: name.trim() }, { code: (code || name).toLowerCase().trim() }] 
    });
    if (existing) {
      return res.status(400).json({ message: 'Duty category with this name or code already exists' });
    }

    const category = await DutyCategory.create({
      name: name.trim(),
      code: (code || name).toLowerCase().trim().replaceAll(' ', '_'),
      description: description || '',
      facultyInChargeId: facultyInChargeId || null,
      isActive: true,
    });

    const populated = await DutyCategory.findById(category._id)
      .populate('facultyInChargeId', 'name email role dept departmentId');

    res.status(201).json(populated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Update a duty leave category / assign faculty
// @route   PUT /api/duty-categories/:id
// @access  Private (Admin only)
router.put('/:id', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { name, description, facultyInChargeId, isActive } = req.body;
    const category = await DutyCategory.findById(req.params.id);

    if (!category) {
      return res.status(404).json({ message: 'Duty category not found' });
    }

    if (name) category.name = name.trim();
    if (description !== undefined) category.description = description;
    if (facultyInChargeId !== undefined) category.facultyInChargeId = facultyInChargeId || null;
    if (isActive !== undefined) category.isActive = isActive;

    await category.save();

    const populated = await DutyCategory.findById(category._id)
      .populate('facultyInChargeId', 'name email role dept departmentId');

    res.json(populated);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Delete a duty leave category
// @route   DELETE /api/duty-categories/:id
// @access  Private (Admin only)
router.delete('/:id', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const category = await DutyCategory.findByIdAndDelete(req.params.id);
    if (!category) {
      return res.status(404).json({ message: 'Duty category not found' });
    }
    res.json({ message: 'Duty category deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
