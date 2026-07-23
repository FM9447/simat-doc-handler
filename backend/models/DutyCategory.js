const mongoose = require('mongoose');

const dutyCategorySchema = mongoose.Schema({
  name: { type: String, required: true, unique: true }, // e.g. IEDC, NSS, MuLearn, IEEE, Sports, Arts
  code: { type: String, required: true, unique: true }, // e.g. iedc, nss, mulearn
  description: { type: String, default: '' },
  facultyInChargeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Assigned Faculty / Nodal Officer
  isActive: { type: Boolean, default: true },
}, {
  timestamps: true,
});

const DutyCategory = mongoose.model('DutyCategory', dutyCategorySchema);
module.exports = DutyCategory;
