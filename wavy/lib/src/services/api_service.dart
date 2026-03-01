import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  late final Dio _dio;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Load from .env, default to localhost for development
  static String get _defaultBaseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3000';
  
  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
    
    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (log) {}, // Silent in production
    ));
  }

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
    DocumentSnapshot? startAfter,
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

    query = query.orderBy('created_at', descending: true).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
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

  // ─── Interest ───────────────────────────────────────────
  // ... (will refactor later)

  // ─── Media (Storage) ────────────────────────────────────
  Future<String> uploadImage(File file, String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(file);
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
    await docRef.set(dataWithId);
    return WavyItem.fromJson(dataWithId);
  }

  // ─── Mark Sold ──────────────────────────────────────────
  Future<void> markSold(String itemId) async {
    await _dio.patch('/items/$itemId', data: {'status': 'sold'});
  }

  Future<void> markPurchased(String itemId, String userId) async {
    await _dio.patch('/items/$itemId', data: {'status': 'sold'});
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
  Future<Seller> getSeller(String sellerId) async {
    final response = await _dio.get('/sellers/$sellerId');
    return Seller.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<WavyItem>> getSellerListings(String sellerId) async {
    final response = await _dio.get('/items', queryParameters: {
      'seller_id': sellerId,
    });
    final data = response.data as List;
    return data.map((json) => WavyItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ─── Saved Items ────────────────────────────────────────
  Future<List<WavyItem>> getSavedItems(List<String> itemIds) async {
    if (itemIds.isEmpty) return [];
    final List<WavyItem> items = [];
    for (final id in itemIds) {
      try {
        final item = await getItem(id);
        items.add(item);
      } catch (_) {
        // Item may have been deleted
      }
    }
    return items;
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
      final item = await getItem(itemId);
      await _dio.patch('/items/$itemId', data: {
        'swipe_count': item.swipeCount + 1,
      });
    } catch (_) {}
  }

  // ─── Events ─────────────────────────────────────────────
  Future<void> logEvent(WavyEvent event) async {
    try {
      await _dio.post('/events', data: event.toJson());
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

  // ─── Sellers (Firestore) ────────────────────────────────
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

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
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
    
    // Fetch actual items
    final itemDocs = await _db.collection('items').where(FieldPath.documentId, whereIn: itemIds).get();
    return itemDocs.docs.map((doc) => WavyItem.fromJson({...doc.data(), 'id': doc.id})).toList();
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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
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
    // Basic implementation: find existing one or create new
    // For simplicity in prototype, we just search participants
    final query = await _db.collection('conversations')
        .where('participants', arrayContains: participants.first)
        .get();
        
    for (var doc in query.docs) {
      final convParts = (doc['participants'] as List).cast<String>();
      if (convParts.length == participants.length && 
          participants.every((p) => convParts.contains(p))) {
        return doc.id;
      }
    }
    
    final docRef = await _db.collection('conversations').add({
      'participants': participants,
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
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
}
