import 'package:flutter_test/flutter_test.dart';
import 'package:wavy/src/providers/providers.dart';
import 'package:wavy/src/models/models.dart';

void main() {
  group('FeedState', () {
    test('Initializes with default values', () {
      const state = FeedState();
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.currentPage, 1);
    });

    test('copyWith updates specified values correctly', () {
      const initialState = FeedState();
      
      final mockItem = WavyItem(
        id: '1',
        sellerId: 's1',
        title: 'Test',
        tagId: 'tag1',
        images: [],
        price: 100,
        currency: 'ETB',
        category: 'Men',
        condition: 'New',
        status: 'active',
        size: 'M',
        createdAt: '2023-01-01T00:00:00Z',
      );

      final newState = initialState.copyWith(
        items: [mockItem],
        isLoading: true,
        error: 'Error occurred',
        currentPage: 2,
      );

      expect(newState.items.length, 1);
      expect(newState.items.first.id, '1');
      expect(newState.isLoading, isTrue);
      expect(newState.error, 'Error occurred');
      expect(newState.currentPage, 2);
    });

    test('copyWith clears error if not specified', () {
      const initialState = FeedState(
        isLoading: true,
        error: 'First Error',
      );

      final newState = initialState.copyWith(isLoading: false);

      expect(newState.isLoading, isFalse);
      expect(newState.error, isNull);
    });
  });

  group('AuthState', () {
    test('Initializes with default null/false values', () {
      final state = AuthState();
      expect(state.phone, isNull);
      expect(state.verificationId, isNull);
      expect(state.isVerified, isFalse);
    });

    test('copyWith updates specified values', () {
      final initialState = AuthState();
      final newState = initialState.copyWith(
        phone: '0911',
        verificationId: 'v123',
        isVerified: true,
      );

      expect(newState.phone, '0911');
      expect(newState.verificationId, 'v123');
      expect(newState.isVerified, isTrue);
    });

    test('copyWith retains existing values', () {
      final initialState = AuthState(
        phone: '0900',
        isVerified: false,
      );
      final newState = initialState.copyWith(isVerified: true);

      expect(newState.phone, '0900');
      expect(newState.isVerified, isTrue);
      expect(newState.verificationId, isNull);
    });
  });
}
