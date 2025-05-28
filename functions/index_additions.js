// firestore_service.dart

// Create a new user document securely
exports.createUserSecurely = onRequest(async (req, res) => {
  try {
    const user = req.body;
    if (!user || !user.uid) {
      return res.status(400).json({ error: 'Missing user data or UID' });
    }
    await db.collection('users').doc(user.uid).set(user);
    return res.status(200).json({ success: true });
  } catch (e) {
    console.error('🔥 createUserSecurely error:', e);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Update user document securely
exports.updateUserSecurely = onRequest(async (req, res) => {
  try {
    const { uid, updates } = req.body;
    if (!uid || !updates) {
      return res.status(400).json({ error: 'Missing uid or updates' });
    }
    await db.collection('users').doc(uid).update(updates);
    return res.status(200).json({ success: true });
  } catch (e) {
    console.error('🔥 updateUserSecurely error:', e);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Increment a single field on a user document
exports.incrementUserField = onRequest(async (req, res) => {
  try {
    const { uid, field } = req.body;
    if (!uid || !field) {
      return res.status(400).json({ error: 'Missing uid or field' });
    }
    await db.collection('users').doc(uid).update({
      [field]: FieldValue.increment(1),
    });
    return res.status(200).json({ success: true });
  } catch (e) {
    console.error('🔥 incrementUserField error:', e);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

