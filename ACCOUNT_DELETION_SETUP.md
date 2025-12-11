# Account Deletion Setup Guide

## Overview
Account deletion is now implemented in the app. When a user deletes their account, all associated data is permanently removed from Firebase. This guide explains what happens and what you need to verify in Firebase.

## What Gets Deleted

When a user deletes their account, the following data is permanently removed:

### 1. User Data
- ✅ User document: `users/{userId}`
- ✅ User subcollections:
  - `users/{userId}/likedItineraries/{itineraryId}`
  - `users/{userId}/savedItineraries/{itineraryId}`
  - `users/{userId}/completedItineraries/{itineraryId}`

### 2. Content Created by User
- ✅ All itineraries created by the user: `itineraries/{itineraryId}` (where `authorID == userId`)
- ✅ All comments made by the user: `itineraries/{itineraryId}/comments/{commentId}` (where `authorID == userId`)
- ✅ All votes on comments: `itineraries/{itineraryId}/comments/{commentId}/votes/{userId}`

### 3. User Interactions
- ✅ All likes given by the user: `itineraries/{itineraryId}/likes/{userId}`
- ✅ All votes on comments: `itineraries/{itineraryId}/comments/{commentId}/votes/{userId}`

### 4. Account Data
- ✅ Handle reservation: `handles/{handle}` (where `uid == userId`)
- ✅ Profile picture: Firebase Storage `profile_pictures/{userId}`
- ✅ Firebase Authentication account

## Firebase Console Setup

### ✅ Firestore Security Rules

**No changes needed!** The current Firestore rules already allow users to delete their own data:

```javascript
// Current rules (from COMPLETE_FIRESTORE_RULES_WITH_VOTES.txt)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can delete their own user document
    match /users/{userId} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can delete their own handle
    match /handles/{handle} {
      allow delete: if request.auth != null && resource.data.uid == request.auth.uid;
    }
    
    // Users can delete their own itineraries
    match /itineraries/{itineraryId} {
      allow delete: if request.auth != null && resource.data.authorID == request.auth.uid;
    }
    
    // Users can delete their own comments
    match /comments/{commentId} {
      allow delete: if request.auth != null && resource.data.authorID == request.auth.uid;
    }
    
    // Users can delete their own votes
    match /votes/{userId} {
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Action Required:** Verify these rules are published in your Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **triptuner-1fd5f**
3. Go to **Firestore Database** → **Rules** tab
4. Verify the rules match `COMPLETE_FIRESTORE_RULES_WITH_VOTES.txt`
5. Click **"Publish"** if you made any changes

### ✅ Firebase Storage Security Rules

**No changes needed!** The current Storage rules already allow users to delete their own profile pictures:

```javascript
// Current rules (from CORRECTED_STORAGE_RULES.txt)
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_pictures/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      // Note: 'write' includes create, update, and delete
    }
  }
}
```

**Action Required:** Verify these rules are published:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **triptuner-1fd5f**
3. Go to **Storage** → **Rules** tab
4. Verify the rules match `CORRECTED_STORAGE_RULES.txt`
5. Click **"Publish"** if you made any changes

### ✅ Firebase Authentication

**No setup needed!** Firebase Auth automatically allows users to delete their own accounts when authenticated.

## How It Works

### User Flow

1. User taps **"Delete Account"** button on Profile page (above "Sign Out")
2. Confirmation dialog appears: *"Are you sure you want to delete your account? This action cannot be undone. All your data, including itineraries, comments, and likes, will be permanently deleted."*
3. If user confirms:
   - All user data is deleted from Firestore
   - All user content is deleted
   - Profile picture is deleted from Storage
   - Handle reservation is deleted
   - Firebase Auth account is deleted
   - User is automatically logged out
   - App state is cleared

### Technical Implementation

The deletion process happens in this order:

1. **Delete user subcollections** (likedItineraries, savedItineraries, completedItineraries)
2. **Delete all itineraries created by user** (including their comments and votes subcollections)
3. **Delete all comments made by user** (from any itinerary, including their votes subcollections)
4. **Delete all votes made by user on comments** (from any itinerary)
5. **Delete all likes given by user on itineraries**
6. **Delete user document**
7. **Delete handle reservation**
8. **Delete profile picture from Storage**
9. **Delete Firebase Auth account**
10. **Logout and clear app state**

## Testing

### Test Account Deletion

1. **Create a test account:**
   - Sign up with a test email
   - Create an itinerary
   - Add a comment to an itinerary
   - Like an itinerary
   - Save an itinerary
   - Complete an itinerary
   - Upload a profile picture

2. **Delete the account:**
   - Go to Profile page
   - Tap "Delete Account"
   - Confirm deletion

3. **Verify deletion in Firebase Console:**
   - **Firestore:**
     - Check `users/{userId}` - should not exist
     - Check `handles/{handle}` - should not exist
     - Check `itineraries/` - user's itineraries should not exist
     - Check `itineraries/{itineraryId}/comments/` - user's comments should not exist
     - Check `itineraries/{itineraryId}/likes/{userId}` - should not exist
     - Check `itineraries/{itineraryId}/comments/{commentId}/votes/{userId}` - should not exist
   - **Storage:**
     - Check `profile_pictures/{userId}` - should not exist
   - **Authentication:**
     - Check Users list - user should not exist

## Important Notes

### ⚠️ Cascading Deletions

When a user deletes their account:
- **Itineraries they created** are completely deleted (including all comments, votes, and likes on those itineraries)
- **Comments they made** are deleted (but the itinerary remains)
- **Likes they gave** are removed (but the itinerary remains)
- **Votes on comments** are removed (but the comment remains, with updated score)

### ⚠️ Data Integrity

- Comment scores will automatically update when votes are deleted
- Like counts will automatically update when likes are deleted
- Other users' data is not affected

### ⚠️ Performance

Account deletion involves multiple Firestore operations. For users with many itineraries/comments, this may take a few seconds. The app shows a loading state during deletion.

## Troubleshooting

### Error: "Permission denied" when deleting

**Possible causes:**
1. Firestore rules not published correctly
2. Storage rules not published correctly
3. User not authenticated

**Solution:**
- Verify all security rules are published in Firebase Console
- Check that user is logged in
- Check Xcode console for specific error messages

### Some data not deleted

**Possible causes:**
1. Network interruption during deletion
2. Firestore rules preventing deletion
3. Storage rules preventing deletion

**Solution:**
- Check Firebase Console to see what data remains
- Verify security rules allow deletion
- Re-run deletion (if account still exists)

### Account deleted but user still logged in

**This should not happen** - the app automatically logs out after successful deletion. If it does:
- Check Xcode console for errors
- Verify Firebase Auth account was deleted
- Manually sign out if needed

## Security Considerations

✅ **Users can only delete their own data** - Security rules ensure users cannot delete other users' data

✅ **All deletions are authenticated** - All operations require the user to be logged in

✅ **Handle reservations are cleaned up** - Handles are freed when accounts are deleted

✅ **No orphaned data** - All associated data is properly cleaned up

## No Cloud Functions Required

**Good news:** Account deletion works entirely from the client side. You do **NOT** need to set up Cloud Functions. All deletions are handled directly by the app using Firestore batch operations and the Firebase SDK.

## Summary

✅ **Firestore Rules:** Already configured correctly - no changes needed  
✅ **Storage Rules:** Already configured correctly - no changes needed  
✅ **Auth:** No setup needed  
✅ **Cloud Functions:** Not required  

**Action Required:** Just verify that your current rules are published in Firebase Console!

