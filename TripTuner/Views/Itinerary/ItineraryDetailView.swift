//
//  ItineraryDetailView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI
import FirebaseAuth

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
                        
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.gray)
                        }
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
                        if !isCompleted {
                            completedManager.markCompleted(itinerary.id)
                        }
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
                    .padding(.vertical, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(itineraryID: itinerary.id, commentsViewModel: commentsViewModel)
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
    private var replyListeners: [String: ListenerRegistration] = [:]
    
    init(itineraryID: String) {
        self.itineraryID = itineraryID
        loadComments()
    }
    
    deinit {
        commentsListener?.remove()
        replyListeners.values.forEach { $0.remove() }
    }
    
    func loadComments() {
        isLoading = true
        
        // Load top-level comments (no parent) with real-time listener
        commentsListener = db.collection("itineraries").document(itineraryID)
            .collection("comments")
            .whereField("parentCommentID", isEqualTo: NSNull())
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
                    
                    var loadedComments: [Comment] = []
                    
                    for document in documents {
                        if let comment = self.commentFromFirestore(document) {
                            loadedComments.append(comment)
                            
                            // Set up real-time listener for replies
                            self.setupReplyListener(for: comment.id)
                        }
                    }
                    
                    self.comments = loadedComments
                }
            }
    }
    
    private func setupReplyListener(for parentID: String) {
        // Remove existing listener if any
        replyListeners[parentID]?.remove()
        
        // Set up real-time listener for replies
        let listener = db.collection("itineraries").document(itineraryID)
            .collection("comments")
            .whereField("parentCommentID", isEqualTo: parentID)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading replies: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                let replies = documents.compactMap { self.commentFromFirestore($0) }
                
                DispatchQueue.main.async {
                    if let index = self.comments.firstIndex(where: { $0.id == parentID }) {
                        self.comments[index].replies = replies
                    }
                }
            }
        
        replyListeners[parentID] = listener
    }
    
    private func loadReplies(for parentID: String, completion: @escaping ([Comment]) -> Void) {
        db.collection("itineraries").document(itineraryID)
            .collection("comments")
            .whereField("parentCommentID", isEqualTo: parentID)
            .order(by: "createdAt", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading replies: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let replies = documents.compactMap { self.commentFromFirestore($0) }
                completion(replies)
            }
    }
    
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
        let likes = data["likes"] as? Int ?? 0
        let dislikes = data["dislikes"] as? Int ?? 0
        let parentCommentID = data["parentCommentID"] as? String
        
        return Comment(
            id: document.documentID,
            authorID: authorID,
            authorName: authorName,
            authorHandle: authorHandle,
            authorProfileImageURL: authorProfileImageURL,
            itineraryID: itineraryID,
            content: content,
            likes: likes,
            dislikes: dislikes,
            createdAt: createdAtTimestamp.dateValue(),
            isLiked: false,
            isDisliked: false,
            replies: [],
            parentCommentID: parentCommentID
        )
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
                "likes": 0,
                "dislikes": 0,
                "createdAt": FieldValue.serverTimestamp(),
                "parentCommentID": NSNull()
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
    
    func addReply(to parentID: String, content: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        // Get user info from Firestore
        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            let authorName = snapshot?.data()?["name"] as? String ?? "User"
            let authorHandle = snapshot?.data()?["handle"] as? String ?? "@user"
            let authorProfileImageURL = snapshot?.data()?["profileImageURL"] as? String
            
            let replyData: [String: Any] = [
                "authorID": userID,
                "authorName": authorName,
                "authorHandle": authorHandle,
                "authorProfileImageURL": authorProfileImageURL ?? NSNull(),
                "itineraryID": self.itineraryID,
                "content": content,
                "likes": 0,
                "dislikes": 0,
                "createdAt": FieldValue.serverTimestamp(),
                "parentCommentID": parentID
            ]
            
            self.db.collection("itineraries").document(self.itineraryID)
                .collection("comments")
                .addDocument(data: replyData) { error in
                    if let error = error {
                        print("Error adding reply: \(error.localizedDescription)")
                    } else {
                        self.updateCommentCount()
                    }
                }
        }
    }
    
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
                                    .collection("comments")
                                    .whereField("parentCommentID", isEqualTo: commentID)
                                    .getDocuments { snapshot, error in
                                        if let documents = snapshot?.documents {
                                            for document in documents {
                                                document.reference.delete()
                                            }
                                        }
                                        self.updateCommentCount()
                                    }
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
        comments.count + comments.reduce(0) { $0 + $1.replies.count }
    }
}

