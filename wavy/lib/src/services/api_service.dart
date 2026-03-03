import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/models.dart';

class ApiService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  ApiService();

  // ─── Auth (Firebase) ────────────────────────────────────
  
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(fb.FirebaseAuthException e) onVerificationFailed,
    required Function(fb.PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String verificationId) onCodeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  Future<fb.UserCredential> signInWithCredential(fb.PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Feed (Firestore) ───────────────────────────────────
  Future<List<WavyItem>> getFeed({
    int limit = 20,
    String? startAfterId,
    String? gender,
    List<String>? sizes,
    String? category,
  }) async {
    Query query = _db.collection('items')
        .where('status', isEqualTo: 'active');

    if (gender != null && gender != 'All') {
      query = query.where('gender', isEqualTo: gender);
    }
    
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    if (sizes != null && sizes.isNotEmpty) {
      query = query.where('size', whereIn: sizes);
    }

    // Inactive sellers are handled by the updateSellerActivity Cloud Function
    // which sets status to 'inactive'. We simply exclude those items.
    query = query.where('status', isNotEqualTo: 'inactive');

    query = query.orderBy('created_at', descending: true).limit(limit);

    if (startAfterId != null) {
      final doc = await _db.collection('items').doc(startAfterId).get();
      if (doc.exists) {
        query = query.startAfterDocument(doc);
      }
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => WavyItem.fromJson({
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id,
    })).toList();
  }

  Future<WavyItem> getItem(String id) async {
    final doc = await _db.collection('items').doc(id).get();
    return WavyItem.fromJson({
      ...doc.data()!,
      'id': doc.id,
    });
  }

  // ─── Media (Storage) ────────────────────────────────────
  Future<String> uploadImage(File file, String path, {Map<String, String>? customMetadata}) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(customMetadata: customMetadata);
    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // ─── Sell / Publish (Firestore) ─────────────────────────
  Future<WavyItem> publishItem(Map<String, dynamic> itemData) async {
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
    } catch (e) {
      debugPrint('Error fetching private phone: $e');
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
        .limit(5)
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
        .limit(5)
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

  Future<String> startOrGetConversation(List<String> participants) async {
    final sortedParticipants = List<String>.from(participants)..sort();
    final conversationKey = sortedParticipants.join('_');
    
    final query = await _db.collection('conversations')
        .where('conversation_key', isEqualTo: conversationKey)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Check thread limits before creating a new one
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final activeThreads = await _db.collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .count()
          .get();

      if (activeThreads.count! >= 75) {
        throw Exception('THREAD_LIMIT_REACHED');
      }
    }
    
    final docRef = await _db.collection('conversations').add({
      'participants': participants,
      'conversation_key': conversationKey,
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });
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
}
