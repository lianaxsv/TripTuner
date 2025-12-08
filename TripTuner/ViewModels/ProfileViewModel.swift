//
//  ProfileViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    
    @Published var user: User?
    @Published var completedItineraries: [Itinerary] = []
    @Published var savedItineraries: [Itinerary] = []
    @Published var milesTraveled: Double = 0
    @Published var neighborhoodsExplored: Int = 0
    @Published var tripsCompleted: Int = 0
    @Published var isLoading = false
    @Published var profileImage: UIImage?
    @Published var profileImageURL: String?
    @Published var showAchievementDetail = false
    @Published var selectedAchievement: Achievement?
    @Published var neighborhoods: [String] = []


    private let savedManager = SavedItinerariesManager.shared
    private let completedManager = CompletedItinerariesManager.shared
    private let itinerariesManager = ItinerariesManager.shared
    private let db = Firestore.firestore()
    private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
            self.authViewModel = authViewModel
            self.user = authViewModel.currentUser
            loadUserData()
            loadProfileImage()
        }
    
    func loadUserData() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.completedItineraries = self.completedManager.getCompletedItineraries(from: self.itinerariesManager.itineraries)
            self.savedItineraries = self.savedManager.getSavedItineraries(from: self.itinerariesManager.itineraries)
            self.tripsCompleted = self.completedItineraries.count
            self.updateNeighborhoodStats()
            self.updateAchievements()
            self.isLoading = false
        }
    }
    
    private func updateNeighborhoodStats() {
        let regions = completedItineraries
            .compactMap {
                // Prefer the region enum when available
                if let region = $0.region {
                    return region.rawValue
                }
                // Fallback to the Firestore string
                return $0.regionString
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        print("DEBUG — Regions: \(regions)")

        let unique = Array(Set(regions)).sorted()
        neighborhoods = unique
        neighborhoodsExplored = unique.count

        print("DEBUG — Unique:", unique)
        print("DEBUG — Count:", neighborhoodsExplored)
    }

    
    func loadProfileImage() {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let data = snapshot?.data(),
               let profileImageURL = data["profileImageURL"] as? String,
               !profileImageURL.isEmpty {
                DispatchQueue.main.async {
                    self.profileImageURL = profileImageURL
                    // Load image from URL
                    self.loadImageFromURL(profileImageURL)
                }
            }
        }
    }
    
    private func loadImageFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async {
                self.profileImage = image
            }
        }.resume()
    }
    
    func setAuthViewModel(_ auth: AuthViewModel) {
        self.authViewModel = auth
        self.user = auth.currentUser
        loadProfileImage()
    }
    
    func refreshStats() {
        loadUserData()
        loadProfileImage()
    }
    func updateAchievements() {
        print("DEBUG: \(neighborhoodsExplored)")

        guard var user = user else { return }
        
        var updatedAchievements: [Achievement] = []
        
        for var achievement in MockData.achievements {
            switch achievement.title {
            
            case "Explorer":
                if neighborhoodsExplored >= 5 && achievement.unlockedAt == nil {
                    achievement.unlockedAt = Date()
                }
                
            case "Goal Crusher":
                if tripsCompleted >= 20 && achievement.unlockedAt == nil {
                    achievement.unlockedAt = Date()
                }
            
            case "Coffee Connoisseur":
                let cafeVisits = completedItineraries.filter { $0.category == .cafes }.count
                if cafeVisits >= 10 && achievement.unlockedAt == nil {
                    achievement.unlockedAt = Date()
                }
            
            default:
                break
            }
            
            updatedAchievements.append(achievement)
        }
        
        user.achievements = updatedAchievements
        self.user = user
        print("DEBUG: \(updatedAchievements)")
    }
}
