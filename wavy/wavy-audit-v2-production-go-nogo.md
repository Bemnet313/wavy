# Wavy — Production Go / No-Go Audit
### Version 2 · Audit Date: March 6, 2026

---

## 🔴 FINAL VERDICT: NO-GO

**Plain English:** Every critical problem we found in the first audit (March 3, 2026) is
**still present today.** None of the five showstopper issues have been fixed. The app
works — users can browse, save, list, and message — but it is **not safe to open to
the public** in its current state. Launching now would expose the business to privacy
lawsuits, spam abuse, and users permanently locked out of their accounts.

---

## What Changed Since the First Audit?

| Area | Before (March 3) | Today (March 6) | Change |
|------|-----------------|-----------------|--------|
| FCM Push Notifications | ❌ Missing | ✅ Deployed | **Fixed** |
| Image Thumbnail Generation | ❌ Missing | ✅ Deployed | **Fixed** |
| Chat messaging (permission-denied bug) | ❌ Broken | ✅ Working | **Fixed** |
| Password reset | ❌ Missing | ❌ Still missing | Not fixed |
| Email verification | ❌ Missing | ❌ Still missing | Not fixed |
| Seller contact privacy breach | ❌ Open hole | ❌ Still open | Not fixed |
| Message sending rate limit | ❌ Missing | ❌ Still missing | Not fixed |
| Account deletion | ❌ Missing | ❌ Still missing | Not fixed |

---

## At-a-Glance Scorecard

| Category | Score | Status |
|----------|-------|--------|
| Core app flows (browse, save, list, message) | 8 / 10 | ✅ Working well |
| Authentication security | 3 / 10 | 🔴 Critical gaps |
| Data privacy | 4 / 10 | 🔴 Phone numbers exposed |
| Abuse prevention | 5 / 10 | 🟡 Good for uploads; missing on messages |
| Legal & compliance | 2 / 10 | 🔴 No GDPR-style account deletion |
| Test coverage | 2 / 10 | 🟡 Only 12 basic tests |
| App store readiness | 6 / 10 | 🟡 Builds fine; APK size too big |
| **Overall production readiness** | **4 / 10** | 🔴 **NO-GO** |

---

## Critical Issues — Must Fix Before Any Public Launch

These five issues are not optional. A real user will hit all of them within the
first week of operation.

---

### 🔴 BLOCKER 1: No Password Reset

**What it means for users:**
Every person who creates an account with email and later forgets their password is
**permanently locked out.** They lose access to all their saved items, their listing
history, and their conversation threads. They cannot get back in. There is no
"Forgot Password" button anywhere in the app.

**What it means for the business:**
High churn at the authentication stage. Users who get locked out leave bad reviews.
Support emails pile up with no good answer to give them.

**How hard is it to fix:** 2–4 hours of work. Firebase already has this built in.
A developer just needs to wire up the button.

**Status since last audit:** ❌ Not started.

---

### 🔴 BLOCKER 2: No Email Verification

**What it means for users:**
Anyone can create an account using an email address they do not own. Example: a
single person could create 100 fake accounts using random email addresses, flood the
feed with fake or misleading listings, and harass sellers through messaging — all
without verification.

**What it means for the business:**
Feed spam destroys trust. Sellers receiving harassment messages will leave. The app
develops a reputation as unsafe.

**How hard is it to fix:** 2–4 hours. Firebase has this built in too.

**Status since last audit:** ❌ Not started.

---

### 🔴 BLOCKER 3: Seller Phone Numbers Are Publicly Accessible

**What it means:**
Every seller's private phone number — stored in what the code calls a "private"
folder — can be read by any person who has an account in the app, even without
pressing the "GET THE FIT / Reveal Contact" button. The security rule that is
supposed to protect this actually leaves it wide open to anyone logged in.

Technically verified: line 24 of `firestore.rules` reads
`allow read: if isAuthenticated();` — this means every logged-in user can query
the database directly and download every seller's phone number in bulk.

**What it means for the business:**
Privacy violation. Sellers are trusting the app with their personal phone numbers.
If those numbers are harvested and sold, or used for spam calls, Wavy is liable.
This is the type of issue that leads to regulatory investigation in many markets.

**How hard is it to fix:** 1–2 hours. One-line change in the database rules file,
already known by the development team.

**Status since last audit:** ❌ Not started. The rule is exactly as it was on March 3.

---

### 🔴 BLOCKER 4: No Limit on Message Sending

**What it means:**
There are no limits on how many messages a user can send. A harasser can open any
chat thread and send **thousands of messages per minute** to a seller. There is
currently no server-side check that stops this.

For comparison: the app already has sensible limits on uploading photos (15/hour)
and creating listings (5/day). Messages have no equivalent protection at all.

**What it means for the business:**
Sellers experience harassment. Support load increases. Firebase costs spike because
every message is a database write that costs money. A coordinated spam campaign
could generate unexpected hosting bills.

**How hard is it to fix:** 4–8 hours. The development team can copy the existing
upload limits pattern into a new message-rate check.

**Status since last audit:** ❌ Not started. No rate limit function exists for messages.

---

### 🔴 BLOCKER 5: No Way To Delete Your Account

**What it means:**
There is no "Delete Account" option anywhere in the app. If a user wants to
remove their personal data, their listings, and their conversation history from
the platform, there is no way for them to do it themselves.

**What it means for the business:**
In Ethiopia and in most international markets where fashion startups seek
investment, data deletion rights are increasingly required. If a user contacts
support asking to delete their account, you currently have no automated
mechanism — a developer would have to do it manually in the Firebase console.
This is also a legal risk as the app expands.

