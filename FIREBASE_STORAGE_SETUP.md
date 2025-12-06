# Firebase Storage Setup Guide for Photos

## Overview
The app now uploads photos to Firebase Storage and saves the download URLs to Firestore. You need to set up Firebase Storage in your Firebase Console.

## Firebase Console Setup

### Step 1: Enable Firebase Storage

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **triptuner-1fd5f**
3. Click **"Storage"** in the left sidebar (under "Build")
4. If not already enabled, click **"Get started"**
5. Choose **"Start in production mode"** (we'll add security rules next)
6. Select a location (choose the same as your Firestore, e.g., `us-east1`)

### Step 2: Set Up Storage Security Rules

1. In Storage, click on the **"Rules"** tab
2. Replace the default rules with the following:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures - users can only upload/read their own
    // The filename is {userId}.jpg, so we match the userId part
    match /profile_pictures/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Itinerary photos - users can upload to their own folder, anyone can read
    match /itineraries/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click **"Publish"** to save the rules

### Step 3: Verify Storage API is Enabled

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **triptuner-1fd5f**
3. Go to **APIs & Services** → **Enabled APIs**
4. Make sure **"Cloud Storage API"** is enabled
5. If not, search for it and click **"Enable"**

## How It Works

### Profile Pictures
- **Path**: `profile_pictures/{userId}.jpg`
- **Upload**: When user selects a profile picture in ProfileView
- **Storage**: URL saved to `users/{userId}/profileImageURL` in Firestore
- **Display**: Loaded from URL throughout the app

### Itinerary Photos
- **Path**: `itineraries/{userId}/{itineraryId}/{photoId}.jpg`
- **Upload**: When user creates an itinerary with photos
- **Storage**: URLs saved to `itineraries/{itineraryId}/photos` array in Firestore
- **Display**: Shown in itinerary detail view and photo gallery

## Testing

1. **Test Profile Picture Upload**:
   - Go to Profile page
   - Tap the profile picture
   - Select a photo
   - Check Firebase Console → Storage → `profile_pictures/` folder
   - Check Firestore → `users/{userId}` → `profileImageURL` field

2. **Test Itinerary Photos**:
   - Create a new itinerary
   - Add 2 photos
   - Submit the itinerary
   - Check Firebase Console → Storage → `itineraries/{userId}/{itineraryId}/` folder
   - Check Firestore → `itineraries/{itineraryId}` → `photos` array

## Troubleshooting

### Error: "Permission denied"
- Check Storage security rules are published
- Verify user is authenticated
- Make sure rules allow the user to write to their own folder

### Photos not appearing
- Check Storage Console to see if files were uploaded
- Check Firestore to see if URLs are saved in the `photos` array
- Verify URLs are valid (check in browser)
- Check Xcode console for upload errors

### Profile picture not showing
- Check `users/{userId}/profileImageURL` in Firestore
- Verify the URL is valid
- Check if image was uploaded to Storage

## Storage Structure

```
gs://triptuner-1fd5f.appspot.com/
├── profile_pictures/
│   ├── {userId1}.jpg
│   ├── {userId2}.jpg
│   └── ...
└── itineraries/
    ├── {userId1}/
    │   ├── {itineraryId1}/
    │   │   ├── {photoId1}.jpg
    │   │   └── {photoId2}.jpg
    │   └── {itineraryId2}/
    │       └── ...
    └── {userId2}/
        └── ...
```

## Cost Considerations

- Firebase Storage has a free tier (5 GB storage, 1 GB/day downloads)
- Photos are compressed to 80% quality (JPEG) to save space
- Each photo is typically 100-500 KB after compression

