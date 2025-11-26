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
    @Published var savedItineraries: [Itinerary] = []
    @Published var milesTraveled: Double = 47.3
    @Published var neighborhoodsExplored: Int = 12
    @Published var tripsCompleted: Int = 23
    @Published var isLoading = false
    @Published var profileImage: UIImage?
    @Published var showAchievementDetail = false
    @Published var selectedAchievement: Achievement?
    
    init(user: User) {
        self.user = user
        loadUserData()
    }
    
    func loadUserData() {
        isLoading = true
        // Mock data loading - user's own itineraries
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Only show itineraries created by this user
            // For demo: show empty by default, or add some with matching authorID
            self.userItineraries = MockData.sampleItineraries.filter { $0.authorID == self.user.id }
            // Mock saved itineraries (these are saved by the user, not created by them)
            self.savedItineraries = Array(MockData.sampleItineraries.prefix(3))
            self.isLoading = false
        }
    }
    
    func refreshStats() {
        loadUserData()
    }
    
    func showAchievement(_ achievement: Achievement) {
        selectedAchievement = achievement
        showAchievementDetail = true
    }
}

