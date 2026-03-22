const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Storage } = require('@google-cloud/storage');
const path = require('path');
const os = require('os');
const fs = require('fs');
const spawn = require('child-process-promise').spawn;

admin.initializeApp();

/**
 * onImageUpload - Automatically generates thumbnails and converts to WebP
 * Trigger: Firebase Storage upload
 */
exports.onImageUpload = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name;
  const contentType = object.contentType;

  // Exit if this is already a thumbnail or not an image
  if (!contentType.startsWith('image/') || filePath.includes('thumb_')) {
    return console.log('This is not an image or already a thumbnail.');
  }

  const fileName = path.basename(filePath);
  const bucket = admin.storage().bucket(object.bucket);
  const tempFilePath = path.join(os.tmpdir(), fileName);
  await bucket.file(filePath).download({ destination: tempFilePath });

  // Generate 400px thumbnail
  const thumbName = `thumb_${fileName}`;
  const thumbFilePath = path.join(path.dirname(filePath), thumbName);
  const tempThumbPath = path.join(os.tmpdir(), thumbName);

  // Use ImageMagick (pre-installed in Cloud Functions environment)
  await spawn('convert', [tempFilePath, '-thumbnail', '400x400>', tempThumbPath]);

  // Upload to storage
  await bucket.upload(tempThumbPath, { destination: thumbFilePath });

  // Clean up
  fs.unlinkSync(tempFilePath);
  fs.unlinkSync(tempThumbPath);

  // Retrieve itemId set by client during upload
  const metadata = object.metadata || {};
  const itemId = metadata.itemId;

  if (itemId) {
    const thumbUrl = `gs://${object.bucket}/${thumbFilePath}`;
    await admin.firestore().collection('items').doc(itemId).update({
      thumbnail: thumbUrl
    });
  }
});

/**
 * onNewMessage - Sends push notification when a new message is added to a conversation
 * Trigger: Firestore onCreate on messages subcollection
 */
exports.onNewMessage = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    const convId = context.params.convId;

    const convDoc = await admin.firestore().collection('conversations').doc(convId).get();
    const convData = convDoc.data();

    // Find recipient
    const recipientId = convData.participants.find(p => p !== message.senderId);

    // Get recipient's FCM token
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    const token = userDoc.data().fcmToken;

    if (!token) return;

    const payload = {
      token: token,
      notification: {
        title: 'New Message',
        body: message.text,
      },
      data: {
        conversationId: convId,
        type: 'CHAT'
      },
      android: {
        notification: {
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      }
    };

    return admin.messaging().send(payload);
  });

/**
 * generateShareLink - Creates a short-code redirect for an item
 * Trigger: HTTPS Callable
 */
exports.generateShareLink = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');

  const itemId = data.itemId;
  const db = admin.firestore();

  let shortCode;
  let exists = true;

  // Retry loop to ensure 100% uniqueness
  while (exists) {
    shortCode = Math.random().toString(36).substring(2, 8);
    const doc = await db.collection('shareUrls').doc(shortCode).get();
    exists = doc.exists;
  }

  await db.collection('shareUrls').doc(shortCode).set({
    itemId: itemId,
    creatorId: context.auth.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { shortUrl: `https://wavy.app/s/${shortCode}` };
});

/**
 * onPhoneReveal - Monitors audit log for phone reveals
 * Trigger: Firestore onCreate on events collection
 */
exports.onPhoneReveal = functions.firestore
  .document('events/{eventId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (data.event_name === 'phone_revealed') {
      console.log(`AUDIT: User ${data.user_id} revealed phone for seller ${data.params.seller_id}`);
      // Potential for monetization/lead-gen logic here
    }
  });

/**
 * getSellerPhone - Fetches protected phone number and logs an audit event
 * Trigger: HTTPS Callable
 */
