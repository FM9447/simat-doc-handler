require('dotenv').config();
const Document = require('./models/Document');
const User = require('./models/User');

async function fix() {
  const validPrincipal = await User.findOne({ role: 'principal', isApproved: true });
  if (!validPrincipal) {
    console.log('No valid principal found to reassign to!');
    process.exit(0);
  }

  const newId = String(validPrincipal._id);
  const docs = await Document.find({ workflow: 'principal' });
  let count = 0;

  for (const doc of docs) {
    if (doc.assigned?.principal?.id !== newId) {
      doc.assigned = { ...(doc.assigned || {}), principal: { id: newId, name: validPrincipal.name } };
      await doc.save();
      count++;
    }
  }

  console.log(`Reassigned ${count} orphaned documents to the valid Principal (${newId}).`);
  process.exit(0);
}

fix();
