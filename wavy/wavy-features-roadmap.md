# Wavy — Feature Roadmap & Opportunities
### Derived from Skills Library Review · March 6, 2026

> **How to read this document:** Each feature below was identified by cross-referencing
> the Wavy platform's current state against a library of 500+ expert skills covering
> everything from payments to AI to search. They are written for a business audience.
> No code required to understand. Priority tiers indicate business value vs. effort.

---

## 🔴 Tier 1 — High Value, Relatively Fast (Fix These First)

These features close gaps that users will actively complain about or that competitors
already have. Most can be shipped within a sprint.

---

### 1. Payments & Booking Inside the App
**What it is:** Let buyers pay for an item inside Wavy, instead of having to call the
seller and sort out payment separately.

**Why it matters:** Right now, the only action inside the app is "reveal phone number."
Everything after that — price negotiation, payment, handoff — happens outside the platform.
Wavy has zero visibility and zero revenue from the actual transaction. Adding even a
simple payment link (Stripe, Telebirr, Chapa for Ethiopia) keeps the transaction inside
the app and creates the foundation for a commission or escrow model.

**Skills behind this:** `stripe-integration`, `payment-integration`, `billing-automation`

**Business impact:** Enables transaction fees. Increases completed sales.
Reduces friction of cash coordination between strangers.

**Effort estimate:** Medium (2–4 weeks for a basic payment flow)

---

### 2. Smart Search and Filtering
**What it is:** A proper search bar where users type what they're looking for (e.g.,
"black leather jacket size M under 500 ETB") and get instant, relevant results.

**Why it matters:** The current feed is swipe-based — good for discovery, bad for
intent. A user who knows what they want has no fast way to find it. They must
scroll through unrelated cards hoping the item appears. Search is the most basic
feature users expect from any marketplace.

**Skills behind this:** `algolia-search`, `hybrid-search-implementation`,
`similarity-search-patterns`

**Business impact:** Increases conversion. Reduces session abandonment. Gives
power users a reason to come back daily.

**Effort estimate:** Low–Medium (1–2 weeks with Algolia or built-in Firestore
full-text-search patterns)

---

### 3. Seller Ratings & Reviews
**What it is:** After a purchase is completed, buyers can leave a 1–5 star rating
and a short comment about the seller. Sellers build a reputation score over time.

**Why it matters:** The app currently shows a "rating" field for sellers but it is
not populated by actual user reviews — it is either hardcoded or empty. Trust is
the core problem in any peer-to-peer marketplace. Reviews are the primary trust
signal. Without them, buyers have no way to assess whether a seller is reliable
before giving out their phone number.

**Skills behind this:** `api-design-principles`, `backend-development-feature-development`

**Business impact:** Dramatically increases buyer confidence.
Reduces risky transactions. Gives sellers incentive to provide great service.

**Effort estimate:** Medium (2–3 weeks)

---

### 4. Push Notification Preferences Screen
**What it is:** A settings page where users can choose which notifications they
receive and which they mute: new messages, price drops on saved items, new items
from a followed seller, weekly digest of new arrivals.

**Why it matters:** Push notifications exist in the app (just added), but there
is no way for users to turn them on or off by type. Sending too many notifications
causes users to uninstall. Too few means they forget the app. Giving control is
a retention best practice.

**Skills behind this:** `firebase` (FCM preferences), `user-management patterns`

**Business impact:** Reduces uninstall rate. Increases re-engagement.

**Effort estimate:** Low (3–5 days)

---

### 5. In-App Offers / Counter-Offers (Negotiation Chat)
**What it is:** A structured "Make an Offer" button on each listing that sends
a formal offer message to the seller with a specific price, which the seller
can accept, counter, or decline — all inside the chat.

**Why it matters:** Ethiopian secondhand culture includes price negotiation as
a natural expectation. The current app forces all negotiation over phone (after
revealing contact). A structured offer flow keeps negotiation in the app,
creates a paper trail, and feels more professional than WhatsApp-style haggling.

**Skills behind this:** `api-design-principles`, `chat systems`

**Business impact:** Increases in-app engagement. Reduces drop-off between
"contact reveal" and completed sale. Potential data on accepted offer rates.

**Effort estimate:** Medium (2–3 weeks)

---

## 🟡 Tier 2 — High Value, Larger Investment (Next Quarter)

These features meaningfully differentiate Wavy from generic marketplaces. They
require more development time but have strong business cases.

---

### 6. AI-Powered Style Recommendations
**What it is:** As a user swipes through items, the app learns their style
preferences (colors, brands, price range, silhouettes) and gives them a personalized
daily feed digest — "Based on what you've saved, you'll love these 5 items."

