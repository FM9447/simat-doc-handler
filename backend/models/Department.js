const { createModel, getModel } = require('../config/driveModel');

module.exports = createModel({
  modelName: 'Department',
  collection: 'workflow',
  baseFilter: { __kind: 'department' },
  refs: {
    hodId: () => getModel('User'),
  },
});
