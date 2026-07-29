const { createModel, getModel } = require('../config/driveModel');

module.exports = createModel({
  modelName: 'DutyCategory',
  collection: 'workflow',
  baseFilter: { __kind: 'duty_category' },
  defaults: {
    description: '',
    isActive: true,
  },
  refs: {
    facultyInChargeId: () => getModel('User'),
  },
});
