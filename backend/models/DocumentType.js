const mongoose = require('mongoose');

const documentTypeSchema = mongoose.Schema({
  name: { type: String, required: true, unique: true },
  steps: [{ 
    type: String, 
    enum: ['teacher', 'hod', 'principal', 'office', 'admin'],
    required: true 
  }],
  isFormBased: { type: Boolean, default: false },
  requiredFields: [{ type: String }], // e.g. ['Reason', 'Semester', 'Year']
  isActive: { type: Boolean, default: true }
}, {
  timestamps: true,
});

const DocumentType = mongoose.model('DocumentType', documentTypeSchema);
module.exports = DocumentType;
