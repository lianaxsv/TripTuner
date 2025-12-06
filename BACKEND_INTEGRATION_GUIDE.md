# Backend Integration Guide for TripTuner

## Data Flow Overview

When a user creates an itinerary, here's exactly where the data goes:

### 1. **User Input** → `AddItineraryView.swift`
   - **Location**: `TripTuner/Views/AddItinerary/AddItineraryView.swift`
   - User fills out the form (title, description, category, region, cost, noise level, stops, etc.)
   - Form data is stored in `@State` variables and `@AppStorage` for draft persistence

### 2. **Submission** → `submitItinerary()` function
   - **Location**: Lines 307-423 in `AddItineraryView.swift`
   - Validates all required fields
   - Geocodes all stop addresses to get latitude/longitude coordinates
   - Creates an `Itinerary` object with all the data

### 3. **Storage** → `ItinerariesManager.shared.addItinerary()`
   - **Location**: `TripTuner/Utilities/ItinerariesManager.swift` (line 38-40)
   - **Current Implementation**: Simply adds to in-memory array
   - **For Backend**: This is where you'll add your API call!

### 4. **Display** → `HomeViewModel` → `HomeView`
   - **Location**: 
     - `TripTuner/ViewModels/HomeViewModel.swift` (observes `ItinerariesManager`)
     - `TripTuner/Views/Home/HomeView.swift` (displays on map)
   - `HomeViewModel` subscribes to `ItinerariesManager.$itineraries` using Combine
   - When itineraries change, the map automatically updates
   - Map shows pins using `itinerary.stops.first?.coordinate` (latitude/longitude)

---

## Key Files for Backend Integration

### **Primary Integration Point: `ItinerariesManager.swift`**

```swift
// TripTuner/Utilities/ItinerariesManager.swift

class ItinerariesManager: ObservableObject {
    static let shared = ItinerariesManager()
    
    @Published var itineraries: [Itinerary] = []
    
    // THIS IS WHERE YOU'LL ADD BACKEND CALLS:
    
    func loadItineraries() {
        // Currently: loads from MockData
        // TODO: Replace with backend API call
        // Example: Task { await NetworkManager.shared.getItineraries() }
    }
    
    func addItinerary(_ itinerary: Itinerary) {
        // Currently: just adds to array
        // TODO: Add backend API call here!
        // Example: 
        // Task {
        //     let saved = try await NetworkManager.shared.createItinerary(itinerary)
        //     await MainActor.run { itineraries.insert(saved, at: 0) }
        // }
        itineraries.insert(itinerary, at: 0)
    }
    
    func updateItinerary(_ itinerary: Itinerary) {
        // TODO: Add backend API call
        if let index = itineraries.firstIndex(where: { $0.id == itinerary.id }) {
            itineraries[index] = itinerary
        }
    }
}
```

### **Network Manager (Already Set Up)**
- **Location**: `TripTuner/Network/NetworkManager.swift`
- Already has placeholder functions for all API endpoints
- Just needs implementation!

---

## Data Structures

### **Itinerary Model**
**Location**: `TripTuner/Models/Itinerary.swift`

```swift
struct Itinerary: Identifiable, Codable {
    let id: String                    // UUID
    var title: String
    var description: String
    var category: ItineraryCategory   // .restaurants, .cafes, .attractions
    var authorID: String
    var authorName: String
    var authorHandle: String
    var authorProfileImageURL: String?
    var stops: [Stop]                // Array of stops
    var photos: [String]             // Array of photo URLs
    var likes: Int
    var comments: Int
    var timeEstimate: Int            // in hours
    var cost: Double?
    var costLevel: CostLevel?        // .free, .$, .$$, .$$$
    var noiseLevel: NoiseLevel?      // .quiet, .moderate, .loud, .veryLoud
    var region: PhiladelphiaRegion?  // .centerCity, .universityCity, etc.
    var createdAt: Date
    var isLiked: Bool
    var isSaved: Bool
}
```

### **Stop Model**
**Location**: `TripTuner/Models/Stop.swift`

```swift
struct Stop: Identifiable, Codable {
    let id: String
    var locationName: String         // e.g., "Rittenhouse Square"
    var address: String               // Full address string
    var addressComponents: Address?  // Structured address (street, city, state, zip)
    var latitude: Double             // REQUIRED for map display!
    var longitude: Double            // REQUIRED for map display!
    var notes: String?
    var order: Int                   // Order in itinerary (1, 2, 3...)
}
```

### **Address Model**
**Location**: `TripTuner/Models/Address.swift`

```swift
struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
}
```

---

## Integration Steps

### Step 1: Implement `NetworkManager.createItinerary()`
```swift
// In NetworkManager.swift
func createItinerary(_ itinerary: Itinerary) async throws -> Itinerary {
    // 1. Encode itinerary to JSON
    // 2. POST to your backend API
    // 3. Decode response
    // 4. Return saved itinerary (with server-generated ID if needed)
}
```

### Step 2: Update `ItinerariesManager.addItinerary()`
```swift
func addItinerary(_ itinerary: Itinerary) {
    Task {
        do {
            let saved = try await NetworkManager.shared.createItinerary(itinerary)
            await MainActor.run {
                itineraries.insert(saved, at: 0)
            }
        } catch {
            // Handle error (show alert, etc.)
            print("Error creating itinerary: \(error)")
        }
    }
}
```

### Step 3: Implement `NetworkManager.getItineraries()`
```swift
func getItineraries(category: ItineraryCategory?, 
                   location: CLLocationCoordinate2D?, 
                   radius: Double?) async throws -> [Itinerary] {
    // GET from backend with optional filters
    // Return array of itineraries
}
```

### Step 4: Update `ItinerariesManager.loadItineraries()`
```swift
func loadItineraries() {
    Task {
        do {
            let fetched = try await NetworkManager.shared.getItineraries(
                category: nil, 
                location: nil, 
                radius: nil
            )
            await MainActor.run {
                itineraries = fetched
                syncWithLikedManager()
            }
        } catch {
            // Handle error
            print("Error loading itineraries: \(error)")
        }
    }
}
```

---

## Important Notes

1. **Coordinates are Critical**: The map uses `stop.latitude` and `stop.longitude` to display pins. Make sure your backend stores and returns these values!

2. **Reactive Updates**: The app uses Combine to automatically update the UI when `ItinerariesManager.itineraries` changes. Just update the `@Published` property and the map will refresh.

3. **Geocoding Happens Client-Side**: Currently, addresses are geocoded in `AddItineraryView` before creating the itinerary. You can either:
   - Keep client-side geocoding (current approach)
   - Move geocoding to backend (send address, backend returns coordinates)

4. **Other Managers to Integrate**:
   - `LikedItinerariesManager` - for likes
   - `SavedItinerariesManager` - for saved itineraries
   - `CompletedItinerariesManager` - for completed trips

5. **Error Handling**: Make sure to handle network errors gracefully and show user-friendly messages.

---

## Example Backend API Structure

Your backend should accept POST requests like:

```json
{
  "title": "Coffee Tour of Center City",
  "description": "A great coffee crawl...",
  "category": "cafes",
  "authorID": "user123",
  "authorName": "John Doe",
  "authorHandle": "@johndoe",
  "stops": [
    {
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
  "timeEstimate": 2,
  "costLevel": "$",
  "noiseLevel": "moderate",
  "region": "centerCity",
  "likes": 0,
  "comments": 0
}
```

And return the same structure with a server-generated `id` and `createdAt` timestamp.
