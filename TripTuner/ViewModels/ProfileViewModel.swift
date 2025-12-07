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
            self.isLoading = false
        }
    }
    
    private func updateNeighborhoodStats() {
        let regions = completedItineraries
            .compactMap { $0.region?.rawValue }  // if region is optional; if not, just use `$0.region`
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty }

        let unique = Array(Set(regions)).sorted()
        neighborhoods = unique
        neighborhoodsExplored = unique.count
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
}