**How hard is it to fix:** 4–8 hours. A "Delete Account" button in Settings
with a confirmation dialog.

**Status since last audit:** ❌ Not started. The Settings screen (`settings_screen.dart`)
contains no account deletion option.

---

## Medium Issues — Fix Before Wide Release

These will not cause a data breach or user lockout, but they will cause visible
problems as the user base grows.

---

### 🟡 Chat Deletion Leaves Hidden Garbage Data

**Plain English:** When a user deletes a conversation, the chat disappears from
the screen — but all the individual messages stay saved in the database forever,
invisible and unclaimed. Like clearing your desk but leaving the drawers full of
old papers. Over months, this adds storage cost for no reason.

**Fix:** Automated cleanup when a conversation is deleted (4–8 hours).
**Status:** ❌ Not fixed.

---

### 🟡 Thumbnail Images Cannot Be Revoked

**Plain English:** When a listing photo is uploaded, the app auto-generates a
small preview image. That preview gets a special URL that expires in the year
2099 — essentially forever. If the seller deletes the listing, the preview image
URL is still active and anyone who saved that link can still see the photo.

**Fix:** Switch to a standard storage link instead of a special time-expiring URL
(2–4 hours). **Status:** ❌ Not fixed (confirmed in `functions/index.js`, line 330–333).

---

### 🟡 App Can Crash During Save/Publish If User Navigates Away

**Plain English:** If a user taps "PUBLISH" on a listing and then immediately
taps the back button while the app is uploading the photos, there is a small
chance the app crashes. This happens on the Sell screen and the Preferences
screen. It was flagged by the code quality checker.

**Fix:** One line of code per location (1–2 hours total, 4 locations).
**Status:** ❌ Still present (confirmed by `flutter analyze`).

---

### 🟡 No SSL Pinning

**Plain English:** On public WiFi (like in a café or mall), a sophisticated
attacker with the right tools could potentially intercept the data flowing
between the app and Firebase. This is an advanced attack, not something a
casual bad actor would do — but it is worth addressing before broad deployment.

**Fix:** Certificate pinning implementation (4–8 hours).
**Status:** ❌ Not started.

---

### 🟡 Test Data Migration Code Left in Production

**Plain English:** There is a function in the code called `migrateDummyData()`
that was used during development to fill the app with fake test products. It
still exists in the production codebase. While it is not automatically triggered,
an accidental call in the wrong context could corrupt production data.

**Fix:** Remove or lock the function (under 1 hour).
**Status:** ❌ Not fixed.

---

## Minor Issues — Polish Before App Store Submission

| Issue | Business Impact | Est. Time |
|-------|----------------|-----------|
| App APK is 81 MB — too large for Ethiopian networks | Users on limited data plans may abandon the download | 1–2h |
| Web login uses a test security key | Web version will be insecure at launch | 1h |
| Chat initially shows only 5 messages | Active conversations look broken | 1h |
| Feed shows items the user already swiped | Confusing repeat experience | 4–8h |
| Some Amharic translations missing | Amharic users see random English text | 4–8h |

---

## What Is Working Well ✅

The following areas are solid and production-grade:

- **Feed, swiping, filtering** — fully working with live Firebase data and pagination
- **Listing creation** — image upload, pricing validation, publish rate limits all work
- **Edit/Delete listings** — owner-only permissions enforced properly
- **Push notifications** — FCM working end-to-end (new since last audit)
- **Photo thumbnails** — auto-generated at upload (new since last audit)
- **Real-time messaging** — Firebase live sync, FCM push, 75-thread limit
- **Google Sign-In** — working for new and returning users
- **Analytics events** — login, signup, swipe, purchase events logged
- **Rate limits** — auth (10/min/IP), uploads (15/hr), publish (5/day) all deployed
- **Security rules** — items, conversations, user data all properly access-controlled
- **CI pipeline** — auto-builds on every code push to GitHub
- **Build quality** — compiles cleanly, zero errors, zero warnings in static analysis

---

## How Many Hours to Production-Ready?

Based on this audit, the total remaining work for a safe public launch is:

| Priority | Issue | Hours |
|----------|-------|-------|
| Critical | Password reset | 2–4h |
| Critical | Email verification | 2–4h |
| Critical | Fix seller contact privacy | 1–2h |
| Critical | Message rate limit | 4–8h |
| Critical | Account deletion | 4–8h |
| Medium | Chat orphan data cleanup | 4–8h |
| Medium | Thumbnail URL fix | 2–4h |
| Medium | Async crash fixes | 1–2h |
| Minor | APK size reduction | 1–2h |
| Minor | Chat message load count | 1h |

**Total estimated effort: 22–43 developer hours (3–5 working days for one developer)**

After those fixes, re-run this audit. The app should reach **CONDITIONAL GO** for
a limited beta audience.

---

## Recommended Next 3 Actions (In Order)

1. **Fix the seller contact privacy rule** — 1 line change, 2 hours maximum. Do this today.
2. **Add password reset + email verification** — both are Firebase built-ins. 1 developer, 1 day.
3. **Add message rate limit** — copy the existing upload limit pattern. 1 developer, 1 day.

After steps 1–3, the five critical blockers are resolved and the app is ready for
a small private beta with real users.

---

*Auditor: Antigravity AI · Date: March 6, 2026 · Version: 2.0*
*This audit reflects code in the repository as reviewed on the date above.*
*A clean re-audit is recommended after all Critical blockers are resolved.*
