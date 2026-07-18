const mongoose = require('mongoose');

async function connectToDatabase() {
  mongoose.set('strictQuery', true);
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('Connected to MongoDB');
}

module.exports = { connectToDatabase };
