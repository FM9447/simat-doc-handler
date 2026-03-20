const mongoose = require('mongoose');
require('dotenv').config();
const DocumentType = require('./models/DocumentType');

const seedFlows = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const initialFlows = [
      { name: 'Bonafide Certificate', steps: ['teacher', 'hod', 'principal'] },
      { name: 'Transfer Certificate', steps: ['teacher', 'office', 'principal'] },
      { name: 'NOC', steps: ['hod', 'principal'] },
      { name: 'Course Completion', steps: ['teacher', 'hod', 'office', 'principal'] }
    ];

    for (const flow of initialFlows) {
      await DocumentType.findOneAndUpdate(
        { name: flow.name },
        flow,
        { upsert: true, new: true }
      );
    }

    console.log('Initial Document Flows seeded successfully!');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

seedFlows();
