const { createModel } = require('../config/driveModel');

module.exports = createModel({
  modelName: 'DocumentType',
  collection: 'workflow',
  baseFilter: { __kind: 'document_type' },
  defaults: {
    steps: [],
    elements: [],
    letterTemplate: '',
    allowCustomHeading: false,
    includeLetterhead: true,
    includeRefDate: true,
    includeSeal: false,
    isFormBased: false,
    requiredFields: [],
    isActive: true,
  },
});
