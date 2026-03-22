import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/models.dart';

class ApiService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  ApiService();

  /// Saves the device FCM token to the current user's Firestore doc.
  /// Called on login and app resume.
  /// Per firebase skill: server must read the token — never trust client to send it inline.
  Future<void> saveFcmToken() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _db.collection('users').doc(user.uid).update({'fcm_token': token});
    } catch (_) {
      // Non-fatal — notifications degrade gracefully
    }
  }

  Future<void> checkAuthRateLimit() async {
    try {
      await _functions
          .httpsCallable('checkAuthRateLimit',
              options: HttpsCallableOptions(timeout: const Duration(seconds: 3)))
          .call()
          .timeout(const Duration(seconds: 3));
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception('TOO_MANY_ATTEMPTS');
      }
      // Skip silently for any other Cloud Function error (not-found, unavailable, etc.)
      return;
    } catch (_) {
      // Timeout, network error, App Check failure — skip silently, never block sign-in
      return;
    }
  }

  Future<fb.UserCredential> signInWithCredential(fb.AuthCredential credential) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        return await currentUser.linkWithCredential(credential);
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // Fallback to sign in if link fails due to existing account
          return await _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }
    return await _auth.signInWithCredential(credential);
  }

  // ─── Auth (Firebase) ────────────────────────────────────
  
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();



  Future<fb.UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      logEvent(WavyEvent(
        userId: cred.user!.uid,
        type: 'user_login',
        action: 'login',
        timestamp: DateTime.now().toUtc().toIso8601String(),
        metadata: {'method': 'email'},
      ));
    }
    return cred;
  }

  Future<fb.UserCredential> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      logEvent(WavyEvent(
        userId: cred.user!.uid,
        type: 'user_signup',
        action: 'signup',
        timestamp: DateTime.now().toUtc().toIso8601String(),
        metadata: {'method': 'email'},
      ));
    }
    return cred;
  }

  Future<fb.UserCredential?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        final isNewUser = cred.additionalUserInfo?.isNewUser ?? false;
        logEvent(WavyEvent(
          userId: cred.user!.uid,
          type: isNewUser ? 'user_signup' : 'user_login',
          action: isNewUser ? 'signup' : 'login',
          timestamp: DateTime.now().toUtc().toIso8601String(),
          metadata: {'method': 'google'},
        ));
      }
      return cred;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  // ─── Feed (Firestore) ───────────────────────────────────
  Future<List<WavyItem>> getFeed({
    int limit = 20,
    String? startAfterId,
    String? gender,
    List<String>? sizes,
    String? category,
    int? minPrice,
    int? maxPrice,
  }) async {
    Query query = _db.collection('items')
        .where('status', isEqualTo: 'active');

    if (gender != null && gender != 'All') {
      query = query.where('gender', isEqualTo: gender);
    }

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    final hasSizes = sizes != null && sizes.isNotEmpty;
    final hasPrice = minPrice != null || maxPrice != null;

    if (hasSizes) {
      if (sizes.length <= 10) {
        query = query.where('size', whereIn: sizes);
      }
      // sizes uses whereIn — price must be filtered client-side
      query = query.orderBy('created_at', descending: true).limit(hasPrice ? limit * 3 : limit);
    } else if (hasPrice) {
      // No sizes filter — safe to use price range on server
      if (minPrice != null) query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      if (maxPrice != null) query = query.where('price', isLessThanOrEqualTo: maxPrice);
      query = query.orderBy('price').orderBy('created_at', descending: true).limit(limit);
    } else {
      query = query.orderBy('created_at', descending: true).limit(limit);
    }

    if (startAfterId != null) {
      final doc = await _db.collection('items').doc(startAfterId).get();
      if (doc.exists) {
        query = query.startAfterDocument(doc);
      }
    }

    final snapshot = await query.get();
    var docs = snapshot.docs.map((doc) => WavyItem.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    })).toList();

    // Client-side price filter when combined with sizes
    if (hasSizes && hasPrice) {
      docs = docs.where((item) {
        final price = item.price;
        if (minPrice != null && price < minPrice) return false;
        if (maxPrice != null && price > maxPrice) return false;
        return true;
      }).take(limit).toList();
    }

    return docs;
  }

  Future<WavyItem> getItem(String id) async {
    final doc = await _db.collection('items').doc(id).get();
    return WavyItem.fromJson({
      ...doc.data()!,
      'id': doc.id,
    });
  }

  // ─── Media (Storage) ────────────────────────────────────
  Future<void> checkUploadRateLimit() async {
    try {
      await _functions.httpsCallable('checkUploadRateLimit').call();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw Exception('UPLOAD_LIMIT_REACHED');
      if (e.code == 'not-found') return; // Fallback
      rethrow;
    }
  }

  Future<String> uploadImage(File file, String path, {Map<String, String>? customMetadata}) async {
    await checkUploadRateLimit();
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(customMetadata: customMetadata);
    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ─── Sell / Publish (Firestore) ─────────────────────────
  Future<void> checkPublishRateLimit() async {
    try {
      await _functions.httpsCallable('checkPublishRateLimit').call();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw Exception('POST_LIMIT_REACHED');
      if (e.code == 'not-found') return; // Fallback
      rethrow;
    }
  }

  Future<WavyItem> publishItem(Map<String, dynamic> itemData) async {
    await checkPublishRateLimit();
    final docRef = _db.collection('items').doc();
    final dataWithId = {
      ...itemData,
      'id': docRef.id,
      'created_at': FieldValue.serverTimestamp(),
    };
    try {
      await docRef.set(dataWithId);
      return WavyItem.fromJson(dataWithId);
    } catch (e) {
      if (e.toString().contains('resource-exhausted') || e.toString().contains('limit')) {
        throw Exception('POST_LIMIT_REACHED');
      }
      rethrow;
    }
  }

  // ─── Edit / Delete Item ────────────────────────────────
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _db.collection('items').doc(itemId).update(data);
  }

  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
    
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      logEvent(WavyEvent(
        userId: userId,
        itemId: itemId,
        type: 'listing_deleted',
        action: 'delete',
        timestamp: DateTime.now().toUtc().toIso8601String(),
      ));
    }
  }

  // ─── Mark Sold ──────────────────────────────────────────
  Future<void> markSold(String itemId) async {
    await _db.collection('items').doc(itemId).update({'status': 'sold'});
  }

  Future<void> markPurchased(String itemId, String userId) async {
    await _db.collection('items').doc(itemId).update({'status': 'sold'});
    await logEvent(WavyEvent(
      userId: userId,
      itemId: itemId,
      type: 'purchase_confirmed',
      action: 'purchased',
      timestamp: DateTime.now().toUtc().toIso8601String(),
      synced: true,
    ));
  }

  // ─── Seller Dashboard ──────────────────────────────────
  Future<Seller?> getSeller(String sellerId) async {
    try {
      final doc = await _db.collection('sellers').doc(sellerId).get();
      if (doc.exists) {
        return Seller.fromJson({
          ...doc.data()!,
          'id': doc.id,
        });
      }
      
      // Fallback to user document for normal users selling items
      final userDoc = await _db.collection('users').doc(sellerId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return Seller(
          id: userDoc.id,
          name: userData['fullName'] ?? userData['name'] ?? 'Wavy User',
          phone: userData['phone'],
          market: 'Individual Seller',
          address: 'Addis Ababa',
          avatarUrl: userData['avatar_url'] as String?,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSellerPhone(String sellerId) async {
    try {
      final result = await _functions.httpsCallable('getSellerPhone').call({
        'sellerId': sellerId,
      });
      return result.data['phone'] as String?;
    } catch (_) {
      // Error fetching private phone removed from production
      return null;
    }
  }

  Future<List<WavyItem>> getSellerListings(String sellerId) async {
    final snapshot = await _db.collection('items')
        .where('seller_id', isEqualTo: sellerId)
        .orderBy('created_at', descending: true)
        .get();
    return snapshot.docs.map((doc) => WavyItem.fromJson({
      ...doc.data(),
      'id': doc.id,
    })).toList();
  }

  // ─── Swipe Logging ──────────────────────────────────────
  Future<void> recordSwipe(String itemId, String userId, String action) async {
    await logEvent(WavyEvent(
      userId: userId,
      itemId: itemId,
      type: 'swipe_event',
      action: action, // 'save' or 'pass'
      timestamp: DateTime.now().toUtc().toIso8601String(),
      synced: true,
    ));

    // Increment swipe count
    try {
      await _db.collection('items').doc(itemId).update({
        'swipe_count': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  // ─── Events ─────────────────────────────────────────────
  Future<void> logEvent(WavyEvent event) async {
    try {
      await _db.collection('events').add(event.toJson());
    } catch (_) {
      // Will be queued offline if this fails
    }
  }

  // ─── Users (Firestore) ──────────────────────────────────
  Future<WavyUser?> getUser(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return WavyUser.fromJson(doc.data()!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> createUser(WavyUser user) async {
    await _db.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  // ─── Avatar (Storage + Firestore) ─────────────────────────
  Future<String> uploadAvatar(File file, String userId) async {
    final ref = FirebaseStorage.instance.ref().child('users/$userId/avatar.jpg');
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'userId': userId},
    );
    final snapshot = await ref.putFile(file, metadata);
    final url = await snapshot.ref.getDownloadURL();
    await _db.collection('users').doc(userId).update({'avatar_url': url});
    return url;
  }

  Future<void> deleteAvatar(String userId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('users/$userId/avatar.jpg');
      await ref.delete();
    } catch (_) {
      // File may not exist — safe to ignore
    }
    await _db.collection('users').doc(userId).update({'avatar_url': FieldValue.delete()});
  }

  // ─── Utility ────────────────────────────────────────────
  String generateId() {
    return _db.collection('temp').doc().id;
  }

  // ─── Saved Items (Firestore) ──────────────────────────────
  Future<void> saveItem(String userId, String itemId) async {
    await _db.collection('users').doc(userId).collection('saved').doc(itemId).set({
      'saved_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsaveItem(String userId, String itemId) async {
    await _db.collection('users').doc(userId).collection('saved').doc(itemId).delete();
  }

  Future<List<WavyItem>> getSavedItems(String userId) async {
    final snapshot = await _db.collection('users').doc(userId).collection('saved').get();
    final itemIds = snapshot.docs.map((doc) => doc.id).toList();
    if (itemIds.isEmpty) return [];
    
    // Chunk requests into 30 to bypass whereIn limits
    final List<WavyItem> items = [];
    for (var i = 0; i < itemIds.length; i += 30) {
      final chunk = itemIds.sublist(i, i + 30 > itemIds.length ? itemIds.length : i + 30);
      final itemDocs = await _db.collection('items').where(FieldPath.documentId, whereIn: chunk).get();
      items.addAll(itemDocs.docs.map((doc) => WavyItem.fromJson({...doc.data(), 'id': doc.id})));
    }
    return items;
  }

  // ─── Chat (Firestore) ─────────────────────────────────────
  Stream<List<ChatConversation>> getConversations(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('updated_at', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(25) // Load 25 most recent messages — enough for most active threads
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}, doc: doc))
            .toList());
  }

  Future<List<ChatMessage>> loadMoreMessages(String conversationId, DocumentSnapshot lastDoc) async {
    final snapshot = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDoc)
        .limit(20) // Load 20 more per page when user scrolls up
        .get();

    return snapshot.docs
        .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}, doc: doc))
        .toList();
  }

  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    final batch = _db.batch();
    
    final msgRef = _db.collection('conversations').doc(conversationId).collection('messages').doc();
    batch.set(msgRef, message.toJson());
    
    final convRef = _db.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'last_message': message.toJson(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  // ─── Chat Images (Storage) ─────────────────────────────────
  Future<String> uploadChatImage(File file, String conversationId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('chats/$conversationId/$timestamp.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    final snapshot = await ref.putFile(file, metadata);
    return await snapshot.ref.getDownloadURL();
  }

  Future<int> getChatImageCount(String conversationId, String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final snapshot = await _db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('sender_id', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      return snapshot.docs.where((doc) => doc.data()['image_url'] != null).length;
    } catch (_) {
      // If index is missing or query fails, allow the upload
      return 0;
    }
  }

  // ─── Chat Reactions ────────────────────────────────────────
  Future<void> addReaction(String conversationId, String messageId, String userId, String emoji) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': emoji});
  }

  Future<void> removeReaction(String conversationId, String messageId, String userId) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': FieldValue.delete()});
  }

  Future<String> startOrGetConversation(List<String> participants) async {
    final sortedParticipants = List<String>.from(participants)..sort();
    final conversationKey = sortedParticipants.join('_');
    final currentUser = _auth.currentUser;
    
    // Query must include arrayContains so Firestore rules can validate
    // that the caller is a participant (rules require uid in participants)
    final query = await _db.collection('conversations')
        .where('conversation_key', isEqualTo: conversationKey)
        .where('participants', arrayContains: currentUser?.uid)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    
    final docRef = await _db.collection('conversations').add({
      'participants': participants,
      'conversation_key': conversationKey,
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    final user = _auth.currentUser;
    if (user != null) {
      logEvent(WavyEvent(
        userId: user.uid,
        type: 'conversation_started',
        action: 'start_chat',
        timestamp: DateTime.now().toUtc().toIso8601String(),
        metadata: {'participants': participants},
      ));
    }
    
    return docRef.id;
  }

  Future<void> deleteConversation(String conversationId) async {
    // Note: To fully delete a thread, cloud functions should ideally sweep
    // the subcollections. For the client side, we remove the doc.
    await _db.collection('conversations').doc(conversationId).delete();
  }

  // ─── Cloud Functions & Notifications ───────────────────
  Future<void> updateFcmToken(String userId, String token) async {
    await _db.collection('users').doc(userId).update({'fcm_token': token});
  }

  Future<String> generateShareLink(String itemId) async {
    try {
      final result = await _functions.httpsCallable('generateShareLink').call({
        'itemId': itemId,
      });
      return result.data['shortUrl'] as String;
    } catch (e) {
      // Fallback for offline/dev
      return 'https://wavy.app/item/$itemId';
    }
  }

  Future<void> requestPremium() async {
    await _functions.httpsCallable('requestPremium').call();
  }

  // ─── Analytics & Auditing ──────────────────────────────
  Future<void> logAudit(String eventName, Map<String, dynamic> params) async {
    final user = _auth.currentUser;
    await _db.collection('events').add({
      'event_name': eventName,
      'params': params,
      'user_id': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── Data Migration (Experimental/Dev) ──────────────────
  Future<void> migrateDummyData(List<WavyItem> items, List<Seller> sellers) async {
    final batch = _db.batch();
    
    // Upload sellers
    for (final seller in sellers) {
      final docRef = _db.collection('sellers').doc(seller.id);
      batch.set(docRef, seller.toJson());
    }

    // Upload items
    for (final item in items) {
      final docRef = _db.collection('items').doc(item.id);
      final json = item.toJson();
      // Ensure created_at is a Timestamp for Firestore sorting
      json['created_at'] = FieldValue.serverTimestamp();
      batch.set(docRef, json);
    }

    await batch.commit();
  }

  // ─── Unread Message Tracking ────────────────────────────────────
  Future<void> markConversationRead(String conversationId, String userId) async {
    await _db.collection('conversations').doc(conversationId).update({
      'last_read_at.$userId': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> getUnreadConversationCount(String userId) {
    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int unread = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final lastReadAt = (data['last_read_at'] as Map<String, dynamic>?)?[userId];
            final updatedAt = data['updated_at'];
            if (lastReadAt == null && updatedAt != null) {
              // Never read = unread if there's a message
              final lastMsg = data['last_message'] as Map<String, dynamic>?;
              if (lastMsg != null && lastMsg['sender_id'] != userId) unread++;
            } else if (lastReadAt != null && updatedAt != null) {
              final readTs = lastReadAt is Timestamp ? lastReadAt : null;
              final updateTs = updatedAt is Timestamp ? updatedAt : null;
              if (readTs != null && updateTs != null && updateTs.compareTo(readTs) > 0) {
                final lastMsg = data['last_message'] as Map<String, dynamic>?;
                if (lastMsg != null && lastMsg['sender_id'] != userId) unread++;
              }
            }
          }
          return unread;
        });
  }
}
