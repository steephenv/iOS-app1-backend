// One-time migration: before Conversations existed, every user's messages
// lived in one flat, ungrouped thread. This groups each user's orphaned
// messages (no conversationId) into a single "recovered" conversation so
// they show up in the Chats list instead of being stranded.
require('dotenv').config();
const mongoose = require('mongoose');
const { connectToDatabase } = require('../src/db');
const Message = require('../src/models/Message');
const Conversation = require('../src/models/Conversation');

const TITLE_LENGTH_LIMIT = 50;

function titleFromMessage(text) {
  const trimmed = text.trim();
  return trimmed.length > TITLE_LENGTH_LIMIT ? `${trimmed.slice(0, TITLE_LENGTH_LIMIT)}…` : trimmed;
}

async function migrate() {
  await connectToDatabase();

  const orphaned = await Message.find({ conversationId: { $exists: false } }).sort({ createdAt: 1 });
  console.log(`Found ${orphaned.length} orphaned messages.`);

  const byUser = new Map();
  for (const message of orphaned) {
    const key = message.userId.toString();
    if (!byUser.has(key)) byUser.set(key, []);
    byUser.get(key).push(message);
  }

  for (const [userId, messages] of byUser) {
    const firstUserMessage = messages.find((m) => m.role === 'user') ?? messages[0];
    const lastMessage = messages[messages.length - 1];

    const conversation = await Conversation.create({
      userId,
      title: titleFromMessage(firstUserMessage.content)
    });

    await Message.updateMany(
      { _id: { $in: messages.map((m) => m._id) } },
      { $set: { conversationId: conversation._id } }
    );

    // Backdate updatedAt so the recovered thread sorts by when it was
    // actually last active, not "now" from this migration run. Mongoose's
    // timestamps option otherwise overwrites updatedAt on every update.
    await Conversation.updateOne(
      { _id: conversation._id },
      { $set: { updatedAt: lastMessage.createdAt } },
      { timestamps: false }
    );

    console.log(
      `Migrated ${messages.length} messages for user ${userId} into conversation ${conversation._id} ("${conversation.title}")`
    );
  }

  console.log('Migration complete.');
  await mongoose.disconnect();
}

migrate().catch((error) => {
  console.error('Migration failed', error);
  process.exit(1);
});
