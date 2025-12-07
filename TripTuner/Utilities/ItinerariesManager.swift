//
//  ItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ItinerariesManager: ObservableObject {
    static let shared = ItinerariesManager()
    
    @Published var itineraries: [Itinerary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {
        loadItineraries()
    }
    
    deinit {
        listener?.remove()
    }
    
    func loadItineraries() {
        // Check if user is authenticated before loading
        guard Auth.auth().currentUser != nil else {
            // User not logged in, clear itineraries
            DispatchQueue.main.async {
                self.itineraries = []
                self.isLoading = false
            }
            return
        }
        
        // Remove existing listener if any
        listener?.remove()
        
        isLoading = true
        errorMessage = nil
        
        // Set up real-time listener for all itineraries
        listener = db.collection("itineraries")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        print("Error loading itineraries: \(error.localizedDescription)")
                        // Don't use mock data - just show empty array if there's an error
                        // In production, you'd want to show an error message to the user
                        self.itineraries = []
                        self.syncWithLikedManager()
                        return
                    }
                    
                    // If snapshot is nil or has no documents, just use empty array
                    // (Don't fall back to mock data - this is real user data)
                    guard let documents = snapshot?.documents else {
                        self.itineraries = []
                        self.syncWithLikedManager()
                        return
                    }
                    
                    var loadedItineraries: [Itinerary] = []
                    var authorIDs = Set<String>()
                    
                    // First pass: load itineraries and collect author IDs
                    for document in documents {
                        if let itinerary = self.itineraryFromFirestore(document: document) {
                            loadedItineraries.append(itinerary)
                            authorIDs.insert(itinerary.authorID)
                        }
                    }
                    
                    // Fetch profile pictures for all authors
                    if !authorIDs.isEmpty {
                        self.loadAuthorProfilePictures(authorIDs: Array(authorIDs)) { profilePictures in
                            // Update itineraries with profile pictures
                            for index in loadedItineraries.indices {
                                let authorID = loadedItineraries[index].authorID
                                if let profileImageURL = profilePictures[authorID] {
                                    loadedItineraries[index].authorProfileImageURL = profileImageURL
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.itineraries = loadedItineraries
                                self.syncWithLikedManager()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.itineraries = loadedItineraries
                            self.syncWithLikedManager()
                        }
                    }
                }
            }
    }
    
    func reloadItineraries() {
        // Public method to reload itineraries (useful after login)
        loadItineraries()
    }
    
    func clearItineraries() {
        // Clear listener and itineraries (useful on logout)
        listener?.remove()
        listener = nil
        DispatchQueue.main.async {
            self.itineraries = []
            self.isLoading = false
        }
    }
    
    func syncWithLikedManager() {
        let likedManager = LikedItinerariesManager.shared
        for index in itineraries.indices {
            // Update like count from persisted state
            let persistedCount = likedManager.getLikeCount(for: itineraries[index].id, defaultCount: itineraries[index].likes)
            itineraries[index].likes = persistedCount
            
            // Update isLiked state
            itineraries[index].isLiked = likedManager.isLiked(itineraries[index].id)
        }
    }
    
    func addItinerary(_ itinerary: Itinerary) {
        // Add to local array immediately for instant UI update
        itineraries.insert(itinerary, at: 0)
        
        // Save to Firestore
        saveItineraryToFirestore(itinerary)
    }
    
    private func saveItineraryToFirestore(_ itinerary: Itinerary) {
        let itineraryData = itineraryToFirestoreData(itinerary)
        
        db.collection("itineraries").document(itinerary.id).setData(itineraryData) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to save itinerary: \(error.localizedDescription)"
                    print("Error saving itinerary: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateItinerary(_ itinerary: Itinerary) {
        // Update local array
        if let index = itineraries.firstIndex(where: { $0.id == itinerary.id }) {
            itineraries[index] = itinerary
        }
        
        // Update in Firestore
        let itineraryData = itineraryToFirestoreData(itinerary)
        db.collection("itineraries").document(itinerary.id).updateData(itineraryData) { error in
            if let error = error {
                print("Error updating itinerary: \(error.localizedDescription)")
            }
        }
    }
    
    func updateLikeCount(for itineraryID: String, newCount: Int) {
        if let index = itineraries.firstIndex(where: { $0.id == itineraryID }) {
            itineraries[index].likes = newCount
            itineraries[index].isLiked = LikedItinerariesManager.shared.isLiked(itineraryID)
            // Note: We don't update Firestore here - the likes subcollection is the source of truth
            // The main document's "likes" field is updated via Cloud Functions or server-side logic
        }
    }
    
    private func loadAuthorProfilePictures(authorIDs: [String], completion: @escaping ([String: String]) -> Void) {
        let db = Firestore.firestore()
        var profilePictures: [String: String] = [:]
        let group = DispatchGroup()
        
        for authorID in authorIDs {
            group.enter()
            db.collection("users").document(authorID).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let data = snapshot?.data(),
                   let profileImageURL = data["profileImageURL"] as? String,
                   !profileImageURL.isEmpty {
                    profilePictures[authorID] = profileImageURL
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(profilePictures)
        }
    }
    
    // MARK: - Firestore Conversion Helpers
    
    private func itineraryToFirestoreData(_ itinerary: Itinerary) -> [String: Any] {
        var data: [String: Any] = [
            "id": itinerary.id,
            "title": itinerary.title,
            "description": itinerary.description,
            "category": itinerary.category.rawValue,
            "authorID": itinerary.authorID,
            "authorName": itinerary.authorName,
            "authorHandle": itinerary.authorHandle,
            "stops": itinerary.stops.map { stopToFirestoreData($0) },
            "photos": itinerary.photos,
            "likes": itinerary.likes,
            "comments": itinerary.comments,
            "timeEstimate": itinerary.timeEstimate,
            "createdAt": Timestamp(date: itinerary.createdAt)
        ]
        
        // Always include authorProfileImageURL (even if nil)
        if let profileImageURL = itinerary.authorProfileImageURL, !profileImageURL.isEmpty {
            data["authorProfileImageURL"] = profileImageURL
        } else {
            data["authorProfileImageURL"] = NSNull()
        }
        
        if let cost = itinerary.cost {
            data["cost"] = cost
        } else {
            data["cost"] = NSNull()
        }
        
        if let costLevel = itinerary.costLevel {
            data["costLevel"] = costLevel.rawValue
        } else {
            data["costLevel"] = NSNull()
        }
        
        if let noiseLevel = itinerary.noiseLevel {
            data["noiseLevel"] = noiseLevel.rawValue // Int value
        } else {
            data["noiseLevel"] = NSNull()
        }
        
        if let region = itinerary.region {
            data["region"] = region.rawValue
        } else {
            data["region"] = NSNull()
        }
        
        return data
    }
    
    private func stopToFirestoreData(_ stop: Stop) -> [String: Any] {
        var data: [String: Any] = [
            "id": stop.id,
            "locationName": stop.locationName,
            "address": stop.address,
            "latitude": stop.latitude,
            "longitude": stop.longitude,
            "order": stop.order
        ]
        
        if let notes = stop.notes {
            data["notes"] = notes
        } else {
            data["notes"] = NSNull()
        }
        
        if let addressComponents = stop.addressComponents {
            data["addressComponents"] = [
                "street": addressComponents.street,
                "city": addressComponents.city,
                "state": addressComponents.state,
                "zipCode": addressComponents.zipCode
            ]
        } else {
            data["addressComponents"] = NSNull()
        }
        
        return data
    }
    
    private func itineraryFromFirestore(document: QueryDocumentSnapshot) -> Itinerary? {
        let data = document.data()
        
        // Get ID - use document ID as fallback
        let id = (data["id"] as? String) ?? document.documentID
        
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let categoryString = data["category"] as? String,
              let category = ItineraryCategory(rawValue: categoryString),
              let authorID = data["authorID"] as? String,
              let authorName = data["authorName"] as? String,
              let authorHandle = data["authorHandle"] as? String,
              let stopsData = data["stops"] as? [[String: Any]],
              let timeEstimate = data["timeEstimate"] as? Int,
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        // These have defaults, so they're not in the guard statement
        let photosArray = data["photos"] as? [String] ?? []
        // Filter out empty photo URLs
        let photos = photosArray.filter { !$0.isEmpty }
        let likes = data["likes"] as? Int ?? 0
        let comments = data["comments"] as? Int ?? 0
        
        let stops = stopsData.compactMap { stopFromFirestoreData($0) }
        
        // Get authorProfileImageURL, filtering out empty strings
        let authorProfileImageURLString = data["authorProfileImageURL"] as? String
        let authorProfileImageURL = (authorProfileImageURLString?.isEmpty == false) ? authorProfileImageURLString : nil
        let cost = data["cost"] as? Double
        let costLevelString = data["costLevel"] as? String
        let costLevel = costLevelString.flatMap { CostLevel(rawValue: $0) }
        let noiseLevelInt = data["noiseLevel"] as? Int
        let noiseLevel = noiseLevelInt.flatMap { NoiseLevel(rawValue: $0) }
        let regionString = data["region"] as? String
        let region = regionString.flatMap { PhiladelphiaRegion(rawValue: $0) }
        
        return Itinerary(
            id: id,
            title: title,
            description: description,
            category: category,
            authorID: authorID,
            authorName: authorName,
            authorHandle: authorHandle,
            authorProfileImageURL: authorProfileImageURL,
            stops: stops,
            photos: photos,
            likes: likes,
            comments: comments,
            timeEstimate: timeEstimate,
            cost: cost,
            costLevel: costLevel,
            noiseLevel: noiseLevel,
            region: region,
            createdAt: createdAtTimestamp.dateValue(),
            isLiked: false,
            isSaved: false
        )
    }
    
    private func stopFromFirestoreData(_ data: [String: Any]) -> Stop? {
        guard let id = data["id"] as? String,
              let locationName = data["locationName"] as? String,
              let address = data["address"] as? String,
              let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
              let order = data["order"] as? Int else {
            return nil
        }
        
        let notes = data["notes"] as? String
        var addressComponents: Address?
        
        if let addressData = data["addressComponents"] as? [String: Any],
           let street = addressData["street"] as? String,
           let city = addressData["city"] as? String,
           let state = addressData["state"] as? String,
           let zipCode = addressData["zipCode"] as? String {
            addressComponents = Address(street: street, city: city, state: state, zipCode: zipCode)
        }
        
        return Stop(
            id: id,
            locationName: locationName,
            address: address,
            addressComponents: addressComponents,
            latitude: latitude,
            longitude: longitude,
            notes: notes,
            order: order
        )
    }
}

