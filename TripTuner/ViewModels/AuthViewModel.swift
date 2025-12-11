//
//  AuthViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import FirebaseStorage
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        // Restore existing Firebase session if available
        if let user = Auth.auth().currentUser {
            Task { await loadUser(uid: user.uid) }
        }
    }
    
    // MARK: - Public API
    
    func login(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                    return
                }
                guard let user = result?.user else { return }
                Task { 
                    await self.loadUser(uid: user.uid, fallbackEmail: email)
                    // Reload all data after successful login
                    await MainActor.run {
                        ItinerariesManager.shared.reloadItineraries()
                        LikedItinerariesManager.shared.reloadLikes()
                        SavedItinerariesManager.shared.reloadSavedItineraries()
                        CompletedItinerariesManager.shared.reloadCompletedItineraries()
                    }
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, handle: String) {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, !handle.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let normalizedHandle = handle.lowercased()
        
        // 1️⃣ Create Firebase Auth user FIRST (this doesn't require Firestore permissions)
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let firebaseUser = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to create user account."
                }
                return
            }
            
            let uid = firebaseUser.uid
            
            // 2️⃣ Now that user is authenticated, check if handle is available
            // Check in "users" collection
            self.db.collection("users")
                .whereField("handle", isEqualTo: normalizedHandle)
                .getDocuments { snapshot, error in
                    
                    if let error = error {
                        // If error, delete the auth user and show error
                        firebaseUser.delete { _ in }
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = error.localizedDescription
                        }
                        return
                    }
                    
                    // If handle exists in users collection, reject
                    if let snapshot = snapshot, !snapshot.documents.isEmpty {
                        firebaseUser.delete { _ in }
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Handle already taken."
                        }
                        return
                    }
                    
                    // 3️⃣ Check in "handles" collection
                    let handleRef = self.db.collection("handles").document(normalizedHandle)
                    handleRef.getDocument { snapshot, error in
                        
                        if let error = error {
                            firebaseUser.delete { _ in }
                            DispatchQueue.main.async {
                                self.isLoading = false
                                self.errorMessage = error.localizedDescription
                            }
                            return
                        }
                        
                        // If handle is already reserved, reject
                        if let snapshot = snapshot, snapshot.exists {
                            let existingUID = snapshot.data()?["uid"] as? String
                            // If it's not this user's UID, reject
                            if existingUID != uid && existingUID != "TEMP" {
                                firebaseUser.delete { _ in }
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.errorMessage = "Handle already taken."
                                }
                                return
                            }
                        }
                        
                        // 4️⃣ Reserve the handle
                        handleRef.setData(["uid": uid]) { error in
                            if let error = error {
                                firebaseUser.delete { _ in }
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.errorMessage = "Could not reserve handle: \(error.localizedDescription)"
                                }
                                return
                            }
                            
                            // 5️⃣ Create user document in Firestore
                            let userData: [String: Any] = [
                                "name": name,
                                "handle": normalizedHandle,
                                "email": email,
                                "profileImageURL": NSNull(),
                                "year": NSNull(),
                                "streak": 0,
                                "points": 0,
                                "createdAt": FieldValue.serverTimestamp()
                            ]
                            
                            self.db.collection("users").document(uid).setData(userData) { error in
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    if let error = error {
                                        // Cleanup: delete handle reservation and auth user
                                        handleRef.delete { _ in }
                                        firebaseUser.delete { _ in }
                                        self.errorMessage = error.localizedDescription
                                        return
                                    }
                                    
                                    // Success! Create user object
                                    let newUser = User(
                                        id: uid,
                                        name: name,
                                        email: email,
                                        profileImageURL: nil,
                                        year: nil,
                                        streak: 0,
                                        points: 0,
                                        achievements: [],
                                        handle: normalizedHandle
                                    )
                                    
                                    self.currentUser = newUser
                                    self.isAuthenticated = true
                                    // Reload all data after successful signup
                                    ItinerariesManager.shared.reloadItineraries()
                                    LikedItinerariesManager.shared.reloadLikes()
                                    SavedItinerariesManager.shared.reloadSavedItineraries()
                                    CompletedItinerariesManager.shared.reloadCompletedItineraries()
                                }
                            }
                        }
                    }
                }
        }
    }


    
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // SAFELY get the presenting view controller for iOS 15+
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            print("No root view controller found.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Unable to fetch Google ID token."
                isLoading = false
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            
            await loadUser(uid: firebaseUser.uid, fallbackEmail: firebaseUser.email)
            await MainActor.run { 
                self.isLoading = false
                // Reload all data after Google sign-in
                ItinerariesManager.shared.reloadItineraries()
                LikedItinerariesManager.shared.reloadLikes()
                SavedItinerariesManager.shared.reloadSavedItineraries()
                CompletedItinerariesManager.shared.reloadCompletedItineraries()
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    
    func deleteAccount(completion: @escaping (Bool, Error?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🗑️ Starting account deletion for user: \(userID)")
        
        // Get user handle for cleanup
        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(false, error)
                }
                return
            }
            
            let handle = snapshot?.data()?["handle"] as? String
            print("📝 User handle: \(handle ?? "none")")
            
            // CRITICAL: Do ALL deletions WHILE user is still authenticated
            // Step 1: Delete all user subcollections
            print("🗑️ Step 1: Deleting user subcollections...")
            self.deleteUserSubcollections(userID: userID) { [weak self] in
                guard let self = self else { return }
                print("✅ Step 1 complete: User subcollections deleted")
                
                // Step 2: Delete all itineraries created by user and their associated data
                print("🗑️ Step 2: Deleting user itineraries...")
                self.deleteUserItineraries(userID: userID) { [weak self] in
                    guard let self = self else { return }
                    print("✅ Step 2 complete: User itineraries deleted")
                    
                    // Step 3: Delete all comments made by user (from any itinerary) - USE USERID
                    print("🗑️ Step 3: Deleting user comments...")
                    self.deleteUserComments(userID: userID) { [weak self] in
                        guard let self = self else { return }
                        print("✅ Step 3 complete: User comments deleted")
                        
                        // Step 4: Delete all votes made by user on comments - USE USERID
                        print("🗑️ Step 4: Deleting user comment votes...")
                        self.deleteUserCommentVotes(userID: userID) { [weak self] in
                            guard let self = self else { return }
                            print("✅ Step 4 complete: User comment votes deleted")
                            
                            // Step 5: Delete all likes given by user on itineraries - USE USERID
                            print("🗑️ Step 5: Deleting user itinerary likes...")
                            self.deleteUserItineraryLikes(userID: userID) { [weak self] in
                                guard let self = self else { return }
                                print("✅ Step 5 complete: User itinerary likes deleted")
                                
                                // Step 6: Delete user document
                                print("🗑️ Step 6: Deleting user document...")
                                self.db.collection("users").document(userID).delete { [weak self] error in
                                    guard let self = self else { return }
                                    
                                    if let error = error {
                                        print("❌ Error deleting user document: \(error.localizedDescription)")
                                    } else {
                                        print("✅ Step 6 complete: User document deleted")
                                    }
                                    
                                    // Step 7: Delete handle reservation
                                    if let handle = handle {
                                        print("🗑️ Step 7: Deleting handle reservation...")
                                        self.db.collection("handles").document(handle.lowercased()).delete { error in
                                            if let error = error {
                                                print("❌ Error deleting handle: \(error.localizedDescription)")
                                            } else {
                                                print("✅ Step 7 complete: Handle deleted")
                                            }
                                        }
                                    }
                                    
                                    // Step 8: Delete profile picture from Storage
                                    print("🗑️ Step 8: Deleting profile picture...")
                                    let storage = Storage.storage()
                                    let profilePictureRef = storage.reference().child("profile_pictures/\(userID)")
                                    profilePictureRef.delete { error in
                                        if let error = error {
                                            print("❌ Error deleting profile picture: \(error.localizedDescription)")
                                        } else {
                                            print("✅ Step 8 complete: Profile picture deleted")
                                        }
                                    }
                                    
                                    // Step 9: Delete Firebase Auth account (LAST - this will invalidate auth token)
                                    print("🗑️ Step 9: Deleting Firebase Auth account...")
                                    if let currentUser = Auth.auth().currentUser, currentUser.uid == userID {
                                        currentUser.delete { [weak self] authError in
                                            guard let self = self else { return }
                                            
                                            DispatchQueue.main.async {
                                                self.isLoading = false
                                                
                                                if let authError = authError {
                                                    print("❌ Error deleting Auth account: \(authError.localizedDescription)")
                                                    completion(false, authError)
                                                } else {
                                                    print("✅ Step 9 complete: Auth account deleted")
                                                    print("✅ All deletion steps complete!")
                                                }
                                                
                                                // Step 10: Logout AFTER all deletions complete
                                                print("🚪 Logging out...")
                                                self.logout()
                                                
                                                if authError == nil {
                                                    completion(true, nil)
                                                }
                                            }
                                        }
                                    } else {
                                        print("⚠️ No current user found for deletion")
                                        DispatchQueue.main.async {
                                            self.isLoading = false
                                            self.logout()
                                            completion(true, nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Account Deletion Helpers
    
    private func deleteUserSubcollections(userID: String, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        // Delete likedItineraries subcollection
        group.enter()
        db.collection("users").document(userID)
            .collection("likedItineraries")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching likedItineraries: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    group.leave()
                    return
                }
                let batch = self.db.batch()
                docs.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if let error = error {
                        print("❌ Error deleting likedItineraries: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        
        // Delete savedItineraries subcollection
        group.enter()
        db.collection("users").document(userID)
            .collection("savedItineraries")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching savedItineraries: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    group.leave()
                    return
                }
                let batch = self.db.batch()
                docs.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if let error = error {
                        print("❌ Error deleting savedItineraries: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        
        // Delete completedItineraries subcollection
        group.enter()
        db.collection("users").document(userID)
            .collection("completedItineraries")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching completedItineraries: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    group.leave()
                    return
                }
                let batch = self.db.batch()
                docs.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }
                batch.commit { error in
                    if let error = error {
                        print("❌ Error deleting completedItineraries: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    private func deleteUserItineraries(userID: String, completion: @escaping () -> Void) {
        db.collection("itineraries")
            .whereField("authorID", isEqualTo: userID)
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else {
                    completion()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion()
                    return
                }
                
                let group = DispatchGroup()
                
                for itineraryDoc in documents {
                    let itineraryID = itineraryDoc.documentID
                    
                    // Delete all comments in this itinerary (and their votes)
                    group.enter()
                    self.db.collection("itineraries").document(itineraryID)
                        .collection("comments")
                        .getDocuments { snapshot, error in
                            guard let commentDocs = snapshot?.documents, !commentDocs.isEmpty else {
                                group.leave()
                                return
                            }
                            
                            let commentGroup = DispatchGroup()
                            
                            // Delete votes subcollection for each comment
                            for commentDoc in commentDocs {
                                commentGroup.enter()
                                self.db.collection("itineraries").document(itineraryID)
                                    .collection("comments").document(commentDoc.documentID)
                                    .collection("votes")
                                    .getDocuments { snapshot, _ in
                                        if let voteDocs = snapshot?.documents, !voteDocs.isEmpty {
                                            let batch = self.db.batch()
                                            voteDocs.forEach { voteDoc in
                                                batch.deleteDocument(voteDoc.reference)
                                            }
                                            batch.commit { _ in commentGroup.leave() }
                                        } else {
                                            commentGroup.leave()
                                        }
                                    }
                            }
                            
                            commentGroup.notify(queue: .main) {
                                // Delete all comments
                                let batch = self.db.batch()
                                commentDocs.forEach { commentDoc in
                                    batch.deleteDocument(commentDoc.reference)
                                }
                                batch.commit { error in
                                    if let error = error {
                                        print("❌ Error deleting comments for itinerary \(itineraryID): \(error.localizedDescription)")
                                    }
                                    group.leave()
                                }
                            }
                        }
                    
                    // Delete likes subcollection
                    group.enter()
                    self.db.collection("itineraries").document(itineraryID)
                        .collection("likes")
                        .getDocuments { snapshot, _ in
                            let batch = self.db.batch()
                            snapshot?.documents.forEach { doc in
                                batch.deleteDocument(doc.reference)
                            }
                            batch.commit { _ in group.leave() }
                        }
                    
                    // Delete the itinerary itself
                    group.enter()
                    itineraryDoc.reference.delete { _ in group.leave() }
                }
                
                group.notify(queue: .main) {
                    completion()
                }
            }
    }
    
    private func deleteUserComments(userID: String, completion: @escaping () -> Void) {
        // Get all itineraries to check for comments
        db.collection("itineraries").getDocuments { [weak self] snapshot, _ in
            guard let self = self else {
                completion()
                return
            }
            
            guard let itineraryDocs = snapshot?.documents else {
                completion()
                return
            }
            
            let group = DispatchGroup()
            
            for itineraryDoc in itineraryDocs {
                let itineraryID = itineraryDoc.documentID
                
                group.enter()
                // CRITICAL: Use userID to find ALL comments by this user
                self.db.collection("itineraries").document(itineraryID)
                    .collection("comments")
                    .whereField("authorID", isEqualTo: userID)
                    .getDocuments { snapshot, error in
                        guard let commentDocs = snapshot?.documents, !commentDocs.isEmpty else {
                            group.leave()
                            return
                        }
                        
                        let commentGroup = DispatchGroup()
                        
                        // Delete votes subcollection for each comment FIRST
                        for commentDoc in commentDocs {
                            commentGroup.enter()
                            self.db.collection("itineraries").document(itineraryID)
                                .collection("comments").document(commentDoc.documentID)
                                .collection("votes")
                                .getDocuments { snapshot, _ in
                                    if let voteDocs = snapshot?.documents, !voteDocs.isEmpty {
                                        let batch = self.db.batch()
                                        voteDocs.forEach { voteDoc in
                                            batch.deleteDocument(voteDoc.reference)
                                        }
                                        batch.commit { _ in commentGroup.leave() }
                                    } else {
                                        commentGroup.leave()
                                    }
                                }
                        }
                        
                        commentGroup.notify(queue: .main) {
                            // Delete all comments by this user using userID
                            let batch = self.db.batch()
                            commentDocs.forEach { commentDoc in
                                batch.deleteDocument(commentDoc.reference)
                            }
                            batch.commit { error in
                                if let error = error {
                                    print("Error deleting comments: \(error.localizedDescription)")
                                }
                                group.leave()
                            }
                        }
                    }
            }
            
            group.notify(queue: .main) {
                completion()
            }
        }
    }
    
    private func deleteUserCommentVotes(userID: String, completion: @escaping () -> Void) {
        // Get all itineraries
        db.collection("itineraries").getDocuments { [weak self] snapshot, _ in
            guard let self = self else {
                completion()
                return
            }
            
            guard let itineraryDocs = snapshot?.documents else {
                completion()
                return
            }
            
            let group = DispatchGroup()
            
            for itineraryDoc in itineraryDocs {
                let itineraryID = itineraryDoc.documentID
                
                group.enter()
                self.db.collection("itineraries").document(itineraryID)
                    .collection("comments")
                    .getDocuments { snapshot, error in
                        guard let commentDocs = snapshot?.documents else {
                            group.leave()
                            return
                        }
                        
                        let commentGroup = DispatchGroup()
                        
                        for commentDoc in commentDocs {
                            commentGroup.enter()
                            let commentID = commentDoc.documentID
                            let commentRef = self.db.collection("itineraries").document(itineraryID)
                                .collection("comments").document(commentID)
                            let voteRef = commentRef.collection("votes").document(userID)
                            
                            // First, get the vote to check its type
                            voteRef.getDocument { snapshot, error in
                                guard let voteData = snapshot?.data(),
                                      let voteType = voteData["type"] as? String else {
                                    // No vote exists, nothing to delete
                                    commentGroup.leave()
                                    return
                                }
                                
                                // Update comment score based on vote type
                                let scoreChange: Int64 = (voteType == "like") ? -1 : 1
                                
                                // Update the comment score
                                commentRef.updateData([
                                    "score": FieldValue.increment(scoreChange)
                                ]) { error in
                                    if let error = error {
                                        print("❌ Error updating comment score for \(commentID): \(error.localizedDescription)")
                                    }
                                    
                                    // Then delete the vote
                                    voteRef.delete { error in
                                        if let error = error {
                                            print("❌ Error deleting vote for comment \(commentID): \(error.localizedDescription)")
                                        }
                                        commentGroup.leave()
                                    }
                                }
                            }
                        }
                        
                        commentGroup.notify(queue: .main) {
                            group.leave()
                        }
                    }
            }
            
            group.notify(queue: .main) {
                print("✅ All user comment votes deleted and scores updated")
                completion()
            }
        }
    }
    
    private func deleteUserItineraryLikes(userID: String, completion: @escaping () -> Void) {
        // Get all itineraries
        db.collection("itineraries").getDocuments { [weak self] snapshot, _ in
            guard let self = self else {
                completion()
                return
            }
            
            guard let itineraryDocs = snapshot?.documents else {
                completion()
                return
            }
            
            let group = DispatchGroup()
            
            for itineraryDoc in itineraryDocs {
                let itineraryID = itineraryDoc.documentID
                
                group.enter()
                // Delete user's like on this itinerary
                self.db.collection("itineraries").document(itineraryID)
                    .collection("likes").document(userID)
                    .delete { _ in group.leave() }
            }
            
            group.notify(queue: .main) {
                completion()
            }
        }
    }
    
    func logout() {
        try? Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
        // Clear all user-specific data when user logs out
        ItinerariesManager.shared.clearItineraries()
        LikedItinerariesManager.shared.clearLikes()
        SavedItinerariesManager.shared.clearSavedItineraries()
        CompletedItinerariesManager.shared.clearCompletedItineraries()
    }
    
    // MARK: - Private helpers
    
    @MainActor
    private func loadUser(uid: String, fallbackEmail: String? = nil) async {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                let name = data["name"] as? String ?? "Traveler"
                let handle = data["handle"] as? String ?? "@traveler"
                let email = data["email"] as? String ?? fallbackEmail ?? ""
                let profileImageURL = data["profileImageURL"] as? String
                let year = data["year"] as? String
                let streak = data["streak"] as? Int ?? 0
                let points = data["points"] as? Int ?? 0
                
                let user = User(
                    id: uid,
                    name: name,
                    email: email,
                    profileImageURL: profileImageURL,
                    year: year,
                    streak: streak,
                    points: points,
                    achievements: [],
                    handle: handle
                )
                self.currentUser = user
                self.isAuthenticated = true
                // Reload all data after loading user
                ItinerariesManager.shared.reloadItineraries()
                LikedItinerariesManager.shared.reloadLikes()
                SavedItinerariesManager.shared.reloadSavedItineraries()
                CompletedItinerariesManager.shared.reloadCompletedItineraries()
            } else {
                // If there's no user document yet, create a minimal one
                let email = fallbackEmail ?? Auth.auth().currentUser?.email ?? ""
                let name = "Traveler"
                let handle = "@traveler"
                
                let user = User(
                    id: uid,
                    name: name,
                    email: email,
                    profileImageURL: nil,
                    year: nil,
                    streak: 0,
                    points: 0,
                    achievements: [],
                    handle: handle
                )
                
                try await db.collection("users").document(uid).setData([
                    "name": name,
                    "handle": handle,
                    "email": email,
                    "streak": 0,
                    "points": 0,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                self.currentUser = user
                self.isAuthenticated = true
                // Reload all data after creating user document
                ItinerariesManager.shared.reloadItineraries()
                LikedItinerariesManager.shared.reloadLikes()
                SavedItinerariesManager.shared.reloadSavedItineraries()
                CompletedItinerariesManager.shared.reloadCompletedItineraries()
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
        }
    }
}

