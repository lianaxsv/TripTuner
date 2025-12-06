//
//  LikedItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class LikedItinerariesManager: ObservableObject {
    static let shared = LikedItinerariesManager()
    
    @Published var likedItineraryIDs: Set<String> = []
    @Published var itineraryLikeCounts: [String: Int] = [:] // itineraryID -> like count
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {
        loadLikes()
    }
    
    deinit {
        listener?.remove()
    }
    
    func loadLikes() {
        guard let userID = Auth.auth().currentUser?.uid else {
            likedItineraryIDs = []
            return
        }
        
        // Load user's liked itineraries
        listener = db.collection("users").document(userID)
            .collection("likedItineraries")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading likes: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.likedItineraryIDs = []
                        return
                    }
                    
                    self.likedItineraryIDs = Set(documents.map { $0.documentID })
                }
            }
        
        // Load like counts for all itineraries
        loadLikeCounts()
    }
    
    private func loadLikeCounts() {
        // Listen to all itineraries to get like counts
        db.collection("itineraries").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading like counts: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                for document in documents {
                    let itineraryID = document.documentID
                    // Count likes from Firestore
                    self.db.collection("itineraries").document(itineraryID)
                        .collection("likes")
                        .getDocuments { snapshot, error in
                            if let snapshot = snapshot {
                                DispatchQueue.main.async {
                                    self.itineraryLikeCounts[itineraryID] = snapshot.documents.count
                                }
                            }
                        }
                }
            }
        }
    }
    
    func isLiked(_ itineraryID: String) -> Bool {
        likedItineraryIDs.contains(itineraryID)
    }
    
    func getLikeCount(for itineraryID: String, defaultCount: Int) -> Int {
        return itineraryLikeCounts[itineraryID] ?? defaultCount
    }
    
    func toggleLike(_ itineraryID: String, currentCount: Int) -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            return currentCount
        }
        
        let wasLiked = likedItineraryIDs.contains(itineraryID)
        let userLikesRef = db.collection("users").document(userID)
            .collection("likedItineraries").document(itineraryID)
        let itineraryLikesRef = db.collection("itineraries").document(itineraryID)
            .collection("likes").document(userID)
        
        if wasLiked {
            // Unlike
            userLikesRef.delete { error in
                if let error = error {
                    print("Error unliking: \(error.localizedDescription)")
                }
            }
            itineraryLikesRef.delete { error in
                if let error = error {
                    print("Error removing like from itinerary: \(error.localizedDescription)")
                }
            }
            
            // Update local state
            likedItineraryIDs.remove(itineraryID)
            let newCount = max(0, currentCount - 1)
            itineraryLikeCounts[itineraryID] = newCount
            
            // Update itinerary document
            db.collection("itineraries").document(itineraryID).updateData([
                "likes": newCount
            ]) { error in
                if let error = error {
                    print("Error updating like count: \(error.localizedDescription)")
                }
            }
            
            return newCount
        } else {
            // Like
            userLikesRef.setData([
                "itineraryID": itineraryID,
                "likedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Error liking: \(error.localizedDescription)")
                }
            }
            
            itineraryLikesRef.setData([
                "userID": userID,
                "likedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Error adding like to itinerary: \(error.localizedDescription)")
                }
            }
            
            // Update local state
            likedItineraryIDs.insert(itineraryID)
            let newCount = currentCount + 1
            itineraryLikeCounts[itineraryID] = newCount
            
            // Update itinerary document
            db.collection("itineraries").document(itineraryID).updateData([
                "likes": newCount
            ]) { error in
                if let error = error {
                    print("Error updating like count: \(error.localizedDescription)")
                }
            }
            
            return newCount
        }
    }
    
    func reloadLikes() {
        loadLikes()
    }
    
    func clearLikes() {
        listener?.remove()
        listener = nil
        DispatchQueue.main.async {
            self.likedItineraryIDs = []
            self.itineraryLikeCounts = [:]
        }
    }
    
    func updateItineraryLikeCount(_ itineraryID: String, count: Int) {
        itineraryLikeCounts[itineraryID] = count
    }
}
