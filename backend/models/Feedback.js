const { createModel, getModel } = require('../config/driveModel');

module.exports = createModel({
  modelName: 'Feedback',
  collection: 'feedback',
  defaults: {
    type: 'feedback',
    status: 'open',
  },
  refs: {
    user: () => getModel('User'),
  },
});
