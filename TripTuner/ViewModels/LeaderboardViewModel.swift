//
//  LeaderboardViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

enum LeaderboardPeriod: String, CaseIterable {
    case thisMonth = "This Month"
    case allTime = "All Time"
}

class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var selectedPeriod: LeaderboardPeriod = .thisMonth
    @Published var isLoading = false
    
    private let itinerariesManager = ItinerariesManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadLeaderboard()
        // Observe changes to itineraries to update leaderboard (debounced to prevent constant updates)
        itinerariesManager.$itineraries
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadLeaderboard()
            }
            .store(in: &cancellables)
    }
    
    var topThree: [LeaderboardEntry] {
        Array(entries.prefix(3))
    }
    
    var publicEntries: [LeaderboardEntry] {
        // Show top 10 publicly (excluding top 3 which are in podium)
        Array(entries.dropFirst(3).prefix(7))
    }
    
    var remainingEntries: [LeaderboardEntry] {
        Array(entries.dropFirst(3))
    }
    
    var currentUserEntry: LeaderboardEntry? {
        guard let userID = Auth.auth().currentUser?.uid else { return nil }
        return entries.first { $0.user.id == userID }
    }
    
    func selectPeriod(_ period: LeaderboardPeriod) {
        selectedPeriod = period
        loadLeaderboard()
    }
    
    func loadLeaderboard() {
        isLoading = true
        
        // Calculate points from upvotes on itineraries
        var userPoints: [String: Int] = [:] // userID -> total upvotes
        var userItineraryCount: [String: Int] = [:] // userID -> itinerary count
        var userInfo: [String: (name: String, handle: String)] = [:] // userID -> user info
        
        let dateFilter: Date?
        if selectedPeriod == .thisMonth {
            let calendar = Calendar.current
            dateFilter = calendar.date(byAdding: .month, value: -1, to: Date())
        } else {
            dateFilter = nil
        }
        
        // Process all itineraries to calculate points
        for itinerary in itinerariesManager.itineraries {
            // Filter by date if needed
            if let dateFilter = dateFilter, itinerary.createdAt < dateFilter {
                continue
            }
            
            let userId = itinerary.authorID
            let upvotes = itinerary.likes
            
            // Sum upvotes as points
            userPoints[userId, default: 0] += upvotes
            userItineraryCount[userId, default: 0] += 1
            
            // Store user info from itinerary
            if userInfo[userId] == nil {
                userInfo[userId] = (name: itinerary.authorName, handle: itinerary.authorHandle)
            }
        }
        
        // Create leaderboard entries from all users who have itineraries
        var leaderboardEntries: [LeaderboardEntry] = []
        
        // Process users from itineraries
        for (userId, points) in userPoints {
            if let info = userInfo[userId] {
                // Create entry with user info from itinerary
                let entry = LeaderboardEntry(
                    id: userId, // Use userId as ID to maintain consistency
                    user: User(
                        id: userId,
                        name: info.name,
                        email: "",
                        points: points,
                        handle: info.handle
                    ),
                    rank: 0, // Will be set after sorting
                    points: points,
                    tripCount: userItineraryCount[userId] ?? 0
                )
                leaderboardEntries.append(entry)
            }
        }
        
        // Fetch ALL users from Firestore (not just those with itineraries)
        let db = Firestore.firestore()
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                // Continue with existing entries
                self.finalizeLeaderboard(leaderboardEntries)
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.finalizeLeaderboard(leaderboardEntries)
                return
            }
            
            // Create a map of existing entries by userID to preserve profile pictures
            var entriesByUserID: [String: LeaderboardEntry] = [:]
            for entry in leaderboardEntries {
                entriesByUserID[entry.user.id] = entry
            }
            
            // Update all users with profile pictures from Firestore
            for document in documents {
                let userId = document.documentID
                let data = document.data()
                let name = data["name"] as? String ?? "User"
                let handle = data["handle"] as? String ?? "@user"
                let profileImageURL = data["profileImageURL"] as? String
                
                if var existingEntry = entriesByUserID[userId] {
                    // Update existing entry with profile picture while preserving other data
                    var user = existingEntry.user
                    // Always update profile picture if we have one from Firestore
                    if let profileImageURL = profileImageURL, !profileImageURL.isEmpty {
                        user.profileImageURL = profileImageURL
                    } else if user.profileImageURL == nil || user.profileImageURL?.isEmpty == true {
                        // Keep existing profile picture if Firestore doesn't have one
                        // Don't overwrite with nil
                    }
                    user.name = name // Update name in case it changed
                    user.handle = handle // Update handle in case it changed
                    existingEntry.user = user
                    entriesByUserID[userId] = existingEntry
                } else {
                    // Create new entry for user without itineraries (0 points)
                    let user = User(
                        id: userId,
                        name: name,
                        email: data["email"] as? String ?? "",
                        profileImageURL: (profileImageURL?.isEmpty == false) ? profileImageURL : nil,
                        year: data["year"] as? String,
                        streak: data["streak"] as? Int ?? 0,
                        points: 0,
                        achievements: [],
                        handle: handle
                    )
                    entriesByUserID[userId] = LeaderboardEntry(
                        id: userId, // Use userId as ID to maintain consistency
                        user: user,
                        rank: 0,
                        points: 0,
                        tripCount: 0
                    )
                }
            }
            
            // Convert back to array - profile pictures are now preserved
            let allEntries = Array(entriesByUserID.values)
            self.finalizeLeaderboard(allEntries)
            
            // After finalizing, ensure profile pictures are loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.loadProfilePictures()
            }
        }
    }
    
    private func finalizeLeaderboard(_ leaderboardEntries: [LeaderboardEntry]) {
        // Sort by points (descending) and assign ranks
        var sortedEntries = leaderboardEntries
        sortedEntries.sort { $0.points > $1.points }
        
        // Preserve profile pictures from existing entries (only if new entry doesn't have one)
        let existingEntriesByID = Dictionary(uniqueKeysWithValues: self.entries.map { ($0.user.id, $0) })
        
        for (index, _) in sortedEntries.enumerated() {
            sortedEntries[index].rank = index + 1
            
            // Preserve profile picture if new entry doesn't have one but existing entry does
            let userId = sortedEntries[index].user.id
            if sortedEntries[index].user.profileImageURL == nil || sortedEntries[index].user.profileImageURL?.isEmpty == true {
                if let existingEntry = existingEntriesByID[userId],
                   let existingProfileImageURL = existingEntry.user.profileImageURL,
                   !existingProfileImageURL.isEmpty {
                    sortedEntries[index].user.profileImageURL = existingProfileImageURL
                }
            }
        }
        
        DispatchQueue.main.async {
            self.entries = sortedEntries
            self.isLoading = false
        }
    }
    
    func refreshLeaderboard() {
        loadLeaderboard()
    }
    
    func loadProfilePictures() {
        // Load profile pictures for all current entries
        guard !entries.isEmpty else { return }
        
        let db = Firestore.firestore()
        let userIDs = Set(entries.map { $0.user.id }) // Use Set to avoid duplicates
        
        // Fetch all user documents to get profile pictures
        let group = DispatchGroup()
        var profilePictures: [String: String] = [:]
        
        for userID in userIDs {
            group.enter()
            db.collection("users").document(userID).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error loading profile picture for \(userID): \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let profileImageURL = data["profileImageURL"] as? String,
                   !profileImageURL.isEmpty {
                    profilePictures[userID] = profileImageURL
                }
            }
        }
        
        group.notify(queue: .main) {
            // Update entries with profile pictures
            var updatedEntries = self.entries
            for index in updatedEntries.indices {
                let userID = updatedEntries[index].user.id
                if let profileImageURL = profilePictures[userID] {
                    updatedEntries[index].user.profileImageURL = profileImageURL
                }
            }
            self.entries = updatedEntries
        }
    }
}

