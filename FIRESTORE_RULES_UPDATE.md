# Firestore Security Rules Update for User-Specific Features

## Overview
The app now uses Firestore to store user-specific data (likes, saved itineraries, completed itineraries, and comments). You need to update your Firestore security rules to allow these operations.

## Updated Security Rules

Add these rules to your existing Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // USERS COLLECTION (your existing rules)
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // User's liked itineraries subcollection
      match /likedItineraries/{itineraryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User's saved itineraries subcollection
      match /savedItineraries/{itineraryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // User's completed itineraries subcollection
      match /completedItineraries/{itineraryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // HANDLES COLLECTION (your existing rules)
    match /handles/{handle} {
      allow read: if request.auth != null;
      allow create: if request.auth != null 
        && !exists(/databases/$(database)/documents/handles/$(handle));
      allow update: if request.auth != null 
        && request.resource.data.uid == request.auth.uid;
      allow delete: if request.auth != null 
        && resource.data.uid == request.auth.uid;
    }

    // ITINERARIES COLLECTION
    match /itineraries/{itineraryId} {
      // Anyone authenticated can read all itineraries (for map display)
      allow read: if request.auth != null;
      
      // Anyone authenticated can create itineraries
      // BUT they can only set authorID to their own UID
      allow create: if request.auth != null 
        && request.resource.data.authorID == request.auth.uid;
      
      // Only the author can update their own itinerary
      allow update: if request.auth != null 
        && resource.data.authorID == request.auth.uid
        && request.resource.data.authorID == request.auth.uid;
      
      // Only the author can delete their own itinerary
      allow delete: if request.auth != null 
        && resource.data.authorID == request.auth.uid;
      
      // Likes subcollection - anyone can read, authenticated users can write
      match /likes/{likeId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
      
      // Comments subcollection
      match /comments/{commentId} {
        // Anyone authenticated can read comments
        allow read: if request.auth != null;
        
        // Anyone authenticated can create comments
        allow create: if request.auth != null 
          && request.resource.data.authorID == request.auth.uid;
        
        // Only the author can update/delete their own comment
        allow update, delete: if request.auth != null 
          && resource.data.authorID == request.auth.uid;
      }
    }
  }
}
```

## What Changed

### New Subcollections:

1. **`users/{userId}/likedItineraries/{itineraryId}`**
   - Stores which itineraries each user has liked
   - Users can only read/write their own likes

2. **`users/{userId}/savedItineraries/{itineraryId}`**
   - Stores which itineraries each user has saved
   - Users can only read/write their own saved items

3. **`users/{userId}/completedItineraries/{itineraryId}`**
   - Stores which itineraries each user has completed
   - Users can only read/write their own completed items

4. **`itineraries/{itineraryId}/likes/{userId}`**
   - Stores all likes for an itinerary (for counting)
   - Anyone authenticated can read/write

5. **`itineraries/{itineraryId}/comments/{commentId}`**
   - Stores comments and replies for each itinerary
   - Anyone can read, only comment author can update/delete

## How to Update

1. Go to Firebase Console → Firestore Database → Rules
2. Replace your existing rules with the complete rules above
3. Click "Publish"
4. Wait a few seconds for rules to propagate

## Testing

After updating the rules, test:
- ✅ User 1 likes an itinerary → User 2 should not see it as liked
- ✅ User 1 saves an itinerary → User 2 should not see it in their saved list
- ✅ User 1 completes an itinerary → User 2 should not see it in their completed list
- ✅ User 1 comments on an itinerary → User 2 can see the comment
- ✅ User 1 can only delete their own comments

