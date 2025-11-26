//
//  CompletedItinerariesManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI

class CompletedItinerariesManager: ObservableObject {
    static let shared = CompletedItinerariesManager()
    
    @Published var completedItineraryIDs: Set<String> = []
    
    private init() {
        // Load completed IDs from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "completedItineraryIDs"),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            completedItineraryIDs = ids
        }
    }
    
    func isCompleted(_ itineraryID: String) -> Bool {
        completedItineraryIDs.contains(itineraryID)
    }
    
    func markCompleted(_ itineraryID: String) {
        completedItineraryIDs.insert(itineraryID)
        saveToUserDefaults()
    }
    
    private func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(completedItineraryIDs) {
            UserDefaults.standard.set(data, forKey: "completedItineraryIDs")
        }
    }
    
    func getCompletedItineraries(from allItineraries: [Itinerary]) -> [Itinerary] {
        allItineraries.filter { completedItineraryIDs.contains($0.id) }
    }
}