**Why it matters:** The swipe mechanic already generates rich preference data.
That data is currently unused for personalization. Adding a simple recommendation
engine turns Wavy into a personal stylist, not just a search engine with cards.

**Skills behind this:** `ai-product`, `recommendation systems`, `embedding-strategies`,
`rag-implementation`

**Business impact:** Drastically increases daily active use. "Curated for you"
is the core value proposition for fashion platforms like Depop and Vinted globally.

**Effort estimate:** High (4–8 weeks for a meaningful implementation)

---

### 7. Seller Verification Program (Badge System)
**What it is:** A formal "Verified Seller" tier that sellers earn by:
- Completing a Wavy onboarding checklist
- Getting 10+ positive reviews
- Completing 5+ sales
- Submitting a national ID for identity verification

Verified sellers get a checkmark badge and appear higher in search results.

**Why it matters:** Trust is everything. In a market where cash transactions
between strangers are the norm, a trusted badge significantly increases
buyer confidence. It also gives sellers a compelling reason to follow platform
guidelines and deliver good service.

**Skills behind this:** `auth-implementation-patterns`, `backend-development-feature-development`

**Business impact:** Creates a premium seller tier. Enables future "Pro Seller" subscription.
Differentiates Wavy quality from a casual classifieds app.

**Effort estimate:** Medium–High (3–5 weeks)

---

### 8. CSV / Analytics Dashboard for Sellers
**What it is:** A private dashboard where sellers can see:
- How many times each listing was viewed
- How many times their profile was visited
- How many people saved their items vs. passed
- Which items get the most engagement
- Their average response time to messages

**Why it matters:** Professional sellers — small boutiques, curators, resellers —
will use Wavy more if it gives them data. Data makes them better sellers. Better
sellers attract more buyers. This is standard on all mature marketplace platforms
(Depop, Vinted, Poshmark all have seller analytics).

**Skills behind this:** `kpi-dashboard-design`, `data-storytelling`, `analytics-tracking`

**Business impact:** Increases time-on-platform for power sellers.
Enables "power seller" upgrade tier. Creates upsell opportunity.

**Effort estimate:** Medium (2–4 weeks)

---

