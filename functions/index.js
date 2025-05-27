// 🔐 Enhanced Cloud Function Logic for Secure Sponsor Updates

const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

// 🔹 SAFE: Public sponsor data only
exports.getUserByReferralCode = onRequest(async (req, res) => {
  try {
    const code = req.query.code;
    if (!code) return res.status(400).json({ error: 'Missing referral code' });

    const snapshot = await db.collection('users')
      .where('referralCode', '==', code)
      .limit(1)
      .get();

    if (snapshot.empty) return res.status(404).json({ error: 'User not found' });

    const doc = snapshot.docs[0];
    const data = doc.data();

    return res.status(200).json({
      uid: doc.id,
      firstName: data.firstName || '',
      lastName: data.lastName || '',
      upline_admin: data.upline_admin || null,
    });
  } catch (err) {
    console.error('🔥 Error in getUserByReferralCode:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// 🔹 Get countries[] from upline admin UID
exports.getCountriesByAdminUid = onRequest(async (req, res) => {
  try {
    const uid = req.query.uid;
    if (!uid) return res.status(400).json({ error: 'Missing admin UID' });

    const doc = await db.collection('users').doc(uid).get();
    if (!doc.exists) return res.status(404).json({ error: 'Admin user not found' });

    const data = doc.data();
    if (!data || !Array.isArray(data.countries)) {
      return res.status(404).json({ error: 'Countries array not found' });
    }

    return res.status(200).json({ countries: data.countries });
  } catch (err) {
    console.error('🔥 Error in getCountriesByAdminUid:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// 🔐 Securely increment sponsor counts and auto-qualify upline
exports.incrementSponsorCounts = onRequest(async (req, res) => {
  try {
    const { referralCode } = req.body;
    if (!referralCode) return res.status(400).json({ error: 'Missing referral code' });

    const refSnapshot = await db.collection('users')
      .where('referralCode', '==', referralCode)
      .limit(1)
      .get();

    if (refSnapshot.empty) return res.status(404).json({ error: 'Sponsor not found' });

    const sponsorDoc = refSnapshot.docs[0];
    const sponsorId = sponsorDoc.id;
    let currentUid = sponsorId;
    let level = 0;

    while (currentUid && level < 20) {
      const userRef = db.collection('users').doc(currentUid);
      const userDoc = await userRef.get();
      if (!userDoc.exists) break;

      const userData = userDoc.data();
      const updates = { total_team_count: FieldValue.increment(1) };

      // Direct sponsor gets both counts
      if (level === 0) {
        updates.direct_sponsor_count = FieldValue.increment(1);
      }

      // Auto-qualify if eligible
      const direct = userData.direct_sponsor_count ?? 0;
      const total = userData.total_team_count ?? 0;
      const directMin = userData.direct_sponsor_min ?? 1;
      const totalMin = userData.total_team_min ?? 1;
      const alreadyQualified = userData.qualified_date != null;

      if (!alreadyQualified && direct >= directMin && total >= totalMin) {
        updates.qualified_date = FieldValue.serverTimestamp();
      }

      await userRef.update(updates);

      // Traverse up the chain
      currentUid = userData.referred_by;
      level++;
    }

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('🔥 Error in incrementSponsorCounts:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});