struct CommentsView: View {
    let itineraryID: String
    @ObservedObject var commentsViewModel: CommentsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var newCommentText = ""
    @State private var replyingTo: Comment?
    @State private var replyText = ""
    
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
                                    commentsViewModel: commentsViewModel,
                                    onReply: { parentComment in
                                        replyingTo = parentComment
                                    }
                                )
                                .padding(.horizontal, 20)
                                
                                // Show replies
                                if !comment.replies.isEmpty {
                                    ForEach(comment.replies) { reply in
                                        CommentRowView(
                                            comment: reply,
                                            commentsViewModel: commentsViewModel,
                                            isReply: true
                                        )
                                        .padding(.leading, 60)
                                        .padding(.trailing, 20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                
                // Reply Input (if replying)
                if let parentComment = replyingTo {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Replying to \(parentComment.authorName)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                            Button("Cancel") {
                                replyingTo = nil
                                replyText = ""
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        
                        HStack(spacing: 12) {
                            TextField("Write a reply...", text: $replyText, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(1...4)
                            
                            Button(action: {
                                if !replyText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    commentsViewModel.addReply(to: parentComment.id, content: replyText)
                                    replyText = ""
                                    replyingTo = nil
                                }
                            }) {
                                Text("Reply")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(replyText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.pennRed)
                                    .cornerRadius(8)
                            }
                            .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                }
                
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
    let comment: Comment
    @ObservedObject var commentsViewModel: CommentsViewModel
    var isReply: Bool = false
    var onReply: ((Comment) -> Void)?
    @State private var isLiked = false
    @State private var isDisliked = false
    @State private var likeCount: Int
    @State private var dislikeCount: Int
    @State private var showDeleteAlert = false
    
    init(comment: Comment, commentsViewModel: CommentsViewModel, isReply: Bool = false, onReply: ((Comment) -> Void)? = nil) {
        self.comment = comment
        self.commentsViewModel = commentsViewModel
        self.isReply = isReply
        self.onReply = onReply
        _isLiked = State(initialValue: comment.isLiked)
        _isDisliked = State(initialValue: comment.isDisliked)
        _likeCount = State(initialValue: comment.likes)
        _dislikeCount = State(initialValue: comment.dislikes)
    }
    
    var canDelete: Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        return comment.authorID == currentUserID
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let profileImageURL = comment.authorProfileImageURL,
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(comment.authorName)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(comment.content)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack(spacing: 16) {
                    Text(comment.createdAt, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if !isReply, let onReply = onReply {
                        Button(action: {
                            onReply(comment)
                        }) {
                            Text("Reply")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if canDelete {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Text("Delete")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Button(action: {
                    if isDisliked {
                        isDisliked = false
                        likeCount += 1 // Restore the like count
                    }
                    isLiked.toggle()
                    if isLiked {
                        likeCount += 1
                    } else {
                        likeCount -= 1 // Allow negatives
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(isLiked ? .pennRed : .gray)
                }
                Text("\(likeCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Button(action: {
                    if isLiked {
                        isLiked = false
                        likeCount -= 1
                    }
                    isDisliked.toggle()
                    if isDisliked {
                        likeCount -= 1 // Decrease count, allow negatives
                    } else {
                        likeCount += 1 // Restore when un-downvoting
                    }
                }) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(isDisliked ? .blue : .gray)
                }
            }
        }
        .padding(.vertical, 8)
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                commentsViewModel.deleteComment(comment.id)
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
}

#Preview {
    ItineraryDetailView(itinerary: MockData.sampleItinerary)
}
