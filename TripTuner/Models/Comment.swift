//
//  Comment.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

struct Comment: Identifiable, Codable, Equatable {
    let id: String
    var authorID: String
    var authorName: String
    var authorHandle: String
    var authorProfileImageURL: String?
    var itineraryID: String
    var content: String
    var score: Int  // Single score: upvote +1, downvote -1
    var createdAt: Date
    var isLiked: Bool
    var isDisliked: Bool

    //var replies: [Comment]
    //var parentCommentID: String?
    
    init(id: String = UUID().uuidString,
         authorID: String,
         authorName: String,
         authorHandle: String,
         authorProfileImageURL: String? = nil,
         itineraryID: String,
         content: String,
         score: Int = 0,
         createdAt: Date = Date(),
         isLiked: Bool = false,
        isDisliked: Bool = false) {
         //replies: [Comment] = [],
         //parentCommentID: String? = nil) {
        self.id = id
        self.authorID = authorID
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.authorProfileImageURL = authorProfileImageURL
        self.itineraryID = itineraryID
        self.content = content
        self.score = score
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.isDisliked = isDisliked
//        self.replies = replies
//        self.parentCommentID = parentCommentID
    }
}

