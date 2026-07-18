const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function issueToken(user) {
  return jwt.sign({ sub: user._id.toString() }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

function validateCredentials(email, password) {
  if (typeof email !== 'string' || !EMAIL_REGEX.test(email)) {
    return 'Please enter a valid email address.';
  }
  if (typeof password !== 'string' || password.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}

router.post('/signup', async (req, res) => {
  const { email, password } = req.body ?? {};
  const validationError = validateCredentials(email, password);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const normalizedEmail = email.toLowerCase().trim();
  const existing = await User.findOne({ email: normalizedEmail });
  if (existing) {
    return res.status(409).json({ error: 'An account with this email already exists.' });
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const user = await User.create({ email: normalizedEmail, passwordHash });

  res.status(201).json({ token: issueToken(user), email: user.email });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body ?? {};
  const validationError = validateCredentials(email, password);
  if (validationError) {
    return res.status(400).json({ error: validationError });
  }

  const normalizedEmail = email.toLowerCase().trim();
  const user = await User.findOne({ email: normalizedEmail });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: 'Incorrect email or password.' });
  }

  res.json({ token: issueToken(user), email: user.email });
});

router.get('/me', requireAuth, async (req, res) => {
  const user = await User.findById(req.userId);
  if (!user) {
    return res.status(401).json({ error: 'Session no longer valid.' });
  }
  res.json({ email: user.email });
});

module.exports = router;
