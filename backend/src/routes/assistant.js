const express = require('express');
const { requireAuth } = require('../middleware/auth');
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const { generateReply } = require('../gemini');

const router = express.Router();

const HISTORY_CONTEXT_LIMIT = 20;
const TITLE_LENGTH_LIMIT = 50;

function formatConversation(conversation) {
  return {
    id: conversation._id.toString(),
    title: conversation.title,
    updatedAt: conversation.updatedAt
  };
}

function formatMessage(message) {
  return {
    id: message._id.toString(),
    role: message.role,
    content: message.content,
    createdAt: message.createdAt
  };
}

function titleFromMessage(text) {
  const trimmed = text.trim();
  return trimmed.length > TITLE_LENGTH_LIMIT ? `${trimmed.slice(0, TITLE_LENGTH_LIMIT)}…` : trimmed;
}

async function findOwnedConversation(id, userId) {
  const conversation = await Conversation.findById(id);
  if (!conversation || !conversation.userId.equals(userId)) {
    return null;
  }
  return conversation;
}

router.get('/conversations', requireAuth, async (req, res) => {
  const conversations = await Conversation.find({ userId: req.userId }).sort({ updatedAt: -1 });
  res.json({ conversations: conversations.map(formatConversation) });
});

router.delete('/conversations/:id', requireAuth, async (req, res) => {
  const conversation = await findOwnedConversation(req.params.id, req.userId);
  if (!conversation) {
    return res.status(404).json({ error: 'Conversation not found.' });
  }
  await Message.deleteMany({ conversationId: conversation._id });
  await conversation.deleteOne();
  res.status(204).end();
});

router.get('/conversations/:id/messages', requireAuth, async (req, res) => {
  const conversation = await findOwnedConversation(req.params.id, req.userId);
  if (!conversation) {
    return res.status(404).json({ error: 'Conversation not found.' });
  }
  const messages = await Message.find({ conversationId: conversation._id }).sort({ createdAt: 1 });
  res.json({ messages: messages.map(formatMessage) });
});

router.post('/messages', requireAuth, async (req, res) => {
  const { conversationId, message } = req.body ?? {};
  if (typeof message !== 'string' || !message.trim()) {
    return res.status(400).json({ error: 'Message cannot be empty.' });
  }

  let conversation;
  if (conversationId) {
    conversation = await findOwnedConversation(conversationId, req.userId);
    if (!conversation) {
      return res.status(404).json({ error: 'Conversation not found.' });
    }
  } else {
    conversation = await Conversation.create({ userId: req.userId, title: titleFromMessage(message) });
  }

  const userMessage = await Message.create({
    conversationId: conversation._id,
    userId: req.userId,
    role: 'user',
    content: message.trim()
  });

  const recentHistory = await Message.find({ conversationId: conversation._id })
    .sort({ createdAt: -1 })
    .limit(HISTORY_CONTEXT_LIMIT);

  try {
    const replyText = await generateReply(recentHistory.reverse());
    const assistantMessage = await Message.create({
      conversationId: conversation._id,
      userId: req.userId,
      role: 'model',
      content: replyText
    });
    // Mongoose bumps updatedAt automatically on save (timestamps: true),
    // which is what keeps the conversation list sorted by recent activity.
    await conversation.save();

    res.status(201).json({
      conversationId: conversation._id.toString(),
      title: conversation.title,
      userMessage: formatMessage(userMessage),
      reply: formatMessage(assistantMessage)
    });
  } catch (error) {
    console.error('Gemini request failed', error);
    res.status(502).json({ error: 'The assistant is unavailable right now. Please try again.' });
  }
});

module.exports = router;