exports.getSellerPhone = functions.https.onCall(async (data, context) => {
  // Ensure caller is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in to view phone details.');
  }

  const sellerId = data.sellerId;
  const callerId = context.auth.uid;

  if (!sellerId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing sellerId.');
  }

  try {
    // Audit log the reveal event
    await admin.firestore().collection('events').add({
      event_name: 'phone_revealed',
      user_id: callerId,
      params: { seller_id: sellerId },
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Read the protected contact document
    const contactRef = admin.firestore().collection('sellers').doc(sellerId).collection('private').doc('contact');
    const contactDoc = await contactRef.get();

    if (!contactDoc.exists) {
      // Fallback logic if structure isn't migrated yet
      const parentDoc = await admin.firestore().collection('sellers').doc(sellerId).get();
      return { phone: parentDoc.data().phone || null };
    }

    return { phone: contactDoc.data().phone };
  } catch (error) {
    console.error('Error fetching phone: ', error);
    throw new functions.https.HttpsError('internal', 'Unable to fetch phone details.');
  }
});

/**
 * onItemReport - Auto-moderation to hide items with 5 or more reports
 * Trigger: Firestore onCreate on items/{itemId}/reports/{reportId}
 */
exports.onItemReport = functions.firestore
  .document('items/{itemId}/reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    const itemId = context.params.itemId;
    const itemRef = admin.firestore().collection('items').doc(itemId);

    // Use an atomic transaction or simple count query
    const reportsSnapshot = await itemRef.collection('reports').count().get();
    const count = reportsSnapshot.data().count;

    if (count >= 5) {
      console.log(`Auto-moderation: Hiding item ${itemId} due to 5+ reports`);
      await itemRef.update({ status: 'hidden' });
    }
  });

/**
 * updateSellerActivity - Daily cron to sync seller last_active to their items
 * Trigger: PubSub Schedule (Every day at midnight)
 */
exports.updateSellerActivity = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - 20); // 20 days ago

  // Find sellers who haven't been active in 20 days
  const inactiveSellers = await admin.firestore().collection('sellers')
    .where('last_active', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
    .where('status', '!=', 'inactive')
    .get();

  let batch = admin.firestore().batch();
  let updateCount = 0;

  for (const seller of inactiveSellers.docs) {
    // Mark seller as intentionally tracked inactive
    batch.update(seller.ref, { status: 'inactive' });
    updateCount++;

    // Hide all their active items from the feed
    const items = await admin.firestore().collection('items')
      .where('seller_id', '==', seller.id)
      .where('status', '==', 'active')
      .get();

    items.forEach(doc => {
      batch.update(doc.ref, { seller_last_active: seller.data().last_active });
      updateCount++;
    });

    if (updateCount >= 400) { // Firestore batch limit is 500, flush early
      await batch.commit();
      batch = admin.firestore().batch(); // Create fresh batch instance
      updateCount = 0;
    }
  }

  if (updateCount > 0) {
    await batch.commit();
  }

  console.log(`Updated seller activity status for ${inactiveSellers.size} sellers.`);
  return null;
});

/**
 * onConversationDelete - Sweeps orphaned messages when a conversation is deleted
 * Trigger: Firestore onDelete on conversations/{convId}
 * Standard: @firebase-firestore-basics — clean up subcollections on parent delete
 */
exports.onConversationDelete = functions.firestore
  .document('conversations/{convId}')
  .onDelete(async (snapshot, context) => {
    const convId = context.params.convId;
    const messagesRef = admin.firestore()
      .collection('conversations').doc(convId).collection('messages');

    // Firestore doesn't cascade-delete subcollections, so we do it manually
    const batchSize = 100;
    let deleted = 0;

    const deleteQuery = async () => {
      const snap = await messagesRef.limit(batchSize).get();
      if (snap.empty) return;

      const batch = admin.firestore().batch();
      snap.docs.forEach(doc => batch.delete(doc.ref));
      await batch.commit();
      deleted += snap.size;

      // Recurse if there are more
      if (snap.size >= batchSize) {
        await deleteQuery();
      }
    };

    await deleteQuery();
    console.log(`Cleaned up ${deleted} orphaned messages from conversation ${convId}.`);
  });

/**
 * enforcePostLimit - Blocks creation if user exceeds 5 posts/day
 * Trigger: Firestore onCreate on items
 */
exports.enforcePostLimit = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const sellerId = data.seller_id;

    const limit = 5; // Strict requirement: 5/day per UID

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const todayItems = await admin.firestore().collection('items')
      .where('seller_id', '==', sellerId)
      .where('created_at', '>=', admin.firestore.Timestamp.fromDate(startOfDay))
      .count().get();

    if (todayItems.data().count > limit) {
      console.warn(`Limit Exceeded: User ${sellerId} reached daily post limit.`);
      await snapshot.ref.delete();
      throw new Error('DAILY_LIMIT_REACHED');
    }
  });

