//
//  User.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    var username: String
    var email: String
    var profileImageURL: String?
    var year: String? // Penn graduation year
    var streak: Int
    var points: Int
    var achievements: [Achievement]
    var handle: String // @username
    
    init(id: String = UUID().uuidString, 
         username: String, 
         email: String, 
         profileImageURL: String? = nil, 
         year: String? = nil, 
         streak: Int = 0, 
         points: Int = 0, 
         achievements: [Achievement] = [],
         handle: String) {
        self.id = id
        self.username = username
        self.email = email
        self.profileImageURL = profileImageURL
        self.year = year
        self.streak = streak
        self.points = points
        self.achievements = achievements
        self.handle = handle
    }
}