### 9. Collections / Curated Lists by Sellers
**What it is:** Sellers (or Wavy's internal team) can group items into themed
collections: "90s streetwear," "Work outfits under 800 ETB," "Festival fits."
Users follow collections and get notified when new items are added.

**Why it matters:** Curation is editorial value. It differentiates Wavy from a
plain grid marketplace and moves it toward a content-meet-commerce platform.
High-engagement influencer sellers can build a following. Wavy's own team can
create editorial collections like a fashion magazine.

**Skills behind this:** `content-creator`, `api-design-principles`

**Business impact:** Increases session depth and repeat visits.
Content collections are shareable on social media — organic growth engine.

**Effort estimate:** Medium (2–3 weeks)

---

### 10. "Price Drop" Alerts on Saved Items
**What it is:** When a seller lowers the price on a listing, every user who
has saved that item receives a push notification: "Price dropped! The vest
you saved is now 350 ETB (was 500 ETB)."

**Why it matters:** This converts passive wishlist behavior into active purchasing.
It is proven to dramatically increase conversion on e-commerce platforms.
Users save items because they're interested but not ready. A price trigger
removes the hesitation.

**Skills behind this:** `firebase` (Firestore triggers), `messaging systems`

**Business impact:** Directly increases completed sales. Creates urgency.
Drives re-engagement with the app.

**Effort estimate:** Low–Medium (1–2 weeks)

---

## 🟢 Tier 3 — Growth & Differentiation (6-Month Horizon)

These features are for when Wavy has traction and is ready to scale.

---

### 11. Refer-a-Friend Program
**What it is:** Every user gets a unique referral link. When a new user signs
up using your link and completes their first purchase, the referrer gets a
credit (e.g., 50 ETB off their next purchase or a featured listing).

**Why it matters:** Wavy's best marketing is word-of-mouth. Addis Ababa is
a city where most clothing discovery happens through friends and community.
A referral mechanic turns existing users into a free sales force.

**Skills behind this:** `referral-program`, `billing-automation`

**Business impact:** Lowest cost user acquisition channel. Self-funding growth
if reward < customer lifetime value.

**Effort estimate:** Medium (2–3 weeks)

---

### 12. Wavy Stories / Reels — Short Video Listings
**What it is:** Sellers can upload a 15–30 second video of the item on a hanger
or being worn. Videos autoplay in a TikTok/Reels-style vertical scroll.

**Why it matters:** Static photos of clothes on a hanger do not sell. Video shows
fabric movement, texture, and true color. Depop introduced video and saw a
significant increase in conversion. Gen-Z in Addis Ababa are heavy Reels/TikTok
consumers. Meeting them in their native format is a strong acquisition play.

**Skills behind this:** `video-processing`, `firebase` (Storage for video), `mobile-design`

**Business impact:** Dramatically increases engagement time per session.
Video listings stand out in feed. Creates a new content format that drives shares.

**Effort estimate:** High (4–6 weeks)

---

### 13. AI "Virtual Try-On" Preview
**What it is:** A user can tap a listing and see what the item would look like
"on them" using a simple AI body overlay. Using the front camera and generative
AI, the app renders the shirt/dress/jacket onto the user's silhouette.

**Why it matters:** The number-one reason people hesitate to buy secondhand online
is "I can't tell if it will fit / look right on me." Virtual try-on directly
removes this objection. Wavy would be the first fashion platform in Addis Ababa
with this capability — a clear differentiator and a press story.

**Skills behind this:** `computer-vision-expert`, `fal-generate`, `fal-image-edit`

**Business impact:** Extreme differentiation. Press-worthy. Increases first-purchase
conversion significantly. Long-term, this is a moat.

**Effort estimate:** Very High (8–12 weeks) — but available via third-party APIs
like fal.ai or Replicate, which could reduce this to 3–5 weeks.

---

### 14. Bundled Listings ("Complete the Look")
**What it is:** A seller can group 2–5 items into a bundle offer: "Buy all 3 for
1,200 ETB instead of 1,800 ETB." The buyer gets a discount; the seller moves
more inventory in one transaction.

**Why it matters:** Secondhand sellers often accumulate many similar items.
Bundling incentivizes higher-value transactions. It also creates a "complete
the look" editorial angle: sellers curate outfits and buyers buy the whole look.

**Skills behind this:** `api-design-principles`, `stripe-integration` (bundled checkout)

**Business impact:** Increases average order value. Reduces inventory backlog
for power sellers. Creates new content format.

**Effort estimate:** Medium (2–3 weeks)

---

### 15. Wavy for Teams / Boutiques (Business Accounts)
**What it is:** A "Boutique" account type for small vintage stores, student
thrift shops, or boutique curators. Business accounts get:
- Multiple team members managing one seller profile
- Bulk listing upload tools (CSV import)
- Promoted listings (paid feature)
- Monthly sales report exports

**Why it matters:** Some of the most reliable inventory sources in Addis Ababa are
small boutiques and curated vintage shops. Giving them professional tools turns them
into high-output sellers rather than casual users. This is the foundation of any
marketplace's "power seller" business model.

**Skills behind this:** `billing-automation`, `api-design-principles`,
`kpi-dashboard-design`, `startup-metrics-framework`

**Business impact:** Monetization foundation. Premium subscription tier.
Reliable, high-volume inventory. Institutional partnerships.

**Effort estimate:** Very High (8–12 weeks for full implementation)

---

## Summary Matrix

| # | Feature | Tier | Business Value | Effort |
|---|---------|------|---------------|--------|
| 1 | In-app payments | 🔴 Now | 🔥 Revenue model | Medium |
| 2 | Smart search | 🔴 Now | 🔥 Core UX gap | Low–Med |
| 3 | Seller ratings | 🔴 Now | 🔥 Trust engine | Medium |
| 4 | Notification preferences | 🔴 Now | Retention | Low |
| 5 | In-app offers / negotiation | 🔴 Now | Engagement | Medium |
| 6 | AI style recommendations | 🟡 Q2 | Differentiation | High |
| 7 | Seller verification badge | 🟡 Q2 | Trust + premium | Med–High |
| 8 | Seller analytics dashboard | 🟡 Q2 | Power user retention | Medium |
| 9 | Collections by sellers | 🟡 Q2 | Content + discovery | Medium |
| 10 | Price drop alerts | 🟡 Q2 | Conversion | Low–Med |
| 11 | Refer-a-friend program | 🟢 6mo | Growth flywheel | Medium |
| 12 | Short video listings | 🟢 6mo | Engagement + Gen-Z | High |
| 13 | AI virtual try-on | 🟢 6mo | Extreme differentiation | High |
| 14 | Bundle listings | 🟢 6mo | AOV increase | Medium |
| 15 | Boutique business accounts | 🟢 6mo | Monetization | Very High |

---

*Author: Antigravity AI · Date: March 6, 2026*
*Features derived by cross-referencing Wavy's current app state with the 500+ skill library*
*covering payments, AI/ML, search, analytics, communication, and marketplace patterns.*
