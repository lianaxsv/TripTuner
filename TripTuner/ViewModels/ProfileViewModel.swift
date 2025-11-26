//
//  ProfileViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var userItineraries: [Itinerary] = []
    @Published var milesTraveled: Double = 47.3
    @Published var neighborhoodsExplored: Int = 12
    @Published var tripsCompleted: Int = 23
    @Published var isLoading = false
    
    init(user: User) {
        self.user = user
        loadUserData()
    }
    
    func loadUserData() {
        isLoading = true
        // Mock data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.userItineraries = MockData.sampleItineraries
            self.isLoading = false
        }
    }
    
    func refreshStats() {
        loadUserData()
    }
}

