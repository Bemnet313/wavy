// Data models for the Wavy app

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
      createdAt: json['created_at'] as String,
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
  final String phone;
  final String market;
  final String address;
  final String? avatarUrl;
  final bool verified;
  final double rating;
  final int totalSales;

  const Seller({
    required this.id,
    required this.name,
    required this.phone,
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
      phone: json['phone'] as String,
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
        'phone': phone,
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

  const WavyUser({
    required this.id,
    required this.phone,
    this.name,
    required this.preferences,
    this.language = 'en',
    this.savedItems = const [],
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'preferences': preferences.toJson(),
        'language': language,
        'saved_items': savedItems,
      };

  WavyUser copyWith({
    String? id,
    String? phone,
    String? name,
    UserPreferences? preferences,
    String? language,
    List<String>? savedItems,
  }) {
    return WavyUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      preferences: preferences ?? this.preferences,
      language: language ?? this.language,
      savedItems: savedItems ?? this.savedItems,
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
