'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const path = require('path');
const os = require('os');
const fs = require('fs');

admin.initializeApp();

const db = admin.firestore();

// ─── Shared rate-limit helper ─────────────────────────────────────────────────
//
// Uses Firestore to track attempt counts per key in a rolling window.
// Document path: _rate_limits/{scope}/keys/{key}
// Fields:        count (int), windowStart (number — epoch ms)
//
// Per cc-skill-security-review §7 — Rate Limiting:
// "Rate limiting on all API endpoints. Stricter limits on expensive operations."
//
async function checkRateLimit({ scope, key, maxCount, windowMs }) {
    const docRef = db.collection('_rate_limits').doc(scope).collection('keys').doc(key);

    const now = Date.now();
    const windowStart = now - windowMs;

    try {
        const result = await db.runTransaction(async (tx) => {
            const snap = await tx.get(docRef);

            if (!snap.exists) {
                tx.set(docRef, { count: 1, windowStart: now });
                return { allowed: true, count: 1 };
            }

            const data = snap.data();

            if (data.windowStart < windowStart) {
                tx.update(docRef, { count: 1, windowStart: now });
                return { allowed: true, count: 1 };
            }

            if (data.count >= maxCount) {
                return { allowed: false, count: data.count };
            }

            tx.update(docRef, { count: admin.firestore.FieldValue.increment(1) });
            return { allowed: true, count: data.count + 1 };
        });

        return result;
    } catch (err) {
        console.error(`Rate limit check failed for scope=${scope} key=${key}:`, err);
        return { allowed: true, count: -1 }; // Fail open
    }
}

// ─── checkAuthRateLimit ───────────────────────────────────────────────────────
// 10 attempts / minute / IP
exports.checkAuthRateLimit = functions.https.onCall(async (data, context) => {
    const ip =
        context.rawRequest?.ip ||
        context.rawRequest?.headers?.['x-forwarded-for']?.split(',')[0]?.trim() ||
        'unknown';

    const key = ip.replace(/[./]/g, '_');

    const { allowed } = await checkRateLimit({
        scope: 'auth',
        key,
        maxCount: 10,
        windowMs: 60 * 1000,
    });

    if (!allowed) {
        throw new functions.https.HttpsError(
            'resource-exhausted',
            'TOO_MANY_ATTEMPTS: Too many login attempts. Please wait 1 minute.',
        );
    }

    return { ok: true };
});

// ─── checkPublishRateLimit ────────────────────────────────────────────────────
// 5 publishes / 24 hours / UID
exports.checkPublishRateLimit = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be signed in to publish.');
    }

    const { allowed } = await checkRateLimit({
        scope: 'publish',
        key: context.auth.uid,
        maxCount: 5,
        windowMs: 24 * 60 * 60 * 1000,
    });

    if (!allowed) {
        throw new functions.https.HttpsError(
            'resource-exhausted',
            'POST_LIMIT_REACHED: Daily publish limit of 5 items reached. Try again tomorrow.',
        );
    }

    return { ok: true };
});

// ─── checkUploadRateLimit ─────────────────────────────────────────────────────
// 15 uploads / hour / UID
exports.checkUploadRateLimit = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be signed in to upload.');
    }

    const { allowed } = await checkRateLimit({
        scope: 'upload',
        key: context.auth.uid,
        maxCount: 15,
        windowMs: 60 * 60 * 1000,
    });

    if (!allowed) {
        throw new functions.https.HttpsError(
            'resource-exhausted',
            'UPLOAD_LIMIT_REACHED: Hourly upload limit of 15 images reached. Try again later.',
        );
    }

    return { ok: true };
});

// ─── ADMIN: Set user as admin ────────────────────────────────────────────────
exports.setAdminRole = functions.https.onCall(async (data, context) => {
    if (!context.auth?.token?.admin) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Must be an admin to assign admin roles.'
        );
    }

    const { targetUid } = data;
    if (!targetUid) {
        throw new functions.https.HttpsError('invalid-argument', 'targetUid is required.');
    }

    try {
        await admin.auth().setCustomUserClaims(targetUid, { admin: true });
        return { ok: true, message: `User ${targetUid} is now an admin.` };
    } catch (e) {
        console.error('Failed to set admin claim', e);
        throw new functions.https.HttpsError('internal', 'Failed to set admin claim.');
    }
});

// ─── ADMIN: Verify Seller ────────────────────────────────────────────────────
exports.verifySeller = functions.https.onCall(async (data, context) => {
    if (!context.auth || !context.auth.token.admin) {
        throw new functions.https.HttpsError(
            'permission-denied',
            'Only admins can verify sellers.'
        );
    }

    const { sellerId, verified } = data;
    if (!sellerId || typeof verified !== 'boolean') {
        throw new functions.https.HttpsError(
            'invalid-argument',
            'sellerId and a boolean verified status are required.'
        );
    }

    try {
        await db.collection('users').doc(sellerId).update({
            verified: verified,
        });
        return { ok: true, message: `Seller ${sellerId} verification set to ${verified}.` };
    } catch (e) {
        console.error(`Failed to verify seller ${sellerId}`, e);
        throw new functions.https.HttpsError('internal', 'Failed to verify seller.');
    }
});

