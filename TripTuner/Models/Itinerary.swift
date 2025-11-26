//
//  Itinerary.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import CoreLocation

struct Itinerary: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var category: ItineraryCategory
    var authorID: String
    var authorName: String
    var authorHandle: String
    var authorProfileImageURL: String?
    var stops: [Stop]
    var photos: [String] // URLs
    var likes: Int
    var comments: Int
    var timeEstimate: Int // in hours
    var cost: Double?
    var costLevel: CostLevel?
    var noiseLevel: NoiseLevel?
    var region: PhiladelphiaRegion?
    var createdAt: Date
    var isLiked: Bool
    var isSaved: Bool
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         category: ItineraryCategory,
         authorID: String,
         authorName: String,
         authorHandle: String,
         authorProfileImageURL: String? = nil,
         stops: [Stop],
         photos: [String] = [],
         likes: Int = 0,
         comments: Int = 0,
         timeEstimate: Int,
         cost: Double? = nil,
         costLevel: CostLevel? = nil,
         noiseLevel: NoiseLevel? = nil,
         region: PhiladelphiaRegion? = nil,
         createdAt: Date = Date(),
         isLiked: Bool = false,
         isSaved: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.authorID = authorID
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.authorProfileImageURL = authorProfileImageURL
        self.stops = stops
        self.photos = photos
        self.likes = likes
        self.comments = comments
        self.timeEstimate = timeEstimate
        self.cost = cost
        self.costLevel = costLevel
        self.noiseLevel = noiseLevel
        self.region = region
        self.createdAt = createdAt
        self.isLiked = isLiked
        self.isSaved = isSaved
    }
}

enum ItineraryCategory: String, Codable, CaseIterable {
    case restaurants = "Restaurants"
    case cafes = "Cafes"
    case attractions = "Attractions"
    case all = "All"
    
    var emoji: String {
        switch self {
        case .restaurants: return "🍽️ "
        case .cafes: return "☕"
        case .attractions: return "🎯"
        case .all: return "📍"
        }
    }
    
    var pinColor: String {
        switch self {
        case .restaurants: return "red"
        case .cafes: return "yellow"
        case .attractions: return "blue"
        case .all: return "gray"
        }
    }
}

