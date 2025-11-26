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
    @Published var completedItineraries: [Itinerary] = []
    @Published var savedItineraries: [Itinerary] = []
    @Published var milesTraveled: Double = 47.3
    @Published var neighborhoodsExplored: Int = 12
    @Published var tripsCompleted: Int = 23
    @Published var isLoading = false
    @Published var profileImage: UIImage?
    @Published var showAchievementDetail = false
    @Published var selectedAchievement: Achievement?
    
    private let savedManager = SavedItinerariesManager.shared
    private let completedManager = CompletedItinerariesManager.shared
    private let itinerariesManager = ItinerariesManager.shared
    
    init(user: User) {
        self.user = user
        loadUserData()
    }
    
    func loadUserData() {
        isLoading = true
        // Mock data loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Get completed itineraries
            self.completedItineraries = self.completedManager.getCompletedItineraries(from: self.itinerariesManager.itineraries)
            // Get saved itineraries from manager
            self.savedItineraries = self.savedManager.getSavedItineraries(from: self.itinerariesManager.itineraries)
            self.tripsCompleted = self.completedItineraries.count
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
