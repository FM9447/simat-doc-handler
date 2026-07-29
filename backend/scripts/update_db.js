require('dotenv').config();
const DocumentType = require('../models/DocumentType');
const Document = require('../models/Document');

async function updateDB() {
  try {
    const dtResult = await DocumentType.updateMany(
      { allowCustomHeading: { $exists: false } },
      { $set: { allowCustomHeading: false } }
    );
    console.log(`Updated ${dtResult.modifiedCount} DocumentTypes`);

    const docResult = await Document.updateMany(
      { customHeading: { $exists: false } },
      { $set: { customHeading: '' } }
    );
    console.log(`Updated ${docResult.modifiedCount} Documents`);
  } catch (err) {
    console.error('Error updating DB:', err);
    process.exit(1);
  }
}

updateDB();
