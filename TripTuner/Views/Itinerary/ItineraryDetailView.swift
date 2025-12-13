//
//  ItineraryDetailView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI
import FirebaseAuth
import Combine

struct ItineraryDetailView: View {
    let itinerary: Itinerary
    @Environment(\.dismiss) var dismiss
    @StateObject private var savedManager = SavedItinerariesManager.shared
    @StateObject private var completedManager = CompletedItinerariesManager.shared
    @StateObject private var likedManager = LikedItinerariesManager.shared
    @StateObject private var commentsViewModel: CommentsViewModel
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var showComments = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showFlagSheet = false
    @State private var showBlockConfirmation = false
    @StateObject private var moderationManager = ContentModerationManager.shared
    private let itinerariesManager = ItinerariesManager.shared
    
    init(itinerary: Itinerary) {
        self.itinerary = itinerary
        let likedManager = LikedItinerariesManager.shared
        let liked = likedManager.isLiked(itinerary.id)
        let count = likedManager.getLikeCount(for: itinerary.id, defaultCount: itinerary.likes)
        _isLiked = State(initialValue: liked)
        _likeCount = State(initialValue: count)
        _commentsViewModel = StateObject(wrappedValue: CommentsViewModel(itineraryID: itinerary.id))
    }
    
    var isSaved: Bool {
        savedManager.isSaved(itinerary.id)
    }
    
    var isCompleted: Bool {
        completedManager.isCompleted(itinerary.id)
    }
    
