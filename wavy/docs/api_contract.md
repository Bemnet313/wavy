# Wavy API Contract 

Base Source: Local JSON Server (`http://localhost:3000`)

---

## 1. Auth Flow

### POST `/auth/send-otp`
- **Body**: `{ "phone": "+251911..." }`
- **Response**: `{ "success": true }`

### POST `/auth/verify-otp`
- **Body**: `{ "phone": "+251911...", "code": "123456" }`
- **Response**: `{ "token": "jwt...", "user": { "id": "user1", "name": "B" } }`

---

## 2. Item & Feed Discovery

### GET `/items/feed`
- **Response**: `[ { WavyItem Model } ]`

### GET `/items/{id}`
- **Response**: `{ WavyItem Model }`

### POST `/items/publish`
- **Body**: `{ WavyItem Model }`
- **Response**: `201 OK`

---

## 3. Intents & Interactions

### POST `/items/{id}/interest`
- **Body**: `{ "user_id": "user1" }`
- **Response**: `201 Created`

### POST `/items/{id}/call`
- **Body**: `{ "user_id": "user1" }`
- **Response**: `201 Created`

### POST `/items/{id}/mark-purchased`
- **Body**: `{ "seller_id": "seller1" }`
- **Response**: `{ "success": true }`

---

## 4. Sellers

### GET `/seller/{id}/dashboard`
- **Response**: `{ "seller": { Seller Model }, "listings": [ { WavyItem Model } ] }`
