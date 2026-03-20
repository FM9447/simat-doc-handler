const mongoose = require('mongoose');

const approvalSchema = mongoose.Schema({
  approverId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  action: { type: String, enum: ['approved', 'rejected', 'forwarded'], required: true },
  comment: { type: String },
  signatureUrl: { type: String }, // Stored in Cloudinary
}, { timestamps: true });

const documentSchema = mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  category: { 
    type: String, 
    required: true
  },
  priority: { 
    type: String, 
    required: true,
    enum: ['low', 'medium', 'high', 'urgent']
  },
  status: { 
    type: String, 
    required: true,
    default: 'pending'
  },
  fileUrl: { type: String }, // PDF or Image link
  rejectionReason: { type: String },
  formData: { type: Map, of: String }, // Stores { 'Reason': 'Higher Studies', 'Year': '2024' }
  workflow: [{ type: String }], // Array of approver IDs (can be ObjectIds or mock IDs)
  approvals: [approvalSchema],
}, {
  timestamps: true,
});

const Document = mongoose.model('Document', documentSchema);
module.exports = Document;
