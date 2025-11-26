//
//  Comment.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    var authorID: String
    var authorName: String
    var authorHandle: String
    var authorProfileImageURL: String?
    var itineraryID: String
    var content: String
    var likes: Int
    var createdAt: Date
    var isLiked: Bool
    var replies: [Comment]
    var parentCommentID: String?
    
    init(id: String = UUID().uuidString,
         authorID: String,
         authorName: String,
         authorHandle: String,
         authorProfileImageURL: String? = nil,
         itineraryID: String,
         content: String,
         likes: Int = 0,
         createdAt: Date = Date(),
         isLiked: Bool = false,
         replies: [Comment] = [],
         parentCommentID: String? = nil) {
        self.id = id
        self.authorID = authorID
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.authorProfileImageURL = authorProfileImageURL
        self.itineraryID = itineraryID
        self.content = content
        self.likes = likes
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.replies = replies
        self.parentCommentID = parentCommentID
    }
}