// ─── FCM: Notify on new chat message ─────────────────────────────────────────
//
// Triggered when a message is written to conversations/{convId}/messages/{msgId}.
// Fetches the receiver's FCM token and sends a push notification.
//
// Per firebase skill: server-side trigger — never trust the client to fire notifications.
// Per cc-skill-security-review §4: authorization checks before operations.
//
exports.onNewChatMessage = functions.firestore
    .document('conversations/{conversationId}/messages/{messageId}')
    .onCreate(async (snap, context) => {
        const message = snap.data();
        const { conversationId } = context.params;

        // Skip system/empty messages
        if (!message || !message.text && !message.item_id) return null;

        const senderId = message.sender_id;
        if (!senderId) return null;

        // Fetch the parent conversation to get participants
        const convSnap = await db.collection('conversations').doc(conversationId).get();
        if (!convSnap.exists) return null;

        const { participants } = convSnap.data();
        if (!Array.isArray(participants) || participants.length < 2) return null;

        // The receiver is whoever is NOT the sender
        const receiverId = participants.find((p) => p !== senderId);
        if (!receiverId) return null;

        // Fetch receiver's FCM token
        const receiverSnap = await db.collection('users').doc(receiverId).get();
        if (!receiverSnap.exists) return null;

        const { fcm_token: fcmToken, name: receiverName } = receiverSnap.data();
        if (!fcmToken) {
            console.log(`Receiver ${receiverId} has no FCM token — skipping notification.`);
            return null;
        }

        // Fetch sender's name for the notification
        const senderSnap = await db.collection('users').doc(senderId).get();
        const senderName = senderSnap.exists ? (senderSnap.data().name || 'Someone') : 'Someone';

        const notificationBody = message.text
            ? (message.text.length > 80 ? message.text.substring(0, 77) + '...' : message.text)
            : '📦 Item shared';

        try {
            await admin.messaging().send({
                token: fcmToken,
                notification: {
                    title: senderName.toUpperCase(),
                    body: notificationBody,
                },
                data: {
                    conversation_id: conversationId,
                    type: 'chat_message',
                },
                android: {
                    priority: 'high',
                    notification: {
                        sound: 'default',
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            });
            console.log(`Notification sent to ${receiverId} for conversation ${conversationId}`);
        } catch (err) {
            // Token may be stale — log but don't throw (non-fatal)
            console.error(`Failed to send FCM to ${receiverId}:`, err.message);
        }

        return null;
    });

// ─── Image Thumbnail Generation ───────────────────────────────────────────────
//
// Triggered when any file is written to the items/ Storage path.
// Generates a 400x400 JPEG thumbnail using sharp, writes it to thumbs/,
// and sets Cache-Control headers for CDN caching.
// Updates the Firestore item doc with the thumbnail_url.
//
// Per firebase skill: serve optimized assets — large collections with raw images hit perf.
// Per cc-skill-security-review: size is already enforced in Storage rules.
//
exports.generateThumbnail = functions.storage.object().onFinalize(async (object) => {
    const filePath = object.name; // e.g. items/abc123/photo.jpg
    const contentType = object.contentType;

    // Only process images in the items/ path
    if (!filePath.startsWith('items/') || !contentType.startsWith('image/')) return null;

    // Skip if this is already a thumbnail
    if (filePath.startsWith('thumbs/')) return null;

    let sharp;
    try {
        sharp = require('sharp');
    } catch (e) {
        console.warn('sharp not installed — thumbnail generation skipped. Run: cd functions && npm install sharp');
        return null;
    }

    const bucket = admin.storage().bucket(object.bucket);
    const fileName = path.basename(filePath);
    const tempInputPath = path.join(os.tmpdir(), fileName);
    const thumbFileName = `thumb_${fileName.replace(/\.[^.]+$/, '.jpg')}`;
    const tempThumbPath = path.join(os.tmpdir(), thumbFileName);

    // Extract itemId from path: items/{itemId}/...
    const pathParts = filePath.split('/');
    const itemId = pathParts[1];

    try {
        // Download original
        await bucket.file(filePath).download({ destination: tempInputPath });

        // Resize to 400x400 JPEG
        await sharp(tempInputPath)
            .resize(400, 400, { fit: 'cover', position: 'center' })
            .jpeg({ quality: 80 })
            .toFile(tempThumbPath);

        // Upload thumbnail with CDN cache headers
        const thumbStoragePath = `thumbs/${itemId}/${thumbFileName}`;
        await bucket.upload(tempThumbPath, {
            destination: thumbStoragePath,
            metadata: {
                contentType: 'image/jpeg',
                cacheControl: 'public, max-age=86400', // 24h CDN cache
            },
        });

        // Get the public download URL
        const thumbFile = bucket.file(thumbStoragePath);
        const [url] = await thumbFile.getSignedUrl({
            action: 'read',
            expires: '01-01-2099',
        });

        // Update Firestore item doc with thumbnail_url
        const itemRef = db.collection('items').doc(itemId);
        const itemSnap = await itemRef.get();
        if (itemSnap.exists) {
            await itemRef.update({ thumbnail_url: url });
            console.log(`Thumbnail generated for item ${itemId}: ${thumbStoragePath}`);
        }
    } catch (err) {
        console.error(`Thumbnail generation failed for ${filePath}:`, err);
    } finally {
        // Cleanup temp files
        try { fs.unlinkSync(tempInputPath); } catch (_) { }
        try { fs.unlinkSync(tempThumbPath); } catch (_) { }
    }

    return null;
});
