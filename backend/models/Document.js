const crypto = require('crypto');
const { createModel, getModel } = require('../config/driveModel');

const Document = createModel({
  modelName: 'Document',
  collection: 'documents',
  defaults: {
    customHeading: '',
    description: '',
    status: 'pending',
    workflow: [],
    approvals: [],
    assigned: {},
    formData: {},
  },
  refs: {
    studentId: () => getModel('User'),
    'approvals.approverId': () => getModel('User'),
  },
});

const originalSave = Document.prototype.save;
Document.prototype.save = async function saveWithCode() {
  if (!this.documentCode) {
    this.documentCode = crypto.randomBytes(4).toString('hex').toUpperCase();
  }
  return originalSave.call(this);
};

module.exports = Document;
