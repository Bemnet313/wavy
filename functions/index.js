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

  // Update item doc in Firestore (assuming filePath is like items/{itemId}/filename)
  const segments = filePath.split('/');
  if (segments[0] === 'items') {
    const itemId = segments[1];
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
      notification: {
        title: 'New Message',
        body: message.text,
        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
      },
      data: {
        conversationId: convId,
        type: 'CHAT'
      }
    };

    return admin.messaging().sendToDevice(token, payload);
  });

/**
 * generateShareLink - Creates a short-code redirect for an item
 * Trigger: HTTPS Callable
 */
exports.generateShareLink = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');

  const itemId = data.itemId;
  // Simple Base62 style random short code
  const shortCode = Math.random().toString(36).substring(2, 8);

  await admin.firestore().collection('shareUrls').doc(shortCode).set({
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
