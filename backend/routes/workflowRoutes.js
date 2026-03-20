const express = require('express');
const DocumentType = require('../models/DocumentType');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');

const router = express.Router();

// @desc    Get all document types/flows
// @route   GET /api/workflow
// @access  Public (for students to see available types)
router.get('/', async (req, res) => {
  try {
    const flows = await DocumentType.find({ isActive: true });
    res.json(flows);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Create new document flow
// @route   POST /api/workflow
// @access  Private (Admin only)
router.post('/', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { name, steps, isFormBased, requiredFields } = req.body;
    const flowExists = await DocumentType.findOne({ name });
    if (flowExists) {
      return res.status(400).json({ message: 'Document type already exists' });
    }
    const flow = await DocumentType.create({ name, steps, isFormBased, requiredFields });
    res.status(201).json(flow);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Update document flow
// @route   PUT /api/workflow/:id
// @access  Private (Admin only)
router.put('/:id', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const { name, steps, isActive, isFormBased, requiredFields } = req.body;
    const flow = await DocumentType.findById(req.params.id);
    if (flow) {
      flow.name = name || flow.name;
      flow.steps = steps || flow.steps;
      if (isActive !== undefined) flow.isActive = isActive;
      if (isFormBased !== undefined) flow.isFormBased = isFormBased;
      if (requiredFields) flow.requiredFields = requiredFields;
      const updatedFlow = await flow.save();
      res.json(updatedFlow);
    } else {
      res.status(404).json({ message: 'Flow not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @desc    Delete document flow
// @route   DELETE /api/workflow/:id
// @access  Private (Admin only)
router.delete('/:id', protect, authorizeRoles('admin'), async (req, res) => {
  try {
    const flow = await DocumentType.findById(req.params.id);
    if (flow) {
      await flow.deleteOne();
      res.json({ message: 'Flow removed' });
    } else {
      res.status(404).json({ message: 'Flow not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
