const { createModel, getModel } = require('../config/driveModel');

module.exports = createModel({
  modelName: 'Notification',
  collection: 'notifications',
  defaults: {
    read: false,
    type: 'info',
  },
  refs: {
    userId: () => getModel('User'),
  },
});
