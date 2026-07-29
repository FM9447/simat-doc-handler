const { createModel, getModel } = require('../config/driveModel');

module.exports = createModel({
  modelName: 'User',
  collection: 'users',
  defaults: {
    role: 'student',
    isApproved: false,
    fcmTokens: [],
  },
  refs: {
    departmentId: () => getModel('Department'),
    tutorId: () => getModel('User'),
    delegatedTo: () => getModel('User'),
    hodOfDeptId: () => getModel('Department'),
  },
});
