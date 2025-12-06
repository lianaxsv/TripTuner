//
//  ProfileViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
class ProfileViewModel: ObservableObject {
    
    @Published var user: User?
    @Published var completedItineraries: [Itinerary] = []
    @Published var savedItineraries: [Itinerary] = []
    @Published var milesTraveled: Double = 47.3
    @Published var neighborhoodsExplored: Int = 12
    @Published var tripsCompleted: Int = 0
    @Published var isLoading = false
    @Published var profileImage: UIImage?
    @Published var showAchievementDetail = false
    @Published var selectedAchievement: Achievement?

    private let savedManager = SavedItinerariesManager.shared
    private let completedManager = CompletedItinerariesManager.shared
    private let itinerariesManager = ItinerariesManager.shared
    private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
            self.authViewModel = authViewModel
            self.user = authViewModel.currentUser
            loadUserData()
        }
    
    func loadUserData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.completedItineraries = self.completedManager.getCompletedItineraries(from: self.itinerariesManager.itineraries)
            self.savedItineraries = self.savedManager.getSavedItineraries(from: self.itinerariesManager.itineraries)
            self.tripsCompleted = self.completedItineraries.count
            self.isLoading = false
        }
    }
    
    func setAuthViewModel(_ auth: AuthViewModel) {
        self.user = auth.currentUser
    }
}
