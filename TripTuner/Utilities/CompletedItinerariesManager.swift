//
//  CompletedItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class CompletedItinerariesManager: ObservableObject {
    static let shared = CompletedItinerariesManager()
    
    @Published var completedItineraryIDs: Set<String> = []
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {
        loadCompletedItineraries()
    }
    
    deinit {
        listener?.remove()
    }
    
    func loadCompletedItineraries() {
        guard let userID = Auth.auth().currentUser?.uid else {
            completedItineraryIDs = []
            return
        }
        
        listener = db.collection("users").document(userID)
            .collection("completedItineraries")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading completed itineraries: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.completedItineraryIDs = []
                        return
                    }
                    
                    self.completedItineraryIDs = Set(documents.map { $0.documentID })
                }
            }
    }
    
    func isCompleted(_ itineraryID: String) -> Bool {
        completedItineraryIDs.contains(itineraryID)
    }
    
    func markCompleted(_ itineraryID: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let completedRef = db.collection("users").document(userID)
            .collection("completedItineraries").document(itineraryID)
        
        completedRef.setData([
            "itineraryID": itineraryID,
            "completedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error marking as completed: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.completedItineraryIDs.insert(itineraryID)
                }
            }
        }
    }
    
    func unmarkCompleted(_ itineraryID: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        let completedRef = db.collection("users").document(userID)
            .collection("completedItineraries").document(itineraryID)
        
        completedRef.delete { error in
            if let error = error {
                print("Error unmarking as completed: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.completedItineraryIDs.remove(itineraryID)
                }
            }
        }
    }
    
    func toggleCompleted(_ itineraryID: String) {
        if isCompleted(itineraryID) {
            unmarkCompleted(itineraryID)
        } else {
            markCompleted(itineraryID)
        }
    }
    
    func reloadCompletedItineraries() {
        loadCompletedItineraries()
    }
    
    func clearCompletedItineraries() {
        listener?.remove()
        listener = nil
        DispatchQueue.main.async {
            self.completedItineraryIDs = []
        }
    }
    
    func getCompletedItineraries(from allItineraries: [Itinerary]) -> [Itinerary] {
        allItineraries.filter { completedItineraryIDs.contains($0.id) }
    }
}
