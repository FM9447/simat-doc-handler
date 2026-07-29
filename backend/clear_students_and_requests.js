require('dotenv').config();

const User = require('./models/User');
const Document = require('./models/Document');
const Notification = require('./models/Notification');

const clearStudentsAndRequests = async () => {
  try {
    const docResult = await Document.deleteMany({});
    console.log(`✅ Cleared ${docResult.deletedCount} document requests.`);

    const studentResult = await User.deleteMany({ role: 'student' });
    console.log(`✅ Cleared ${studentResult.deletedCount} student accounts.`);

    const notifResult = await Notification.deleteMany({});
    console.log(`✅ Cleared ${notifResult.deletedCount} notifications.`);

    console.log('🎉 Cleanup completed successfully! Staff and Admin accounts were preserved.');
    process.exit(0);
  } catch (err) {
    console.error('❌ Cleanup error:', err);
    process.exit(1);
  }
};

clearStudentsAndRequests();
