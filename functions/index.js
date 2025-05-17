// index.js — Unified Cloud Functions for TeamBuilder+

const { onRequest } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const { initializeApp } = require("firebase-admin/app");

initializeApp();

// 🔍 Get All Downline Users
exports.getDownlineUsers = onRequest(async (req, res) => {
  try {
    const email = req.headers['x-user-email'];

    if (!email) {
      console.log('🚫 Missing x-user-email header');
      return res.status(401).json({
        error: 'Unauthorized - Missing x-user-email header',
      });
    }

    console.log(`📩 Fetching downline for email: ${email}`);

    const db = getFirestore();
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    return res.status(200).json(users);
  } catch (err) {
    console.error('🔥 Error in getDownlineUsers:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// 🧾 Get User Profile By Email
exports.getUserProfileByEmail = onRequest(async (req, res) => {
  try {
    const email = req.headers['x-user-email'];

    if (!email) {
      console.log('🚫 Missing x-user-email header');
      return res.status(401).json({
        error: 'Unauthorized - Missing x-user-email header',
      });
    }

    console.log(`🔍 Fetching user profile for: ${email}`);

    const db = getFirestore();
    const snapshot = await db
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.status(404).json({ error: 'User not found' });
    }

    const doc = snapshot.docs[0];
    const userData = { id: doc.id, ...doc.data() };

    return res.status(200).json(userData);
  } catch (err) {
    console.error('🔥 Error in getUserProfileByEmail:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
