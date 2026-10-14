# MotoLog backend structure

This directory holds the Firestore/Storage configuration for MotoLog —
usernames, public/private profiles, friend requests, and each rider's
garage data. These files aren't part of the Xcode build; they configure the
Firebase project itself, and the same project backs both the iOS app and the
marketing website's login/dashboard.

## Schema

- `usernames/{usernameLowercased}` → `{ uid }` — reserves a unique handle. Permanent in v1 (no rename yet).
- `users/{uid}` → `{ username, displayName, photoURL, isPublic, totalMiles, bikeCount, createdAt }` — the public-safe profile document.
- `users/{uid}/private/profile` → `{ email }` — sensitive fields, readable only by the owner. Kept separate because Firestore security rules can't redact individual fields within one document.
- `users/{uid}/friends/{friendUid}` → `{ since }` — written on **both** users' subcollections when a request is accepted.
- `friendRequests/{minUid}_{maxUid}` → `{ fromUid, toUid, status, createdAt }` — doc ID is deterministic (lower uid first) so a pair can only ever have one request between them at a time.
- `users/{uid}/motorcycles/{id}` → `{ make, model, year, nickname, currentMileage, dateAdded, finalDriveType, photoURL, photoAttribution, updatedAt }` — owner-only, synced from the app's local SwiftData by `GarageSyncService`. `id` is the model's own UUID.
- `users/{uid}/maintenanceItems/{id}` → `{ motorcycleId, type, customName, intervalMiles, intervalMonths, lastServiceMileage, lastServiceDate, updatedAt }` — owner-only. References its bike via `motorcycleId` rather than nesting, so it can be queried/synced independently.
- `users/{uid}/trips/{id}` → `{ motorcycleId, date, distanceMiles, durationMinutes, notes, startTemperatureF, endTemperatureF, routeURL, updatedAt }` — owner-only.
- Storage `motorcycle_photos/{uid}/{motorcycleId}` and `trip_routes/{uid}/{tripId}` — the actual photo/route bytes. Firestore documents cap at 1 MB, so only the Storage download URL rides along on the doc above.
- `posts/{id}` → `{ authorUid, authorDisplayName, authorUsername, authorPhotoURL, tripId, motorcycleName, distanceMiles, durationMinutes, averageSpeedMph, routeURL, imageURLs, caption, isPublic, likeCount, commentCount, createdAt }` — a rider opting to share a GPS-tracked trip to the feed. `routeURL` is copied from the `Trip` being shared, not re-uploaded. Visibility is per-post: Public (any signed-in rider) or Friends-only, chosen at share time.
- `posts/{id}/likes/{uid}` → `{ createdAt }` — presence = liked.
- `posts/{id}/comments/{id}` → `{ authorUid, authorDisplayName, authorPhotoURL, text, createdAt }`.
- Storage `post_images/{uid}/{postId}/{imageId}` — optional photos attached to a post.

## Privacy model

- `isPublic: true` → anyone signed in can view the profile and it appears in the public leaderboard query.
- `isPublic: false` (default) → visible only to the owner and accepted friends.
- Friending requires a request/accept handshake — there is no instant add-by-email. This is the key difference from the v1 friends sketch.
- Garage data (`motorcycles`/`maintenanceItems`/`trips`) is never shared with other riders, public or not — owner-only, full stop. The website dashboard reads it by signing in as that same owner.
- Feed posts follow the same Public/friends-only split as profiles, but it's a per-post choice, not tied to the rider's own profile visibility setting.

## Deploying

Once you've created the Firebase project (see the setup steps in chat) and installed the Firebase CLI (`npm install -g firebase-tools`):

```bash
firebase login
firebase use --add          # pick your MotoLog project
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Or paste `firestore.rules` / `storage.rules` directly into Firebase Console → Firestore Database → Rules / Storage → Rules, and manually create the composite index described in `firestore.indexes.json` under the Firestore Indexes tab (Firestore will also offer to create it automatically the first time the leaderboard query runs and fails for lack of an index — just click the link in the error).
