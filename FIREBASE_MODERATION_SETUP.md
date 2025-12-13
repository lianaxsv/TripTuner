# Firebase Setup for Content Moderation Features

## Overview
This guide explains the Firebase changes needed to support the new flagging and blocking features that comply with App Review Guideline 1.2.

## Required Changes

### 1. Update Firestore Security Rules

You need to add rules for three new collections:

1. **`users/{userId}/blockedUsers/{blockedUserId}`** - Stores blocked users per user
2. **`flags`** - Stores flagged content for review
3. **`developerNotifications`** - Stores notifications for developers

#### Steps to Update Rules:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Replace your existing rules with the rules from `FIRESTORE_RULES_WITH_MODERATION.txt`
5. Click **"Publish"** to save

### 2. New Firestore Collections

The following collections will be automatically created when users start using the moderation features:

#### `users/{userId}/blockedUsers/{blockedUserId}`
- **Structure**: Subcollection under each user document
- **Purpose**: Stores which users each person has blocked
- **Document Fields**:
  - `blockedUserID` (string)
  - `blockedUserName` (string)
  - `blockedUserHandle` (string)
  - `blockedAt` (timestamp)

#### `flags`
- **Structure**: Top-level collection
- **Purpose**: Stores all flagged content for developer review
- **Document Fields**:
  - `contentType` (string): "itinerary" or "comment"
  - `contentID` (string): ID of the flagged content
  - `itineraryID` (string): If flagging a comment, the parent itinerary ID
  - `contentTitle` (string): Title of itinerary (if applicable)
  - `contentPreview` (string): Preview of comment (if applicable)
  - `authorID` (string): ID of content author
  - `authorName` (string): Name of content author
  - `authorHandle` (string): Handle of content author
  - `flaggedBy` (string): ID of user who flagged
  - `reason` (string): Reason for flagging
  - `additionalInfo` (string, optional): Additional details
  - `flaggedAt` (timestamp)
  - `status` (string): "pending", "reviewed", "resolved", etc.

#### `developerNotifications`
- **Structure**: Top-level collection
- **Purpose**: Notifies developers when users are blocked
- **Document Fields**:
  - `type` (string): "user_blocked"
  - `blockedBy` (string): ID of user who blocked
  - `blockerName` (string): Name of user who blocked
  - `blockerHandle` (string): Handle of user who blocked
  - `blockedUserID` (string): ID of blocked user
  - `blockedUserName` (string): Name of blocked user
  - `blockedUserHandle` (string): Handle of blocked user
  - `createdAt` (timestamp)
  - `reviewed` (boolean): Whether developer has reviewed

### 3. Security Rules Explanation

#### Blocked Users (`users/{userId}/blockedUsers/{blockedUserId}`)
- Users can only read/write their own blocked users list
- This ensures privacy - users can't see who blocked them

#### Flags Collection
- Any authenticated user can create a flag
- Users can read flags they created (for their own reference)
- **Production Recommendation**: Restrict read access to admins only for better security

#### Developer Notifications
- Any authenticated user can create notifications (when blocking)
- Currently, any authenticated user can read (for testing)
- **Production Recommendation**: Restrict read access to admins only

### 4. Admin Access (Optional - For Production)

For production, you may want to restrict access to flags and notifications to admins only. You can do this by:

1. Adding an `isAdmin` field to user documents
2. Creating a helper function in Firestore rules:

```javascript
function isAdmin() {
  return request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

3. Updating the rules:
```javascript
// Flags - only admins can read all
allow read: if request.auth != null && (
  resource.data.flaggedBy == request.auth.uid || 
  isAdmin()
);

// Developer notifications - only admins can read
allow read: if isAdmin();
```

### 5. Monitoring and Review

#### Viewing Flags in Firebase Console:
1. Go to Firestore Database
2. Open the `flags` collection
3. Review flagged content
4. Update the `status` field as you review items

#### Viewing Block Notifications:
1. Go to Firestore Database
2. Open the `developerNotifications` collection
3. Review user blocks
4. Mark `reviewed` as true when processed

### 6. No Indexes Required

The current implementation doesn't require any composite indexes. All queries use simple document reads or single-field queries that Firestore supports by default.

## Testing

After updating the rules:

1. **Test Blocking**: Block a user and verify the document appears in `users/{yourUserId}/blockedUsers/{blockedUserId}`
2. **Test Flagging**: Flag an itinerary or comment and verify it appears in the `flags` collection
3. **Test Filtering**: Verify that blocked users' content no longer appears in your feed
4. **Test Notifications**: Verify that blocking a user creates a notification in `developerNotifications`

## Important Notes

- The collections are created automatically when users use the features - no manual setup needed
- Rules are enforced immediately after publishing
- Make sure to test in a development environment first
- Consider implementing admin authentication before production deployment

