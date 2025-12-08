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
    // Cache profile pictures to persist across leaderboard updates
    private var profilePictureCache: [String: String] = [:]
    
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
        
        // CRITICAL: Preserve ALL profile pictures from existing entries FIRST before recreating
        // This ensures profile pictures are never lost during updates
        for entry in self.entries {
            if let profileImageURL = entry.user.profileImageURL, !profileImageURL.isEmpty {
                profilePictureCache[entry.user.id] = profileImageURL
            }
        }
        
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
                // Use cached profile picture if available
                let cachedProfileImageURL = profilePictureCache[userId]
                
                // Create entry with user info from itinerary
                let entry = LeaderboardEntry(
                    id: userId, // Use userId as ID to maintain consistency
                    user: User(
                        id: userId,
                        name: info.name,
                        email: "",
                        profileImageURL: cachedProfileImageURL,
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
            
            // Create a map of existing entries by userID
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
                
                // Update cache with Firestore profile picture if available (but don't overwrite existing cache if Firestore is nil)
                if let profileImageURL = profileImageURL, !profileImageURL.isEmpty {
                    profilePictureCache[userId] = profileImageURL
                }
                // If Firestore doesn't have one, keep the existing cache value (already set above)
                
                // ALWAYS use cached profile picture (preserved from existing entries or from Firestore)
                let finalProfileImageURL = profilePictureCache[userId]
                
                if var existingEntry = entriesByUserID[userId] {
                    // Update existing entry with profile picture while preserving other data
                    var user = existingEntry.user
                    // ALWAYS use cached profile picture - never set to nil
                    user.profileImageURL = finalProfileImageURL
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
                        profileImageURL: finalProfileImageURL, // Use cached profile picture
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
            
            // After finalizing, fetch fresh profile pictures from Firestore in background
            // This updates the cache for future updates, but doesn't overwrite existing ones
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.loadProfilePictures(forceRefresh: false) // Don't force refresh to preserve existing
            }
        }
    }
    
    private func finalizeLeaderboard(_ leaderboardEntries: [LeaderboardEntry]) {
        // Sort by points (descending) and assign ranks
        var sortedEntries = leaderboardEntries
        sortedEntries.sort { $0.points > $1.points }
        
        // CRITICAL: Always ensure profile pictures are set from cache before displaying
        for (index, _) in sortedEntries.enumerated() {
            sortedEntries[index].rank = index + 1
            
            // ALWAYS use cached profile picture - never leave it as nil
            let userId = sortedEntries[index].user.id
            if let cachedProfileImageURL = profilePictureCache[userId], !cachedProfileImageURL.isEmpty {
                sortedEntries[index].user.profileImageURL = cachedProfileImageURL
            } else {
                // If cache doesn't have it, preserve from current entry if it exists
                // This should rarely happen, but ensures we never lose profile pictures
                if sortedEntries[index].user.profileImageURL == nil || sortedEntries[index].user.profileImageURL?.isEmpty == true {
                    // Try to get from existing entries
                    if let existingEntry = self.entries.first(where: { $0.user.id == userId }),
                       let existingProfileImageURL = existingEntry.user.profileImageURL,
                       !existingProfileImageURL.isEmpty {
                        sortedEntries[index].user.profileImageURL = existingProfileImageURL
                        profilePictureCache[userId] = existingProfileImageURL
                    }
                } else {
                    // If entry already has a profile picture, cache it
                    if let profileImageURL = sortedEntries[index].user.profileImageURL {
                        profilePictureCache[userId] = profileImageURL
                    }
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
    
    func loadProfilePictures(forceRefresh: Bool = false) {
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
            // Update cache and entries with profile pictures
            var updatedEntries = self.entries
            
            for index in updatedEntries.indices {
                let userID = updatedEntries[index].user.id
                
                if let profileImageURL = profilePictures[userID], !profileImageURL.isEmpty {
                    // Always update cache with fresh data from Firestore
                    self.profilePictureCache[userID] = profileImageURL
                    // Always update entry with fresh profile picture
                    updatedEntries[index].user.profileImageURL = profileImageURL
                } else if !forceRefresh {
                    // Only use cache if not forcing refresh and Firestore doesn't have one
                    if let cachedProfileImageURL = self.profilePictureCache[userID], !cachedProfileImageURL.isEmpty {
                        updatedEntries[index].user.profileImageURL = cachedProfileImageURL
                    }
                }
            }
            
            // Only update if we have changes or if forcing refresh
            if forceRefresh || profilePictures.count > 0 {
                self.entries = updatedEntries
            }
        }
    }
}

