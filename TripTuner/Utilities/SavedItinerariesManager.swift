//
//  SavedItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI

class SavedItinerariesManager: ObservableObject {
    static let shared = SavedItinerariesManager()
    
    @Published var savedItineraryIDs: Set<String> = []
    
    private init() {
        // Load saved IDs from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "savedItineraryIDs"),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            savedItineraryIDs = ids
        } else {
            // Initialize with mock saved itineraries for demo
            savedItineraryIDs = Set(MockData.sampleItineraries.prefix(3).map { $0.id })
        }
    }
    
    func isSaved(_ itineraryID: String) -> Bool {
        savedItineraryIDs.contains(itineraryID)
    }
    
    func toggleSave(_ itineraryID: String) {
        if savedItineraryIDs.contains(itineraryID) {
            savedItineraryIDs.remove(itineraryID)
        } else {
            savedItineraryIDs.insert(itineraryID)
        }
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(savedItineraryIDs) {
            UserDefaults.standard.set(data, forKey: "savedItineraryIDs")
        }
    }
    
    func getSavedItineraries(from allItineraries: [Itinerary]) -> [Itinerary] {
        allItineraries.filter { savedItineraryIDs.contains($0.id) }
    }
}