    var isAuthor: Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        return itinerary.authorID == currentUserID
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Image/Photos
                    ZStack {
                        if !itinerary.photos.isEmpty, 
                           let firstPhotoURL = itinerary.photos.first,
                           !firstPhotoURL.isEmpty,
                           let photoURL = URL(string: firstPhotoURL) {
                            AsyncImage(url: photoURL) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.pennRed.opacity(0.8), Color.pennBlue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.pennRed.opacity(0.8), Color.pennBlue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                @unknown default:
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.pennRed.opacity(0.8), Color.pennBlue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                            .frame(height: 250)
                            .clipped()
                        } else {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.pennRed.opacity(0.8), Color.pennBlue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 250)
                        }
                        
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(itinerary.title)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(itinerary.category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                Spacer()
                                
                                // Photo count indicator
                                if itinerary.photos.count > 1 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 12))
                                        Text("\(itinerary.photos.count)")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(20)
                        }
                    }
                    
                    // Metadata Bar
                    HStack {
                        // Author
                        HStack(spacing: 12) {
                            if let profileImageURL = itinerary.authorProfileImageURL,
                               !profileImageURL.isEmpty,
                               let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    @unknown default:
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(itinerary.authorName)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(itinerary.authorHandle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text(itinerary.createdAt, style: .relative)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    
                    // Engagement Metrics
                    HStack(spacing: 24) {
                        Button(action: {
                            let newCount = likedManager.toggleLike(itinerary.id, currentCount: likeCount)
                            isLiked = likedManager.isLiked(itinerary.id)
                            likeCount = newCount
                            // Update the itinerary in the manager
                            ItinerariesManager.shared.updateLikeCount(for: itinerary.id, newCount: newCount)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .foregroundColor(isLiked ? .pennRed : .gray)
                                Text("\(likeCount)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        
                        Button(action: {
                            showComments = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.gray)
                                Text("\(commentsViewModel.totalCommentCount)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        
                        Button(action: {
                            savedManager.toggleSave(itinerary.id)
                        }) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isSaved ? .pennRed : .gray)
                        }
                        
                        Spacer()
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Divider()
                    
                    // Trip Information
                    VStack(alignment: .leading, spacing: 20) {
                        Text(itinerary.description)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Stats
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("\(itinerary.timeEstimate) hours")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            if let costLevel = itinerary.costLevel {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Cost")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text(costLevel.displayName)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            
                            if let noiseLevel = itinerary.noiseLevel {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Noise")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    HStack(spacing: 4) {
                                        Text(noiseLevel.emoji)
                                        Text(noiseLevel.displayName)
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Photo Gallery
                        if !itinerary.photos.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Photos")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(itinerary.photos.filter { !$0.isEmpty }, id: \.self) { photoURLString in
                                            if let photoURL = URL(string: photoURLString) {
                                                AsyncImage(url: photoURL) { phase in
                                                    switch phase {
                                                    case .empty:
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .overlay(
                                                                ProgressView()
                                                            )
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    case .failure:
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.3))
                                                            .overlay(
                                                                Image(systemName: "photo")
                                                                    .foregroundColor(.gray)
                                                            )
                                                    @unknown default:
                                                        Rectangle()
                                                            .fill(Color.gray.opacity(0.3))
                                                    }
                                                }
                                                .frame(width: 200, height: 150)
                                                .cornerRadius(12)
                                                .clipped()
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 20)
                        }
                        
                        // Timeline
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Timeline")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.horizontal, 20)
                            
                            ForEach(Array(itinerary.stops.enumerated()), id: \.element.id) { index, stop in
                                TimelineStopView(stop: stop, index: index, isLast: index == itinerary.stops.count - 1)
                            }
                        }
                        .padding(.top, 20)
                    }
                    
                    // I Did This Trip Button
                    Button(action: {
                        completedManager.toggleCompleted(itinerary.id)
                    }) {
                        Text(isCompleted ? "✓ Completed This Trip!" : "I Did This Trip!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isCompleted ? Color.green : Color.pennRed)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Delete Button (only for author)
                    if isAuthor {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Itinerary")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .disabled(isDeleting)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    } else {
                        // Add bottom padding if no delete button
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isAuthor {
                        Menu {
                            Button(role: .destructive, action: {
                                showFlagSheet = true
                            }) {
                                Label("Report Content", systemImage: "flag")
                            }
                            
                            Button(role: .destructive, action: {
                                showBlockConfirmation = true
                            }) {
                                Label("Block User", systemImage: "person.crop.circle.badge.xmark")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("⚠️ Delete Itinerary", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Forever", role: .destructive) {
                    deleteItinerary()
                }
            } message: {
                Text("WARNING: This action cannot be undone!\n\nDeleting this itinerary will permanently remove:\n• The itinerary itself\n• All comments and replies\n• All likes and votes\n• All associated data\n\nAre you absolutely sure you want to delete this itinerary?")
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(itineraryID: itinerary.id, commentsViewModel: commentsViewModel)
        }
        .sheet(isPresented: $showFlagSheet) {
            FlagContentSheet(
                contentType: .itinerary,
                contentID: itinerary.id,
                itineraryID: itinerary.id,
                onFlagSubmitted: {
                    showFlagSheet = false
                }
            )
        }
        .alert("Block User", isPresented: $showBlockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                moderationManager.blockUser(
                    itinerary.authorID,
                    userName: itinerary.authorName,
                    userHandle: itinerary.authorHandle
                )
                // Dismiss the view after blocking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to block \(itinerary.authorName)? You won't see their content anymore, and they won't be able to see yours.")
        }
        .sheet(isPresented: $showFlagSheet) {
            FlagContentSheet(
                contentType: .itinerary,
                contentID: itinerary.id,
                itineraryID: itinerary.id,
                onFlagSubmitted: {
                    showFlagSheet = false
                }
            )
        }
        .alert("Block User", isPresented: $showBlockConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                moderationManager.blockUser(
                    itinerary.authorID,
                    userName: itinerary.authorName,
                    userHandle: itinerary.authorHandle
                )
                // Dismiss the view after blocking
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to block \(itinerary.authorName)? You won't see their content anymore, and they won't be able to see yours.")
        }
    }
    
    private func deleteItinerary() {
        isDeleting = true
        itinerariesManager.deleteItinerary(itinerary.id) { success, error in
            DispatchQueue.main.async {
                self.isDeleting = false
                if let error = error {
                    print("Error deleting itinerary: \(error.localizedDescription)")
                    // You could show an error alert here if needed
                } else if success {
                    // Dismiss the view after successful deletion
                    self.dismiss()
                }
            }
        }
    }
}

struct TimelineStopView: View {
    let stop: Stop
    let index: Int
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.pennRed)
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            
            // Stop content
            VStack(alignment: .leading, spacing: 8) {
                Text(stop.locationName)
                    .font(.system(size: 18, weight: .semibold))
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(stop.address)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                if let notes = stop.notes {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Comments View
import FirebaseFirestore
import FirebaseAuth

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    var itineraryID: String
    
    private let db = Firestore.firestore()
    private var commentsListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private var allComments: [Comment] = [] // Store unfiltered comments
//    private var replyListeners: [String: ListenerRegistration] = [:]
    
    init(itineraryID: String) {
        self.itineraryID = itineraryID
        loadComments()
        // Observe blocked users changes and re-filter
        ContentModerationManager.shared.$blockedUserIDs
            .sink { [weak self] _ in
                self?.applyBlockedUsersFilter()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        commentsListener?.remove()
//        replyListeners.values.forEach { $0.remove() }
    }
    
    func loadComments() {
        isLoading = true
        
        // Load top-level comments (no parent) with real-time listener
        commentsListener = db.collection("itineraries").document(itineraryID)
            .collection("comments")
//            .whereField("parentCommentID", isEqualTo: NSNull())
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error loading comments: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.comments = []
                        return
                    }
                    
                    // Preserve existing vote states for current user
                    let existingCommentsByID = Dictionary(uniqueKeysWithValues: self.comments.map { ($0.id, $0) })
                    
                    var loadedComments: [Comment] = []
                    let group = DispatchGroup()
                    
                    guard let currentUserID = Auth.auth().currentUser?.uid else {
                        // If no user, just load comments without vote states
                        for document in documents {
                            if let comment = self.commentFromFirestore(document) {
                                loadedComments.append(comment)
                            }
                        }
                        // Store unfiltered comments
                        self.allComments = loadedComments
                        self.applyBlockedUsersFilter()
                        return
                    }
                    
                    for document in documents {
                        if let comment = self.commentFromFirestore(document) {
                            var commentWithVote = comment
                            
                            // CRITICAL: Always use score from Firestore (shared across all users)
                            // The score in commentFromFirestore is already from Firestore - never override it
                            
                            // Preserve only the user's personal vote state (isLiked/isDisliked)
                            if let existingComment = existingCommentsByID[comment.id] {
                                commentWithVote.isLiked = existingComment.isLiked
                                commentWithVote.isDisliked = existingComment.isDisliked
                                // Score MUST come from Firestore (already set correctly in commentFromFirestore)
                                // Do NOT use existingComment.score - always use the score from Firestore
                                loadedComments.append(commentWithVote)
                            } else {
                                // Load vote state for new comment
                                group.enter()
                                self.loadUserVoteForComment(commentID: comment.id, userID: currentUserID) { isLiked, isDisliked in
                                    commentWithVote.isLiked = isLiked
                                    commentWithVote.isDisliked = isDisliked
                                    // Score from Firestore (already set in commentFromFirestore) - this is the source of truth
                                    loadedComments.append(commentWithVote)
                                    group.leave()
                                }
                            }
                        }
                    }
                    
                    group.notify(queue: .main) {
                        // Store unfiltered comments
                        self.allComments = loadedComments
                        self.applyBlockedUsersFilter()
                    }
                }
            }
    }
    
//    private func setupReplyListener(for parentID: String) {
//        // Remove existing listener if any
//        replyListeners[parentID]?.remove()
//        
//        // Set up real-time listener for replies
//        let listener = db.collection("itineraries").document(itineraryID)
//            .collection("comments")
//            .whereField("parentCommentID", isEqualTo: parentID)
//            .order(by: "createdAt", descending: false)
//            .addSnapshotListener { [weak self] snapshot, error in
//                guard let self = self else { return }
//                
//                if let error = error {
//                    print("Error loading replies: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else {
//                    // If no documents, set empty replies array
//                    DispatchQueue.main.async {
//                        guard let index = self.comments.firstIndex(where: { $0.id == parentID }),
//                              !self.comments[index].replies.isEmpty else {
//                            return
//                        }
//                        
//                        var updatedComment = self.comments[index]
//                        updatedComment.replies = []
//                        
//                        // Create a completely new array
//                        var updatedComments: [Comment] = []
//                        for (i, comment) in self.comments.enumerated() {
//                            if i == index {
//                                updatedComments.append(updatedComment)
//                            } else {
//                                updatedComments.append(comment)
//                            }
//                        }
//                        self.comments = updatedComments
//                    }
//                    return
//                }
//                
//                let replies = documents.compactMap { self.commentFromFirestore($0) }
//                
//                DispatchQueue.main.async {
//                    guard let index = self.comments.firstIndex(where: { $0.id == parentID }) else {
//                        return
//                    }
//                    
//                    // Create a new comment with updated replies to ensure SwiftUI detects the change
//                    var updatedComment = self.comments[index]
//                    updatedComment.replies = replies
//                    
//                    // Create a completely new array to trigger SwiftUI's change detection
//                    var updatedComments: [Comment] = []
//                    for (i, comment) in self.comments.enumerated() {
//                        if i == index {
//                            updatedComments.append(updatedComment)
//                        } else {
//                            updatedComments.append(comment)
//                        }
//                    }
//                    self.comments = updatedComments
//                    self.objectWillChange.send()  // <-- ADD THIS FIX
//                }
//            }
//        
//        replyListeners[parentID] = listener
//    }
//    
//    private func loadReplies(for parentID: String, completion: @escaping ([Comment]) -> Void) {
//        db.collection("itineraries").document(itineraryID)
//            .collection("comments")
//            .whereField("parentCommentID", isEqualTo: parentID)
//            .order(by: "createdAt", descending: false)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error loading replies: \(error.localizedDescription)")
//                    completion([])
//                    return
//                }
//                
//                guard let documents = snapshot?.documents else {
//                    completion([])
//                    return
//                }
//                
//                let replies = documents.compactMap { self.commentFromFirestore($0) }
//                completion(replies)
//            }
//    }
    
    private func commentFromFirestore(_ document: QueryDocumentSnapshot) -> Comment? {
        let data = document.data()
        
        guard let authorID = data["authorID"] as? String,
              let authorName = data["authorName"] as? String,
              let authorHandle = data["authorHandle"] as? String,
              let content = data["content"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        let authorProfileImageURLString = data["authorProfileImageURL"] as? String
        let authorProfileImageURL = (authorProfileImageURLString?.isEmpty == false) ? authorProfileImageURLString : nil
        // Use score if available, otherwise calculate from likes/dislikes for backward compatibility
        let score = data["score"] as? Int ?? ((data["likes"] as? Int ?? 0) - (data["dislikes"] as? Int ?? 0))
//        let parentCommentID = data["parentCommentID"] as? String
        
        let commentID = document.documentID
        
        // Vote states will be loaded separately in loadComments
        return Comment(
            id: commentID,
            authorID: authorID,
            authorName: authorName,
            authorHandle: authorHandle,
            authorProfileImageURL: authorProfileImageURL,
            itineraryID: itineraryID,
            content: content,
            score: score,
            createdAt: createdAtTimestamp.dateValue(),
            isLiked: false,
            isDisliked: false
//            replies: [],
//            parentCommentID: parentCommentID
        )
    }
    
    private func loadUserVoteForComment(commentID: String, userID: String, completion: @escaping (Bool, Bool) -> Void) {
        db.collection("itineraries").document(itineraryID)
            .collection("comments").document(commentID)
            .collection("votes").document(userID)
            .getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let voteType = data["type"] as? String {
                    completion(voteType == "like", voteType == "dislike")
                } else {
                    completion(false, false)
                }
            }
    }
    
    func toggleCommentLike(commentID: String, isCurrentlyLiked: Bool, isCurrentlyDisliked: Bool, currentScore: Int) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let commentRef = db.collection("itineraries").document(itineraryID)
            .collection("comments").document(commentID)
        let voteRef = commentRef.collection("votes").document(userID)
        
        if isCurrentlyLiked {
            // Unlike: remove vote (decrease score by 1)
            voteRef.delete { error in
                if error == nil {
                    commentRef.updateData([
                        "score": FieldValue.increment(Int64(-1))
                    ]) { error in
                        if let error = error {
                            print("Error updating score: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Error removing like vote: \(error!.localizedDescription)")
                }
            }
        } else {
            // Like: add/update vote
            let voteData: [String: Any] = ["type": "like", "votedAt": FieldValue.serverTimestamp()]
            
            if isCurrentlyDisliked {
                // If currently disliked, change to like (increase score by 2: +1 for like, +1 to undo dislike)
                voteRef.setData(voteData) { error in
                    if error == nil {
                        commentRef.updateData([
                            "score": FieldValue.increment(Int64(2))
                        ]) { error in
                            if let error = error {
                                print("Error updating score: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Error setting like vote: \(error!.localizedDescription)")
                    }
                }
            } else {
                // New like (increase score by 1)
                voteRef.setData(voteData) { error in
                    if error == nil {
                        commentRef.updateData([
                            "score": FieldValue.increment(Int64(1))
                        ]) { error in
                            if let error = error {
                                print("Error updating score: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Error setting like vote: \(error!.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func toggleCommentDislike(commentID: String, isCurrentlyLiked: Bool, isCurrentlyDisliked: Bool, currentScore: Int) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let commentRef = db.collection("itineraries").document(itineraryID)
            .collection("comments").document(commentID)
        let voteRef = commentRef.collection("votes").document(userID)
        
        if isCurrentlyDisliked {
            // Undislike: remove vote (increase score by 1)
            voteRef.delete { error in
                if error == nil {
                    commentRef.updateData([
                        "score": FieldValue.increment(Int64(1))
                    ]) { error in
                        if let error = error {
                            print("Error updating score: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("Error removing dislike vote: \(error!.localizedDescription)")
                }
            }
        } else {
            // Dislike: add/update vote
            let voteData: [String: Any] = ["type": "dislike", "votedAt": FieldValue.serverTimestamp()]
            
            if isCurrentlyLiked {
                // If currently liked, change to dislike (decrease score by 2: -1 for dislike, -1 to undo like)
                voteRef.setData(voteData) { error in
                    if error == nil {
                        commentRef.updateData([
                            "score": FieldValue.increment(Int64(-2))
                        ]) { error in
                            if let error = error {
                                print("Error updating score: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Error setting dislike vote: \(error!.localizedDescription)")
                    }
                }
            } else {
                // New dislike (decrease score by 1)
                voteRef.setData(voteData) { error in
                    if error == nil {
                        commentRef.updateData([
                            "score": FieldValue.increment(Int64(-1))
                        ]) { error in
                            if let error = error {
                                print("Error updating score: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Error setting dislike vote: \(error!.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func updateCommentVoteState(commentID: String, isLiked: Bool, isDisliked: Bool, score: Int) {
        // Update vote state optimistically for immediate UI feedback
        // Score will eventually be synced by real-time listener from Firestore (shared across all users)
        // But we update it optimistically here so the UI responds immediately
        if let index = comments.firstIndex(where: { $0.id == commentID }) {
            var updatedComment = comments[index]
            updatedComment.isLiked = isLiked
            updatedComment.isDisliked = isDisliked
            updatedComment.score = score // Update score optimistically for immediate feedback
            comments[index] = updatedComment
        }
    }
    
    func addComment(content: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get user info from Firestore
        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            let authorName = snapshot?.data()?["name"] as? String ?? "User"
            let authorHandle = snapshot?.data()?["handle"] as? String ?? "@user"
            let authorProfileImageURL = snapshot?.data()?["profileImageURL"] as? String
            
            let commentData: [String: Any] = [
                "authorID": userID,
                "authorName": authorName,
                "authorHandle": authorHandle,
                "authorProfileImageURL": authorProfileImageURL ?? NSNull(),
                "itineraryID": self.itineraryID,
                "content": content,
                "score": 0,
                "createdAt": FieldValue.serverTimestamp(),
//                "parentCommentID": NSNull()
            ]
            
            self.db.collection("itineraries").document(self.itineraryID)
                .collection("comments")
                .addDocument(data: commentData) { error in
                    if let error = error {
                        print("Error adding comment: \(error.localizedDescription)")
                    } else {
                        // Update comment count on itinerary
                        self.updateCommentCount()
                    }
                }
        }
    }
    
//    func addReply(to parentID: String, content: String) {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            return
//        }
//        
//        // Get user info from Firestore
//        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
//            guard let self = self else { return }
//            
//            let authorName = snapshot?.data()?["name"] as? String ?? "User"
//            let authorHandle = snapshot?.data()?["handle"] as? String ?? "@user"
//            let authorProfileImageURL = snapshot?.data()?["profileImageURL"] as? String
//            
//            let replyData: [String: Any] = [
//                "authorID": userID,
//                "authorName": authorName,
//                "authorHandle": authorHandle,
//                "authorProfileImageURL": authorProfileImageURL ?? NSNull(),
//                "itineraryID": self.itineraryID,
//                "content": content,
//                "likes": 0,
//                "dislikes": 0,
//                "createdAt": FieldValue.serverTimestamp(),
//                "parentCommentID": parentID
//            ]
//            
//            self.db.collection("itineraries").document(self.itineraryID)
//                .collection("comments")
//                .addDocument(data: replyData) { error in
//                    if let error = error {
//                        print("Error adding reply: \(error.localizedDescription)")
//                    } else {
//                        self.updateCommentCount()
//                    }
//                }
//        }
//    }
    
    func deleteComment(_ commentID: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Check if user owns the comment
        db.collection("itineraries").document(itineraryID)
            .collection("comments").document(commentID).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let data = snapshot?.data(),
                   let authorID = data["authorID"] as? String,
                   authorID == userID {
                    // Delete the comment
                    self.db.collection("itineraries").document(self.itineraryID)
                        .collection("comments").document(commentID).delete { error in
                            if let error = error {
                                print("Error deleting comment: \(error.localizedDescription)")
                            } else {
                                // Also delete any replies
                                self.db.collection("itineraries").document(self.itineraryID)
//                                    .collection("comments")
//                                    .whereField("parentCommentID", isEqualTo: commentID)
//                                    .getDocuments { snapshot, error in
//                                        if let documents = snapshot?.documents {
//                                            for document in documents {
//                                                document.reference.delete()
//                                            }
//                                        }
//                                        self.updateCommentCount()
//                                    }
                            }
                        }
                }
            }
    }
    
    private func updateCommentCount() {
        db.collection("itineraries").document(itineraryID)
            .collection("comments")
            .getDocuments { snapshot, error in
                if let count = snapshot?.documents.count {
                    self.db.collection("itineraries").document(self.itineraryID)
                        .updateData(["comments": count]) { error in
                            if let error = error {
                                print("Error updating comment count: \(error.localizedDescription)")
                            }
                        }
                }
            }
    }
    
    var totalCommentCount: Int {
        comments.count
//        + comments.reduce(0) { $0 + $1.replies.count }
    }
    
    // Apply blocked users filter to existing comments
    private func applyBlockedUsersFilter() {
        let moderationManager = ContentModerationManager.shared
        let filteredComments = moderationManager.filterBlockedContent(
            allComments,
            authorIDKeyPath: \.authorID
        )
        // Sort comments to maintain order
        let sortedComments = filteredComments.sorted { $0.createdAt > $1.createdAt }
        self.comments = sortedComments
    }
}

struct CommentsView: View {
    let itineraryID: String
    @ObservedObject var commentsViewModel: CommentsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newCommentText = ""
//    @State private var replyingTo: Comment?
//    @State private var replyText = ""
//    @FocusState private var isReplyFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if commentsViewModel.comments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No comments yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("Be the first to comment!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(commentsViewModel.comments) { comment in
                                CommentRowView(
                                    comment: comment,
                                    commentsViewModel: commentsViewModel
//                                    onReply: { parentComment in
//                                        replyingTo = parentComment
//                                        isReplyFieldFocused = true
//                                    }
                                )
                                .id(comment.id)
                                .padding(.horizontal, 20)
                                
                                // Show replies
//                                if !comment.replies.isEmpty {
//                                    ForEach(comment.replies) { reply in
//                                        CommentRowView(
//                                            comment: reply,
//                                            commentsViewModel: commentsViewModel,
//                                            isReply: true
//                                        )
//                                        .padding(.leading, 60)
//                                        .padding(.trailing, 20)
//                                    }
//                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                
                // Reply Input (if replying)
//                if let parentComment = replyingTo {
//                    VStack(spacing: 8) {
//                        HStack {
//                            Text("Replying to \(parentComment.authorName)")
//                                .font(.system(size: 12))
//                                .foregroundColor(.gray)
//                            Spacer()
//                            Button("Cancel") {
//                                replyingTo = nil
//                                replyText = ""
//                                isReplyFieldFocused = false
//                            }
//                            .font(.system(size: 12))
//                            .foregroundColor(.blue)
//                        }
//                        .padding(.horizontal, 16)
//                        
//                        HStack(spacing: 12) {
//                            TextField("Write a reply...", text: $replyText, axis: .vertical)
//                                .textFieldStyle(.roundedBorder)
//                                .lineLimit(1...4)
//                                .focused($isReplyFieldFocused)
//                            
//                            Button(action: {
//                                if !replyText.trimmingCharacters(in: .whitespaces).isEmpty {
//                                    commentsViewModel.addReply(to: parentComment.id, content: replyText)
//                                    replyText = ""
//                                    replyingTo = nil
//                                    isReplyFieldFocused = false
//                                }
//                            }) {
//                                Text("Reply")
//                                    .font(.system(size: 16, weight: .semibold))
//                                    .foregroundColor(.white)
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 10)
//                                    .background(replyText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.pennRed)
//                                    .cornerRadius(8)
//                            }
//                            .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
//                        }
//                        .padding(.horizontal, 16)
//                    }
//                    .padding(.vertical, 8)
//                    .background(Color.gray.opacity(0.05))
//                }
                
                // Comment Input
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    
                    Button(action: {
                        if !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty {
                            commentsViewModel.addComment(content: newCommentText)
                            newCommentText = ""
                        }
                    }) {
                        Text("Post")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.pennRed)
                            .cornerRadius(8)
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CommentRowView: View {
    let commentID: String
    @ObservedObject var commentsViewModel: CommentsViewModel
    @State private var isLiked = false
    @State private var isDisliked = false
    @State private var score: Int = 0
    @State private var showDeleteAlert = false
    @State private var showFlagSheet = false
    @State private var showBlockConfirmation = false
    @State private var authorName: String = ""
    @State private var content: String = ""
    @State private var authorProfileImageURL: String? = nil
    @State private var createdAt: Date = Date()
    @State private var authorID: String = ""
    @State private var authorHandle: String = ""
    @StateObject private var moderationManager = ContentModerationManager.shared
    
    // Get the current comment from the view model (always up-to-date)
    private var comment: Comment? {
        commentsViewModel.comments.first(where: { $0.id == commentID })
    }
    
    init(comment: Comment, commentsViewModel: CommentsViewModel) {
        self.commentID = comment.id
        self.commentsViewModel = commentsViewModel
        _isLiked = State(initialValue: comment.isLiked)
        _isDisliked = State(initialValue: comment.isDisliked)
        _score = State(initialValue: comment.score)
        _authorName = State(initialValue: comment.authorName)
        _content = State(initialValue: comment.content)
        _authorProfileImageURL = State(initialValue: comment.authorProfileImageURL)
        _createdAt = State(initialValue: comment.createdAt)
        _authorID = State(initialValue: comment.authorID)
        _authorHandle = State(initialValue: comment.authorHandle)
    }
    
    private var canDelete: Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        return authorID == currentUserID
    }
    
    private var canModerate: Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        return authorID != currentUserID
    }
    
    private var profileImageView: some View {
        Group {
            if let profileImageURL = authorProfileImageURL,
               !profileImageURL.isEmpty,
               let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    @unknown default:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }
        }
    }
    
    private var commentContentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(authorName)
                .font(.system(size: 14, weight: .semibold))
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                Text(createdAt, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                if canDelete {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text("Delete")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                
                if canModerate {
                    Menu {
                        Button(role: .destructive, action: {
                            showFlagSheet = true
                        }) {
                            Label("Report", systemImage: "flag")
                        }
                        
                        Button(role: .destructive, action: {
                            showBlockConfirmation = true
                        }) {
                            Label("Block User", systemImage: "person.crop.circle.badge.xmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    private var votingButtons: some View {
        VStack(spacing: 4) {
            Button(action: {
                handleUpvote()
            }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12))
                    .foregroundColor(isLiked ? .pennRed : .gray)
            }
            Text("\(score)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Button(action: {
                handleDownvote()
            }) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 12))
                    .foregroundColor(isDisliked ? .blue : .gray)
            }
        }
    }
    
    private func handleUpvote() {
        let wasLiked = isLiked
        let wasDisliked = isDisliked
        
        // Update local vote state immediately for UI responsiveness
        if isDisliked {
            isDisliked = false
            score += 1 // Undo dislike
        }
        isLiked.toggle()
        
        // Update score optimistically for immediate feedback
        if isLiked {
            score += 1 // Add like
        } else {
            score -= 1 // Remove like
        }
        
        // Save to Firestore - real-time listener will sync with other users
        commentsViewModel.toggleCommentLike(
            commentID: commentID,
            isCurrentlyLiked: wasLiked,
            isCurrentlyDisliked: wasDisliked,
            currentScore: score
        )
        
        // Update comment vote state in view model
        commentsViewModel.updateCommentVoteState(
            commentID: commentID,
            isLiked: isLiked,
            isDisliked: isDisliked,
            score: score
        )
    }
    
    private func handleDownvote() {
        let wasLiked = isLiked
        let wasDisliked = isDisliked
        
        // Update local vote state immediately for UI responsiveness
        if isLiked {
            isLiked = false
            score -= 1 // Undo like
        }
        isDisliked.toggle()
        
        // Update score optimistically for immediate feedback
        if isDisliked {
            score -= 1 // Add dislike
        } else {
            score += 1 // Remove dislike
        }
        
        // Save to Firestore - real-time listener will sync with other users
        commentsViewModel.toggleCommentDislike(
            commentID: commentID,
            isCurrentlyLiked: wasLiked,
            isCurrentlyDisliked: wasDisliked,
            currentScore: score
        )
        
        // Update comment vote state in view model
        commentsViewModel.updateCommentVoteState(
            commentID: commentID,
            isLiked: isLiked,
            isDisliked: isDisliked,
            score: score
        )
    }
    
    private func updateFromComment(_ comment: Comment) {
        score = comment.score
        isLiked = comment.isLiked
        isDisliked = comment.isDisliked
        authorName = comment.authorName
        content = comment.content
        authorProfileImageURL = comment.authorProfileImageURL
        createdAt = comment.createdAt
        authorID = comment.authorID
        authorHandle = comment.authorHandle
    }
    
    private var mainContentView: some View {
        HStack(alignment: .top, spacing: 12) {
            profileImageView
            commentContentView
            Spacer()
            votingButtons
        }
        .padding(.vertical, 8)
    }
    
    var body: some View {
        mainContentView
            .onChange(of: commentsViewModel.comments) { _, newValue in
                if let updatedComment = newValue.first(where: { $0.id == commentID }) {
                    // Always sync from view model - it has the most up-to-date state
                    // (either optimistic or from Firestore real-time listener)
                    updateFromComment(updatedComment)
                }
            }
            .onAppear {
                if let initialComment = comment {
                    updateFromComment(initialComment)
                }
            }
            .alert("Delete Comment", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    commentsViewModel.deleteComment(commentID)
                }
            } message: {
                Text("Are you sure you want to delete this comment?")
            }
            .sheet(isPresented: $showFlagSheet) {
                FlagContentSheet(
                    contentType: .comment,
                    contentID: commentID,
                    itineraryID: commentsViewModel.itineraryID,
                    onFlagSubmitted: {
                        showFlagSheet = false
                    }
                )
            }
            .alert("Block User", isPresented: $showBlockConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Block", role: .destructive) {
                    moderationManager.blockUser(
                        authorID,
                        userName: authorName,
                        userHandle: authorHandle
                    )
                }
            } message: {
                Text("Are you sure you want to block \(authorName)? You won't see their content anymore, and they won't be able to see yours.")
            }
    }
}

// MARK: - Flag Content Sheet
struct FlagContentSheet: View {
    let contentType: ContentType
    let contentID: String
    let itineraryID: String
    let onFlagSubmitted: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: FlagReason?
    @State private var additionalInfo: String = ""
    @State private var isSubmitting = false
    private let moderationManager = ContentModerationManager.shared
    
    enum ContentType {
        case itinerary
        case comment
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Help us understand what's wrong with this content. Your report is anonymous.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Section("Reason for Reporting") {
                    ForEach(FlagReason.allCases, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reason.rawValue)
                                        .foregroundColor(.primary)
                                    Text(reason.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.pennRed)
                                }
                            }
                        }
                    }
                }
                
                if selectedReason != nil {
                    Section("Additional Information (Optional)") {
                        TextField("Provide more details...", text: $additionalInfo, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitFlag()
                    }
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
        }
    }
    
    private func submitFlag() {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        
        if contentType == .itinerary {
            moderationManager.flagItinerary(
                contentID,
                reason: reason,
                additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo
            )
        } else {
            moderationManager.flagComment(
                contentID,
                itineraryID: itineraryID,
                reason: reason,
                additionalInfo: additionalInfo.isEmpty ? nil : additionalInfo
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            onFlagSubmitted()
            dismiss()
        }
    }
}

#Preview {
    ItineraryDetailView(itinerary: MockData.sampleItinerary)
}
