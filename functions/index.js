// 🔐 Enhanced Cloud Function Logic for Secure Sponsor Updates & Auto-Invitations

const { onRequest } = require("firebase-functions/v2/https");
const { onCall } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

initializeApp();
const db = getFirestore();
const messaging = admin.messaging();

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

    if (data.role !== 'admin') {
      return res.status(403).json({ error: 'User is not an Admin' });
    }

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

      if (level === 0) {
        updates.direct_sponsor_count = FieldValue.increment(1);
      }

      const direct = userData.direct_sponsor_count ?? 0;
      const total = userData.total_team_count ?? 0;
      const directMin = userData.direct_sponsor_min ?? 1;
      const totalMin = userData.total_team_min ?? 1;
      const alreadyQualified = userData.qualified_date != null;

      if (!alreadyQualified && direct >= directMin && total >= totalMin) {
        updates.qualified_date = FieldValue.serverTimestamp();
      }

      await userRef.update(updates);

      if (level === 0) {
        await checkEligibilityAndSendInvite(currentUid);
      }

      currentUid = userData.referred_by;
      level++;
    }

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('🔥 Error in incrementSponsorCounts:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// 🔐 Check Admin subscription or trial status
exports.checkAdminSubscriptionStatus = functions.https.onCall(async (data, context) => {
  const uid = data.uid;

  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'User ID is required.');
  }

  try {
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found.');
    }

    const userData = userDoc.data();
    const role = userData.role || 'user';
    if (role !== 'admin') {
      return { isActive: true };
    }

    const now = new Date();
    const trialStart = userData.trialStartAt?.toDate?.() || null;
    const subscriptionExpiresAt = userData.subscriptionExpiresAt?.toDate?.() || null;

    let isActive = false;
    let trialExpired = true;
    let daysRemaining = 0;

    if (subscriptionExpiresAt && subscriptionExpiresAt > now) {
      isActive = true;
      daysRemaining = Math.ceil((subscriptionExpiresAt - now) / (1000 * 60 * 60 * 24));
      trialExpired = true;
    } else if (trialStart) {
      const trialEnd = new Date(trialStart);
      trialEnd.setDate(trialEnd.getDate() + 30);
      if (trialEnd > now) {
        isActive = true;
        daysRemaining = Math.ceil((trialEnd - now) / (1000 * 60 * 60 * 24));
        trialExpired = false;
      }
    }

    return {
      isActive,
      daysRemaining,
      trialExpired,
    };
  } catch (error) {
    console.error('❌ Error in checkAdminSubscriptionStatus:', error);
    throw new functions.https.HttpsError('internal', 'Failed to verify subscription status.');
  }
});

// 🔔 Send FCM push notification on in-app notification creation (v2-compatible)
exports.sendPushNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
  const snap = event.data;
  const context = event;

  const userId = context.params.userId;
  const notificationData = snap?.data();

  const userDoc = await db.collection("users").doc(userId).get();
  const fcmToken = userDoc.data()?.fcm_token;

  if (!fcmToken) {
    console.log(`❌ No FCM token for user ${userId}`);
    return null;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: notificationData?.title || "New Alert",
      body: notificationData?.message || "You have a new notification in TeamBuild Pro",
    },
    android: { notification: { sound: "default" } },
    apns: { payload: { aps: { sound: "default" } } },
  };

  try {
    const response = await messaging.send(message);
    console.log(`✅ FCM push sent: ${response}`);
  } catch (error) {
    console.error(`❌ Failed to send FCM push:`, error);
  }
});

// 🔐 Auto-check eligibility and invite user
async function checkEligibilityAndSendInvite(uid) {
  const userDoc = await db.collection('users').doc(uid).get();
  if (!userDoc.exists) return;

  const userData = userDoc.data();
  const adminId = userData.upline_admin;
  if (!adminId) return;

  const settingsDoc = await db.collection('admin_settings').doc(adminId).get();
  if (!settingsDoc.exists) return;

  const settings = settingsDoc.data();
  const { direct_sponsor_min = 1, total_team_min = 1, countries = [] } = settings;

  const direct = userData.direct_sponsor_count ?? 0;
  const total = userData.total_team_count ?? 0;
  const country = userData.country ?? '';
  const firstName = userData.firstName || '';

  const isEligible =
    direct >= direct_sponsor_min &&
    total >= total_team_min &&
    countries.includes(country);

  if (!isEligible) return;

  const existing = await db.collection('invites')
    .where('toUserId', '==', uid)
    .where('fromAdminId', '==', adminId)
    .limit(1)
    .get();

  if (!existing.empty) return;

  await db.collection('invites').add({
    fromAdminId: adminId,
    toUserId: uid,
    bizOpp: settings.biz_opp ?? '',
    refLink: settings.biz_opp_ref_url ?? '',
    sentAt: Timestamp.now(),
    status: 'sent',
  });

  await db.collection('users')
    .doc(uid)
    .collection('notifications')
    .add({
      type: 'invitation',
      title: `🎉 Congratulations!`,
      message: `Your hard work has paid off! You’re now qualified to join ${settings.biz_opp || 'a business opportunity'}.

Visit your Dashboard and click ‘Join Opportunity’ to get started.`,
      timestamp: Timestamp.now(),
      read: false,
    });

  console.log(`✅ Invite + notification sent to user ${uid} from admin ${adminId}`);
}
