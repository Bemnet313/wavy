import 'package:dio/dio.dart';
import '../models/models.dart';

class ApiService {
  late final Dio _dio;
  
  // Default to localhost for web, 10.0.2.2 for Android emulator
  static const String _defaultBaseUrl = 'http://localhost:3000';
  
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

  // ─── Auth ───────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _dio.get('/auth', queryParameters: {'phone': phone});
    final data = response.data as List;
    if (data.isNotEmpty) {
      return data.first as Map<String, dynamic>;
    }
    // Mock: create new auth entry
    final newAuth = {
      'phone': phone,
      'otp': '123456',
      'verified': false,
      'token': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
    };
    final createResponse = await _dio.post('/auth', data: newAuth);
    return createResponse.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    // Mock: accept any 6-digit OTP
    final response = await _dio.get('/auth', queryParameters: {'phone': phone});
    final data = response.data as List;
    if (data.isNotEmpty) {
      final auth = data.first as Map<String, dynamic>;
      // Update verified status
      await _dio.patch('/auth/${auth['id']}', data: {'verified': true});
      return {...auth, 'verified': true};
    }
    throw Exception('Phone not found');
  }

  // ─── Feed ───────────────────────────────────────────────
  Future<List<WavyItem>> getFeed({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/items', queryParameters: {
      'status': 'active',
      '_page': page,
      '_limit': limit,
    });
    final data = response.data as List;
    return data.map((json) => WavyItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<WavyItem> getItem(String id) async {
    final response = await _dio.get('/items/$id');
    return WavyItem.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Interest ───────────────────────────────────────────
  Future<Seller> expressInterest(String itemId, String userId) async {
    // Log the interest event
    await logEvent(WavyEvent(
      userId: userId,
      itemId: itemId,
      type: 'interest_event',
      action: 'interest',
      timestamp: DateTime.now().toUtc().toIso8601String(),
      synced: true,
    ));

    // Get the item to find seller
    final item = await getItem(itemId);
    
    // Increment interest count
    await _dio.patch('/items/$itemId', data: {
      'interest_count': item.interestCount + 1,
    });

    // Get seller info
    final sellerResponse = await _dio.get('/sellers/${item.sellerId}');
    return Seller.fromJson(sellerResponse.data as Map<String, dynamic>);
  }

  // ─── Call ───────────────────────────────────────────────
  Future<void> logCall(String itemId, String userId) async {
    await logEvent(WavyEvent(
      userId: userId,
      itemId: itemId,
      type: 'call_event',
      action: 'call',
      timestamp: DateTime.now().toUtc().toIso8601String(),
      synced: true,
    ));
  }

  // ─── Sell / Publish ─────────────────────────────────────
  Future<WavyItem> publishItem(Map<String, dynamic> itemData) async {
    final response = await _dio.post('/items', data: itemData);
    return WavyItem.fromJson(response.data as Map<String, dynamic>);
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

  // ─── Users ──────────────────────────────────────────────
  Future<WavyUser?> getUser(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return WavyUser.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<WavyUser> updateUser(String userId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/$userId', data: data);
    return WavyUser.fromJson(response.data as Map<String, dynamic>);
  }
}
