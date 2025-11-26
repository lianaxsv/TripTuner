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
    
    private let savedManager = SavedItinerariesManager.shared
    
    init(user: User) {
        self.user = user
        loadUserData()
    }
    
    func loadUserData() {
        isLoading = true
        // Mock data loading - user's own itineraries
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Only show itineraries created by this user
            self.userItineraries = MockData.sampleItineraries.filter { $0.authorID == self.user.id }
            // Get saved itineraries from manager
            self.savedItineraries = self.savedManager.getSavedItineraries(from: MockData.sampleItineraries)
            self.isLoading = false
        }
    }
    
    func refreshSavedItineraries() {
        savedItineraries = savedManager.getSavedItineraries(from: MockData.sampleItineraries)
    }
    
    func refreshStats() {
        loadUserData()
    }
    
    func showAchievement(_ achievement: Achievement) {
        selectedAchievement = achievement
        showAchievementDetail = true
    }
}

