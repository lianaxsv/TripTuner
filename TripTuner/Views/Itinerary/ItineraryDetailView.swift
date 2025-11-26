//
//  ItineraryDetailView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

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
                    // Hero Image
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pennRed.opacity(0.8), Color.pennBlue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 250)
                        
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
                            }
                            .padding(20)
                        }
                    }
                    
                    // Metadata Bar
                    HStack {
                        // Author
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
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
class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    var itineraryID: String
    
    init(itineraryID: String) {
        self.itineraryID = itineraryID
        loadComments()
    }
    
    func loadComments() {
        isLoading = true
        // Mock comments
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.comments = [
                Comment(
                    authorID: "1",
                    authorName: "John Doe",
                    authorHandle: "@johndoe",
                    itineraryID: self.itineraryID,
                    content: "This looks amazing! Can't wait to try it.",
                    likes: 12,
                    dislikes: 2,
                    createdAt: Date().addingTimeInterval(-7200)
                ),
                Comment(
                    authorID: "2",
                    authorName: "Jane Smith",
                    authorHandle: "@janesmith",
                    itineraryID: self.itineraryID,
                    content: "I did this last weekend and it was fantastic!",
                    likes: 8,
                    dislikes: 1,
                    createdAt: Date().addingTimeInterval(-3600)
                )
            ]
            self.isLoading = false
        }
    }
    
    func addComment(content: String) {
        let newComment = Comment(
            authorID: MockData.currentUserId,
            authorName: MockData.currentUser.username,
            authorHandle: MockData.currentUser.handle,
            itineraryID: itineraryID,
            content: content,
            likes: 0,
            dislikes: 0,
            createdAt: Date()
        )
        comments.insert(newComment, at: 0)
    }
    
    func addReply(to parentID: String, content: String) {
        if let parentIndex = comments.firstIndex(where: { $0.id == parentID }) {
            let reply = Comment(
                authorID: MockData.currentUserId,
                authorName: MockData.currentUser.username,
                authorHandle: MockData.currentUser.handle,
                itineraryID: itineraryID,
                content: content,
                likes: 0,
                dislikes: 0,
                createdAt: Date(),
                parentCommentID: parentID
            )
            comments[parentIndex].replies.append(reply)
        }
    }
    
    func deleteComment(_ commentID: String) {
        // Remove from main comments
        comments.removeAll { $0.id == commentID }
        // Remove from replies
        for index in comments.indices {
            comments[index].replies.removeAll { $0.id == commentID }
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
        comment.authorID == MockData.currentUserId
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
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
                        likeCount = max(0, likeCount + 1) // Restore the like count
                    }
                    isLiked.toggle()
                    if isLiked {
                        likeCount += 1
                    } else {
                        likeCount = max(0, likeCount - 1)
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
                        likeCount = max(0, likeCount - 1)
                    }
                    isDisliked.toggle()
                    if isDisliked {
                        likeCount = max(0, likeCount - 1) // Decrease upvote count by 1
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
