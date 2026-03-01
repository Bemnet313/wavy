# Wavy App - API Contract (Firestore & Cloud Functions)

This details the abstract operational endpoints the client needs for integration. Since we are using Firebase, many of these "endpoints" are direct SDK reads/writes or callable Cloud Functions.

## Auth

**POST /auth/otp/send** (Firebase Phone Auth SDK)
- Request: `{ "phone": "+251..." }`
- Response: Firebase sets state up internally -> `{ "verificationId": "requestId" }`

**POST /auth/otp/verify** (Firebase Phone Auth SDK)
- Request: `{ "verificationId": "...", "smsCode": "..." }`
- Response: Firebase authenticates user session -> `{ "userToken": "..." }`

## Items

**GET /items**
- Call: `FirebaseFirestore.instance.collection('items').where('status', isEqualTo: 'active').get()`
- Description: Queries the active feed. Paginated queries with tokens (`startAfterDocument`) should be used.

**GET /items/{id}**
- Call: `FirebaseFirestore.instance.collection('items').doc(id).get()`
- Response: Returns single Item Document.

**POST /items** (Create Listing)
1. **Upload Images**: Multipart upload to Firebase Storage to `items/{itemId}/original.jpg`
2. **Write Doc**: Write metadata explicitly to `/items/{itemId}` containing the original storage URLs. (A Cloud Function will background process thumbnails.)

**PUT /items/{id}** (Update Listing)
- Call: `.doc(id).update({ "price": 270 })`

**POST /items/{id}/mark-sold** (Mark Sold)
- Call: `.doc(id).update({ "status": "sold" })`

## Saves

**POST /users/{uid}/saved**
- Call: Write `{ "itemId": "item_123", "savedAt": FieldValue.serverTimestamp() }` to `/users/{uid}/saved/{itemId}`

**GET /users/{uid}/saved**
- Call: Retrieve Snapshot stream of `/users/{uid}/saved`

## Share Links

**GET /s/{shortId}**
- Call: Callable Cloud Function `generateShareLink`
- Request: `{ "itemId": "item_123" }`
- Response: `{ "shortUrl": "https://wavy.app/s/aBcDeF" }`

## Conversations & Chat

**POST /conversations**
- Call: Check if `/conversations` document exists mapping the sender and receiver. If not, create definition tracking `participants: [uid1, uid2]`.

**GET /conversations/{convId}/messages**
- Call: Listen to realtime updates `collection('conversations').doc(convId).collection('messages').orderBy('createdAt', descending: true).limit(50).snapshots()`
- Response: Stream of new messages payload

**POST /conversations/{convId}/messages**
- Call: `.collection('conversations').doc(convId).collection('messages').add({ ... })`

## Phone Reveal

**POST /items/{id}/interest**
- Call: Trigger callable function or write to event queue
- Request: `{ "itemId": "item_... " }`
- Response: Trigger writes a `phoneReveal` record and retrieves masked/unmasked numbers depending on buyer verification state.
