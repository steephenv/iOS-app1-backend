const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    conversationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation', required: true, index: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    role: { type: String, enum: ['user', 'model'], required: true },
    content: { type: String, required: true }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Message', messageSchema);
