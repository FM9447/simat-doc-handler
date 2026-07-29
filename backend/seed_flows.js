require('dotenv').config();
const connectDB = require('./config/db');

async function seedFlows() {
  try {
    await connectDB();
    console.log('🎉 KTU Document Templates seeded successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Seeding error:', err);
    process.exit(1);
  }
}

seedFlows();
