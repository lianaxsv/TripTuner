//
//  ContentModerationManager.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

class ContentModerationManager: ObservableObject {
    static let shared = ContentModerationManager()
    
    @Published var blockedUserIDs: Set<String> = []
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var blockedUsersListener: ListenerRegistration?
    
    private init() {
        loadBlockedUsers()
    }
    
    deinit {
        blockedUsersListener?.remove()
    }
    
    // MARK: - Blocking Users
    
    func loadBlockedUsers() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            blockedUserIDs = []
            return
        }
        
        // Remove existing listener if any
        blockedUsersListener?.remove()
        
        // Set up real-time listener for blocked users
        blockedUsersListener = db.collection("users").document(currentUserID)
            .collection("blockedUsers")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading blocked users: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.blockedUserIDs = []
                        return
                    }
                    
                    // Extract blocked user IDs from document IDs
                    self.blockedUserIDs = Set(documents.map { $0.documentID })
                }
            }
    }
    
    func blockUser(_ userID: String, userName: String, userHandle: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Add to local set immediately for instant UI update
        blockedUserIDs.insert(userID)
        
        // Save to Firestore
        let blockData: [String: Any] = [
            "blockedUserID": userID,
            "blockedUserName": userName,
            "blockedUserHandle": userHandle,
            "blockedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(currentUserID)
            .collection("blockedUsers")
            .document(userID)
            .setData(blockData) { [weak self] error in
                if let error = error {
                    print("Error blocking user: \(error.localizedDescription)")
                    // Remove from local set if error
                    DispatchQueue.main.async {
                        self?.blockedUserIDs.remove(userID)
                    }
                } else {
                    // Notify developers of the block
                    self?.notifyDeveloperOfBlock(
                        blockedBy: currentUserID,
                        blockedUserID: userID,
                        blockedUserName: userName,
                        blockedUserHandle: userHandle
                    )
                }
            }
    }
    
    func unblockUser(_ userID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Remove from local set immediately
        blockedUserIDs.remove(userID)
        
        // Remove from Firestore
        db.collection("users").document(currentUserID)
            .collection("blockedUsers")
            .document(userID)
            .delete { [weak self] error in
                if let error = error {
                    print("Error unblocking user: \(error.localizedDescription)")
                    // Re-add to local set if error
                    DispatchQueue.main.async {
                        self?.blockedUserIDs.insert(userID)
                    }
                }
            }
    }
    
    func isUserBlocked(_ userID: String) -> Bool {
        return blockedUserIDs.contains(userID)
    }
    
    // MARK: - Flagging Content
    
    func flagItinerary(_ itineraryID: String, reason: FlagReason, additionalInfo: String? = nil) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get itinerary details for the flag
        db.collection("itineraries").document(itineraryID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching itinerary for flagging: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let authorID = data["authorID"] as? String,
                  let title = data["title"] as? String else {
                return
            }
            
            let flagData: [String: Any] = [
                "contentType": "itinerary",
                "contentID": itineraryID,
                "contentTitle": title,
                "authorID": authorID,
                "authorName": data["authorName"] as? String ?? "Unknown",
                "authorHandle": data["authorHandle"] as? String ?? "@unknown",
                "flaggedBy": currentUserID,
                "reason": reason.rawValue,
                "additionalInfo": additionalInfo ?? NSNull(),
                "flaggedAt": FieldValue.serverTimestamp(),
                "status": "pending"
            ]
            
            // Save flag to Firestore
            self.db.collection("flags").addDocument(data: flagData) { error in
                if let error = error {
                    print("Error flagging itinerary: \(error.localizedDescription)")
                } else {
                    print("✅ Itinerary flagged successfully")
                }
            }
        }
    }
    
    func flagComment(_ commentID: String, itineraryID: String, reason: FlagReason, additionalInfo: String? = nil) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get comment details for the flag
        db.collection("itineraries").document(itineraryID)
            .collection("comments").document(commentID)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching comment for flagging: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let authorID = data["authorID"] as? String,
                      let content = data["content"] as? String else {
                    return
                }
                
                let flagData: [String: Any] = [
                    "contentType": "comment",
                    "contentID": commentID,
                    "itineraryID": itineraryID,
                    "contentPreview": String(content.prefix(100)), // First 100 chars
                    "authorID": authorID,
                    "authorName": data["authorName"] as? String ?? "Unknown",
                    "authorHandle": data["authorHandle"] as? String ?? "@unknown",
                    "flaggedBy": currentUserID,
                    "reason": reason.rawValue,
                    "additionalInfo": additionalInfo ?? NSNull(),
                    "flaggedAt": FieldValue.serverTimestamp(),
                    "status": "pending"
                ]
                
                // Save flag to Firestore
                self.db.collection("flags").addDocument(data: flagData) { error in
                    if let error = error {
                        print("Error flagging comment: \(error.localizedDescription)")
                    } else {
                        print("✅ Comment flagged successfully")
                    }
                }
            }
    }
    
    // MARK: - Developer Notifications
    
    private func notifyDeveloperOfBlock(
        blockedBy: String,
        blockedUserID: String,
        blockedUserName: String,
        blockedUserHandle: String
    ) {
        // Get user info for the person who blocked
        db.collection("users").document(blockedBy).getDocument { [weak self] snapshot, _ in
            guard let self = self else { return }
            
            let blockerName = snapshot?.data()?["name"] as? String ?? "Unknown"
            let blockerHandle = snapshot?.data()?["handle"] as? String ?? "@unknown"
            
            let notificationData: [String: Any] = [
                "type": "user_blocked",
                "blockedBy": blockedBy,
                "blockerName": blockerName,
                "blockerHandle": blockerHandle,
                "blockedUserID": blockedUserID,
                "blockedUserName": blockedUserName,
                "blockedUserHandle": blockedUserHandle,
                "createdAt": FieldValue.serverTimestamp(),
                "reviewed": false
            ]
            
            // Save to developer notifications collection
            self.db.collection("developerNotifications").addDocument(data: notificationData) { error in
                if let error = error {
                    print("Error creating developer notification: \(error.localizedDescription)")
                } else {
                    print("✅ Developer notified of user block")
                }
            }
        }
    }
    
    // MARK: - Content Filtering
    
    func filterBlockedContent<T>(_ items: [T], authorIDKeyPath: KeyPath<T, String>) -> [T] {
        return items.filter { item in
            let authorID = item[keyPath: authorIDKeyPath]
            return !isUserBlocked(authorID)
        }
    }
}

enum FlagReason: String, CaseIterable {
    case spam = "Spam"
    case harassment = "Harassment or Bullying"
    case inappropriate = "Inappropriate Content"
    case misinformation = "Misinformation"
    case other = "Other"
    
    var description: String {
        switch self {
        case .spam:
            return "Repetitive, unwanted, or promotional content"
        case .harassment:
            return "Content that targets, threatens, or harasses others"
        case .inappropriate:
            return "Content that violates community guidelines"
        case .misinformation:
            return "False or misleading information"
        case .other:
            return "Other reason not listed above"
        }
    }
}

