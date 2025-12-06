//
//  SavedItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class SavedItinerariesManager: ObservableObject {
    static let shared = SavedItinerariesManager()
    
    @Published var savedItineraryIDs: Set<String> = []
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {
        loadSavedItineraries()
    }
    
    deinit {
        listener?.remove()
    }
    
    func loadSavedItineraries() {
        guard let userID = Auth.auth().currentUser?.uid else {
            savedItineraryIDs = []
            return
        }
        
        listener = db.collection("users").document(userID)
            .collection("savedItineraries")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading saved itineraries: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.savedItineraryIDs = []
                        return
                    }
                    
                    self.savedItineraryIDs = Set(documents.map { $0.documentID })
                }
            }
    }
    
    func isSaved(_ itineraryID: String) -> Bool {
        savedItineraryIDs.contains(itineraryID)
    }
    
    func toggleSave(_ itineraryID: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let isCurrentlySaved = savedItineraryIDs.contains(itineraryID)
        let savedRef = db.collection("users").document(userID)
            .collection("savedItineraries").document(itineraryID)
        
        if isCurrentlySaved {
            // Unsave
            savedRef.delete { error in
                if let error = error {
                    print("Error unsaving: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.savedItineraryIDs.remove(itineraryID)
                    }
                }
            }
        } else {
            // Save
            savedRef.setData([
                "itineraryID": itineraryID,
                "savedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    print("Error saving: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.savedItineraryIDs.insert(itineraryID)
                    }
                }
            }
        }
    }
    
    func reloadSavedItineraries() {
        loadSavedItineraries()
    }
    
    func clearSavedItineraries() {
        listener?.remove()
        listener = nil
        DispatchQueue.main.async {
            self.savedItineraryIDs = []
        }
    }
    
    func getSavedItineraries(from allItineraries: [Itinerary]) -> [Itinerary] {
        allItineraries.filter { savedItineraryIDs.contains($0.id) }
    }
}