/**
 * enforceImageUploadLimit - Blocks image uploads if user exceeds 15/hour
 * Trigger: Storage onFinalize
 */
exports.enforceImageUploadLimit = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name;
  if (!filePath.startsWith('items/')) return;

  const sellerId = filePath.split('/')[1];
  if (!sellerId) return;

  const oneHourAgo = new Date(Date.now() - 3600000);

  // Track usage in a separate collection for efficiency
  const usageRef = admin.firestore().collection('user_usage').doc(sellerId);
  const uploads = await admin.firestore().collection('storage_logs')
    .where('userId', '==', sellerId)
    .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(oneHourAgo))
    .count().get();

  if (uploads.data().count > 15) {
    console.warn(`Limit Exceeded: User ${sellerId} reached hourly upload limit. Deleting file.`);
    await admin.storage().bucket(object.bucket).file(filePath).delete();
    return;
  }

  // Log the successful upload
  await admin.firestore().collection('storage_logs').add({
    userId: sellerId,
    path: filePath,
    timestamp: admin.firestore.FieldValue.serverTimestamp()
  });
});

/**
 * checkAuthRateLimit - Blocks auth attempts if IP exceeds 10/min
 * Trigger: HTTPS Callable
 */
exports.checkAuthRateLimit = functions.https.onCall(async (data, context) => {
  const ip = context.rawRequest.ip || context.rawRequest.headers['x-forwarded-for'];
  if (!ip) return { allowed: true };

  const oneMinAgo = new Date(Date.now() - 60000);
  const ipKey = ip.replace(/\./g, '_'); // Replace dots for doc ID compatibility

  const limiterRef = admin.firestore().collection('auth_limiter').doc(ipKey);
  const doc = await limiterRef.get();
  const now = Date.now();

  let attempts = [];
  if (doc.exists) {
    attempts = doc.data().attempts.filter(t => t > oneMinAgo.getTime());
  }

  if (attempts.length >= 10) {
    console.warn(`Rate Limit: IP ${ip} blocked for too many auth attempts.`);
    throw new functions.https.HttpsError('resource-exhausted', 'Too many attempts. Try again in 1 minute.');
  }

  attempts.push(now);
  await limiterRef.set({
    attempts,
    last_attempt: admin.firestore.FieldValue.serverTimestamp(),
    ttl: new Date(now + 3600000) // 1 hour TTL for auto-cleanup
  });

  return { allowed: true };
});

/**
 * enforceChatRateLimit - Limits users to 3 messages per minute
 */
exports.enforceChatRateLimit = functions.firestore
  .document('conversations/{convId}/messages/{msgId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const senderId = data.senderId;

    const oneMinAgo = new Date(Date.now() - 60000);

    const recentMessages = await admin.firestore()
      .collection('conversations').doc(context.params.convId)
      .collection('messages')
      .where('senderId', '==', senderId)
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(oneMinAgo))
      .count().get();

    if (recentMessages.data().count > 3) {
      await snapshot.ref.delete();
      throw new functions.https.HttpsError('resource-exhausted', 'Chat rate limit exceeded.');
    }
  });

/**
 * enforceDeviceLimit - Limits max 2 accounts per physical device
 */
exports.enforceDeviceLimit = functions.https.onCall(async (data, context) => {
  const deviceId = data.deviceId;
  if (!deviceId) throw new functions.https.HttpsError('invalid-argument', 'deviceId required');

  const existing = await admin.firestore().collection('users')
    .where('device_id', '==', deviceId).count().get();

  if (existing.data().count >= 2) {
    throw new functions.https.HttpsError('resource-exhausted', 'Device limit reached.');
  }

  return { allowed: true };
});

/**
 * requestPremium - Lead gen for premium upsell
 */
exports.requestPremium = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must log in');

  const uid = context.auth.uid;

  await admin.firestore().collection('premium_requests').add({
    user_id: uid,
    status: 'pending',
    requested_at: admin.firestore.FieldValue.serverTimestamp()
  });

  return { success: true, message: 'We will contact you, or call 0942123939.' };
});
