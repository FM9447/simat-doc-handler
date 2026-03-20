const mongoose = require('mongoose');

const userSchema = mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { 
    type: String, 
    required: true, 
    enum: ['student', 'teacher', 'hod', 'principal', 'office', 'admin'],
    default: 'student'
  },
  registerNo: { type: String }, // For students
  dept: { type: String },       // For students, teachers, HODs
  signatureUrl: { type: String }, // Stored in Cloudinary
  isApproved: { type: Boolean, default: false }
}, {
  timestamps: true,
});

const User = mongoose.model('User', userSchema);
module.exports = User;
