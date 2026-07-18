const express = require('express');
const { requireAuth } = require('../middleware/auth');
const Message = require('../models/Message');
const { generateReply } = require('../gemini');

const router = express.Router();

const HISTORY_CONTEXT_LIMIT = 20;

function formatMessage(message) {
  return {
    id: message._id.toString(),
    role: message.role,
    content: message.content,
    createdAt: message.createdAt
  };
}

router.get('/history', requireAuth, async (req, res) => {
  const messages = await Message.find({ userId: req.userId }).sort({ createdAt: 1 }).limit(200);
  res.json({ messages: messages.map(formatMessage) });
});

router.post('/chat', requireAuth, async (req, res) => {
  const { message } = req.body ?? {};
  if (typeof message !== 'string' || !message.trim()) {
    return res.status(400).json({ error: 'Message cannot be empty.' });
  }

  const userMessage = await Message.create({
    userId: req.userId,
    role: 'user',
    content: message.trim()
  });

  const recentHistory = await Message.find({ userId: req.userId })
    .sort({ createdAt: -1 })
    .limit(HISTORY_CONTEXT_LIMIT);

  try {
    const replyText = await generateReply(recentHistory.reverse());
    const assistantMessage = await Message.create({
      userId: req.userId,
      role: 'model',
      content: replyText
    });
    res.status(201).json({
      userMessage: formatMessage(userMessage),
      reply: formatMessage(assistantMessage)
    });
  } catch (error) {
    console.error('Gemini request failed', error);
    res.status(502).json({ error: 'The assistant is unavailable right now. Please try again.' });
  }
});

module.exports = router;
