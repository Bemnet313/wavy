import 'package:cloud_firestore/cloud_firestore.dart';

class WavyItem {
  final String id;
  final String title;
  final String? titleAm;
  final int price;
  final String currency;
  final String size;
  final String condition;
  final List<String> images;
  final String sellerId;
  final String tagId;
  final String status;
  final int swipeCount;
  final int interestCount;
  final String category;
  final String createdAt;

  const WavyItem({
    required this.id,
    required this.title,
    this.titleAm,
    required this.price,
    this.currency = 'ETB',
    required this.size,
    required this.condition,
    required this.images,
    required this.sellerId,
    required this.tagId,
    this.status = 'active',
    this.swipeCount = 0,
    this.interestCount = 0,
    required this.category,
    required this.createdAt,
  });

  factory WavyItem.fromJson(Map<String, dynamic> json) {
    String createdAtStr = '';
    final createdAt = json['created_at'];
    if (createdAt is Timestamp) {
      createdAtStr = createdAt.toDate().toIso8601String();
    } else if (createdAt is String) {
      createdAtStr = createdAt;
    }

    return WavyItem(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAm: json['title_am'] as String?,
      price: json['price'] as int,
      currency: json['currency'] as String? ?? 'ETB',
      size: json['size'] as String,
      condition: json['condition'] as String,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      sellerId: json['seller_id'] as String,
      tagId: json['tag_id'] as String,
      status: json['status'] as String? ?? 'active',
      swipeCount: json['swipe_count'] as int? ?? 0,
      interestCount: json['interest_count'] as int? ?? 0,
      category: json['category'] as String,
      createdAt: createdAtStr,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'title_am': titleAm,
        'price': price,
        'currency': currency,
        'size': size,
        'condition': condition,
        'images': images,
        'seller_id': sellerId,
        'tag_id': tagId,
        'status': status,
        'swipe_count': swipeCount,
        'interest_count': interestCount,
        'category': category,
        'created_at': createdAt,
      };

  WavyItem copyWith({
    String? id,
    String? title,
    String? titleAm,
    int? price,
    String? currency,
    String? size,
    String? condition,
    List<String>? images,
    String? sellerId,
    String? tagId,
    String? status,
    int? swipeCount,
    int? interestCount,
    String? category,
    String? createdAt,
  }) {
    return WavyItem(
      id: id ?? this.id,
      title: title ?? this.title,
      titleAm: titleAm ?? this.titleAm,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      tagId: tagId ?? this.tagId,
      status: status ?? this.status,
      swipeCount: swipeCount ?? this.swipeCount,
      interestCount: interestCount ?? this.interestCount,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Seller {
  final String id;
  final String name;
  final String? phone;
  final String market;
  final String address;
  final String? avatarUrl;
  final bool verified;
  final double rating;
  final int totalSales;

  const Seller({
    required this.id,
    required this.name,
    this.phone,
    required this.market,
    this.address = 'Addis Ababa, Ethiopia',
    this.avatarUrl,
    this.verified = false,
    this.rating = 0.0,
    this.totalSales = 0,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      market: json['market'] as String,
      address: json['address'] as String? ?? 'Addis Ababa, Ethiopia',
      avatarUrl: json['avatar_url'] as String?,
      verified: json['verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalSales: json['total_sales'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (phone != null) 'phone': phone,
        'market': market,
        'address': address,
        'avatar_url': avatarUrl,
        'verified': verified,
        'rating': rating,
        'total_sales': totalSales,
      };
}

class WavyUser {
  final String id;
  final String phone;
  final String? name;
  final UserPreferences preferences;
  final String language;
  final List<String> savedItems;
  final String? fcmToken;

  const WavyUser({
    required this.id,
    required this.phone,
    this.name,
    required this.preferences,
    this.language = 'en',
    this.savedItems = const [],
    this.fcmToken,
  });

  factory WavyUser.fromJson(Map<String, dynamic> json) {
    return WavyUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      preferences: UserPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>? ?? {}),
      language: json['language'] as String? ?? 'en',
      savedItems:
          (json['saved_items'] as List<dynamic>?)?.cast<String>() ?? [],
      fcmToken: json['fcm_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'preferences': preferences.toJson(),
        'language': language,
        'saved_items': savedItems,
        'fcm_token': fcmToken,
      };

  WavyUser copyWith({
    String? id,
    String? phone,
    String? name,
    UserPreferences? preferences,
    String? language,
    List<String>? savedItems,
    String? fcmToken,
  }) {
    return WavyUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      preferences: preferences ?? this.preferences,
      language: language ?? this.language,
      savedItems: savedItems ?? this.savedItems,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

class UserPreferences {
  final String gender;
  final List<String> sizes;
  final List<String> styles;
  final int? age;
  final bool hasSeenTutorial;

  const UserPreferences({
    this.gender = '',
    this.sizes = const [],
    this.styles = const [],
    this.age,
    this.hasSeenTutorial = false,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      gender: json['gender'] as String? ?? '',
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>() ?? [],
      styles: (json['styles'] as List<dynamic>?)?.cast<String>() ?? [],
      age: json['age'] as int?,
      hasSeenTutorial: json['has_seen_tutorial'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'sizes': sizes,
        'styles': styles,
        if (age != null) 'age': age,
        'has_seen_tutorial': hasSeenTutorial,
      };
}

class WavyEvent {
  final String? id;
  final String userId;
  final String itemId;
  final String type; // swipe_event, interest_event, call_event, mark_sold, purchase_confirmed
  final String action;
  final String timestamp;
  final bool synced;

  const WavyEvent({
    this.id,
    required this.userId,
    required this.itemId,
    required this.type,
    required this.action,
    required this.timestamp,
    this.synced = false,
  });

  factory WavyEvent.fromJson(Map<String, dynamic> json) {
    return WavyEvent(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      itemId: json['item_id'] as String,
      type: json['type'] as String,
      action: json['action'] as String,
      timestamp: json['timestamp'] as String,
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'item_id': itemId,
        'type': type,
        'action': action,
        'timestamp': timestamp,
        'synced': synced,
      };
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String timestamp;
  final String? attachedItemId;
  /// Firestore document reference used as a cursor for pagination.
  /// Only populated when messages are loaded from Firestore queries.
  final DocumentSnapshot? docRef;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.attachedItemId,
    this.docRef,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {DocumentSnapshot? doc}) {
    String tsStr = '';
    final ts = json['timestamp'];
    if (ts is Timestamp) {
      tsStr = ts.toDate().toIso8601String();
    } else if (ts is String) {
      tsStr = ts;
    }

    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String,
      text: json['text'] as String,
      timestamp: tsStr,
      attachedItemId: json['attached_item_id'] as String?,
      docRef: doc,
    );
  }

  Map<String, dynamic> toJson() => {
        'sender_id': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        if (attachedItemId != null) 'attached_item_id': attachedItemId,
      };
}

class ChatConversation {
  final String id;
  final List<String> participants;
  final ChatMessage? lastMessage;
  final String updatedAt;
  final Map<String, dynamic>? metadata;

  const ChatConversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.updatedAt,
    this.metadata,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    String upStr = '';
    final up = json['updated_at'];
    if (up is Timestamp) {
      upStr = up.toDate().toIso8601String();
    } else if (up is String) {
      upStr = up;
    }

    return ChatConversation(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>).cast<String>(),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      updatedAt: upStr,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
