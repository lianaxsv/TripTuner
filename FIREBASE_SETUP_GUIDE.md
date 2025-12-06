# Firebase Setup Guide for TripTuner

## Overview
This guide will help you set up Firebase Firestore to store and retrieve itineraries. The app now saves all itineraries to Firestore and associates them with the user who created them.

## What Changed

### Data Flow
1. **Creating Itineraries**: When a user creates an itinerary, it's saved to Firestore with their `authorID` (Firebase Auth UID)
2. **Loading Itineraries**: The app loads ALL itineraries from Firestore and displays them on the map
3. **My Created Itineraries**: Only shows itineraries where `authorID` matches the current user's ID

### User ID vs Email
**We use User ID (Firebase Auth UID)** because:
- ✅ It's unique and permanent
- ✅ It's already available after authentication
- ✅ It doesn't change if user updates their email
- ✅ More secure (doesn't expose email addresses)

## Firebase Console Setup

### Step 1: Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **triptuner-1fd5f**
3. Click **"Firestore Database"** in the left sidebar
4. If not already enabled, click **"Create database"**
5. Choose **"Start in production mode"** (we'll add security rules next)
6. Select a location (choose closest to your users, e.g., `us-east1`)

### Step 2: Set Up Firestore Security Rules

1. In Firestore Database, click on the **"Rules"** tab
2. Replace the default rules with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Handles collection (for unique handle checking)
    match /handles/{handleId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Itineraries collection
    match /itineraries/{itineraryId} {
      // Anyone authenticated can read all itineraries (for map display)
      allow read: if isAuthenticated();
      
      // Anyone authenticated can create itineraries
      allow create: if isAuthenticated() 
        && request.resource.data.authorID == request.auth.uid;
      
      // Only the author can update their own itinerary
      allow update: if isAuthenticated() 
        && resource.data.authorID == request.auth.uid
        && request.resource.data.authorID == request.auth.uid;
      
      // Only the author can delete their own itinerary
      allow delete: if isAuthenticated() 
        && resource.data.authorID == request.auth.uid;
    }
  }
}
```

3. Click **"Publish"** to save the rules

### Step 3: Create Indexes (if needed)

The app queries itineraries ordered by `createdAt`. Firestore may prompt you to create an index. If you see an error link in the console:

1. Click the error link (it will open in a new tab)
2. Click **"Create Index"**
3. Wait for the index to build (usually takes a few minutes)

**Index Details:**
- Collection: `itineraries`
- Fields: `createdAt` (Descending)
- Query scope: Collection

### Step 4: Verify Firestore API is Enabled

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **triptuner-1fd5f**
3. Go to **APIs & Services** → **Enabled APIs**
4. Make sure **"Cloud Firestore API"** is enabled
5. If not, search for it and click **"Enable"**

## Data Structure

### Itineraries Collection

Each document in the `itineraries` collection has this structure:

```javascript
{
  "id": "uuid-string",
  "title": "Coffee Tour of Center City",
  "description": "A great coffee crawl...",
  "category": "cafes",  // "restaurants", "cafes", or "attractions"
  "authorID": "firebase-auth-uid",  // Links to user who created it
  "authorName": "John Doe",
  "authorHandle": "@johndoe",
  "authorProfileImageURL": null,  // or URL string
  "stops": [
    {
      "id": "stop-uuid",
      "locationName": "La Colombe",
      "address": "130 S 19th St, Philadelphia, PA 19103",
      "addressComponents": {
        "street": "130 S 19th St",
        "city": "Philadelphia",
        "state": "PA",
        "zipCode": "19103"
      },
      "latitude": 39.9500,
      "longitude": -75.1700,
      "notes": "Great coffee",
      "order": 1
    }
  ],
  "photos": [],  // Array of photo URLs
  "likes": 0,
  "comments": 0,
  "timeEstimate": 2,  // in hours
  "cost": 15.0,  // or null
  "costLevel": "$",  // "Free", "$", "$$", or "$$$"
  "noiseLevel": 2,  // 1=quiet, 2=moderate, 3=loud, 4=veryLoud
  "region": "centerCity",  // Philadelphia region
  "createdAt": Timestamp  // Firestore timestamp
}
```

### Users Collection

Each document in the `users` collection has this structure:

```javascript
{
  "name": "John Doe",
  "handle": "@johndoe",
  "email": "john@example.com",
  "profileImageURL": null,
  "year": null,
  "streak": 0,
  "points": 0,
  "createdAt": Timestamp
}
```

## Testing

1. **Create an Itinerary**:
   - Sign in to the app
   - Go to "Add Post" tab
   - Create a new itinerary
   - Check Firebase Console → Firestore → `itineraries` collection
   - Verify the document was created with your `authorID`

2. **View on Map**:
   - Go to "Home" tab
   - The map should show ALL itineraries from all users
   - Your new itinerary should appear

3. **View My Created Itineraries**:
   - Go to "Add Post" tab
   - You should only see itineraries you created
   - Other users' itineraries won't appear here

## Troubleshooting

### Error: "Missing or insufficient permissions"
- Check that Firestore security rules are published
- Verify the user is authenticated (check `AuthViewModel.isAuthenticated`)
- Make sure `authorID` matches `request.auth.uid` when creating

### Error: "The query requires an index"
- Click the error link in the console
- Create the index as prompted
- Wait for index to build (can take a few minutes)

### Itineraries not appearing
- Check Firestore Console to see if documents exist
- Verify the app is connected to the correct Firebase project
- Check Xcode console for error messages
- Make sure Firestore API is enabled

### Map shows no pins
- Verify itineraries have valid `latitude` and `longitude` values
- Check that `stops` array is not empty
- Ensure coordinates are valid numbers (not NaN)

## Next Steps

After this is working, you can integrate:
- **Comments**: Save comments to Firestore subcollection
- **Likes**: Update like counts in Firestore
- **Saved Itineraries**: Store saved itinerary IDs per user
- **Completed Itineraries**: Track completed trips per user

## Security Notes

- ✅ Users can only create itineraries with their own `authorID`
- ✅ Users can only update/delete their own itineraries
- ✅ All users can read all itineraries (for map display)
- ✅ User documents are protected (users can only modify their own)
- ✅ Handles collection allows authenticated writes (for handle reservation)

