# Wavy App - Canonical Data Models (Firestore)

These models represent the document structures to be used in Firebase Cloud Firestore for the Wavy application.

### User (collection: `users/{userId}`)
```json
{
  "id": "uid (string)",
  "name": "string",
  "displayName": "string",
  "phone": "+2519xxxxxxxx",
  "avatarUrl": "string|null",
  "role": "buyer|seller|both",
  "verifiedSeller": true|false,
  "preferences": {
    "genders": ["women","men","both"],
    "sizes": ["S","M","L"],
    "styles": ["streetwear","vintage"]
  },
  "createdAt": "timestamp",
  "lastActive": "timestamp"
}
```

### Item / Listing (collection: `items/{itemId}`)
```json
{
  "id": "item_123",
  "sellerId": "uid",
  "title": "Y2K Oversized Jacket",
  "description": "string",
  "price": 250,
  "currency": "ETB",
  "images": ["gs://.../item_123/1.webp", "..."],
  "thumbnail": "gs://.../item_123/thumb.webp",
  "size": "M",
  "condition": "good|fair|excellent",
  "tags": ["vintage","y2k"],
  "status": "active|sold|archived",
  "createdAt": "timestamp",
  "location": { "city": "Addis Ababa", "lat": null, "lng": null }
}
```

### SavedItem (per-user) — stored under `users/{userId}/saved/{itemId}`
```json
{
  "itemId": "item_123",
  "savedAt": "timestamp"
}
```

### Conversation (collection: `conversations/{convId}`)
```json
{
  "id": "conv_456",
  "participants": ["buyerUid", "sellerUid"],
  "lastMessage": "Where is your location?",
  "lastAt": "timestamp",
  "itemContext": "item_123" // optional
}
```

### Messages (subcollection: `conversations/{convId}/messages/{msgId}`)
```json
{
  "id": "msg_1",
  "senderId": "uid",
  "text": "Where are you located?",
  "attachedItemId": "item_123|null",
  "attachments": [], // image URLs for shared images (if allowed later)
  "createdAt": "timestamp",
  "delivered": true|false,
  "readAt": "timestamp|null"
}
```

### EventLog (collection: `events/{id}`)
Store analytics & audit events:
```json
{
  "event": "item_saved|share_copy|open_item|apply_filters|undo_restore",
  "userId": "uid|null",
  "itemId": "item_123|null",
  "meta": {},
  "createdAt": "timestamp"
}
```
