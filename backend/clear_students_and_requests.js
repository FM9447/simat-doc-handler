const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Document = require('./models/Document');
const Notification = require('./models/Notification');

const clearStudentsAndRequests = async () => {
  try {
    const dbUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/smartcampus';
    console.log('Connecting to database...');
    await mongoose.connect(dbUri);

    // 1. Delete all document requests
    const docResult = await Document.deleteMany({});
    console.log(`✅ Cleared ${docResult.deletedCount} document requests.`);

    // 2. Delete all student users (leaving staff and admin accounts intact)
    const studentResult = await User.deleteMany({ role: 'student' });
    console.log(`✅ Cleared ${studentResult.deletedCount} student accounts.`);

    // 3. Clear notifications
    const notifResult = await Notification.deleteMany({});
    console.log(`✅ Cleared ${notifResult.deletedCount} notifications.`);

    console.log('🎉 Cleanup completed successfully! Staff and Admin accounts were preserved.');
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('❌ Cleanup error:', err);
    process.exit(1);
  }
};

clearStudentsAndRequests();
