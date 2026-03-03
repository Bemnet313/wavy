import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wavy/src/models/models.dart';

void main() {
  group('Models JSON serialization', () {
    test('WavyItem parses correctly with all fields', () {
      final json = {
        'id': 'item-1',
        'seller_id': 'seller-1',
        'title': 'Jacket',
        'title_am': 'ጃኬት',
        'tag_id': 'tag1',
        'images': ['url1.jpg'],
        'price': 1000,
        'category': 'Men',
        'condition': 'New',
        'size': 'M',
        'status': 'active',
        'gender': 'Men',
        'swipe_count': 5,
        'interest_count': 2,
        'created_at': '2023-01-01T00:00:00Z',
      };

      final item = WavyItem.fromJson(json);

      expect(item.id, 'item-1');
      expect(item.price, 1000.0);
      expect(item.titleAm, 'ጃኬት');
      expect(item.status, 'active');
      expect(item.images.length, 1);
    });

    test('WavyItem handles missing fields with defaults', () {
      final json = {
        'id': 'item-2',
        'seller_id': 'seller-2',
        'tag_id': 'tag2',
        'title': 'Pants',
        'images': [],
        'price': 500,
        'category': 'Men',
        'condition': 'Used',
        'size': 'L',
        'created_at': '2023-01-01T00:00:00Z',
      };

      final item = WavyItem.fromJson(json);

      expect(item.titleAm, isNull);
      expect(item.currency, 'ETB'); // default
      expect(item.swipeCount, 0); // default
      expect(item.interestCount, 0); // default
    });

    test('WavyItem handles Timestamp for created_at', () {
      final now = Timestamp.now();
      final json = {
        'id': 'item-3',
        'seller_id': 'seller-3',
        'title': 'Timestamp Test',
        'tag_id': 'tag3',
        'images': [],
        'price': 100,
        'category': 'Women',
        'condition': 'New',
        'size': 'M',
        'created_at': now,
      };

      final item = WavyItem.fromJson(json);
      expect(DateTime.parse(item.createdAt).difference(now.toDate()).inSeconds, 0);
    });

    test('Seller parses correctly', () {
      final json = {
        'id': 'seller-1',
        'name': 'Test Store',
        'phone': '0911223344',
        'market': 'M1',
        'rating': 4.5,
        'verified': true,
        'total_sales': 10,
        'joined_year': 2022,
      };

      final seller = Seller.fromJson(json);
      expect(seller.id, 'seller-1');
      expect(seller.rating, 4.5);
      expect(seller.verified, true);
    });

    test('Seller uses false/defaults when missing', () {
      final json = {
        'id': 'seller-2',
        'name': 'Basic Store',
        'phone': null,
        'market': 'M2',
        'joined_year': 2024,
      };

      final seller = Seller.fromJson(json);
      expect(seller.verified, false);
      expect(seller.rating, 0.0);
      expect(seller.totalSales, 0);
    });

    test('ChatMessage parses correctly', () {
      final json = {
        'id': 'msg-1',
        'sender_id': 'user-1',
        'text': 'Hello',
        'timestamp': '2023-01-01T00:00:00Z',
        'attached_item_id': 'item-1',
      };

      final msg = ChatMessage.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.text, 'Hello');
      expect(msg.attachedItemId, 'item-1');
    });
  });
}
