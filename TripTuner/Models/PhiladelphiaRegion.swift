//
//  PhiladelphiaRegion.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

enum PhiladelphiaRegion: String, Codable, CaseIterable {
    case all = "All Regions"
    case centerCity = "Center City"
    case universityCity = "University City"
    case fishtown = "Fishtown"
    case northernLiberties = "Northern Liberties"
    case oldCity = "Old City"
    case rittenhouse = "Rittenhouse"
    case southPhilly = "South Philly"
    case manayunk = "Manayunk"
    case fairmount = "Fairmount"
    
    var emoji: String {
        switch self {
        case .centerCity: return "🏙️"
        case .universityCity: return "🎓"
        case .fishtown: return "🐟"
        case .northernLiberties: return "🎨"
        case .oldCity: return "🏛️"
        case .rittenhouse: return "🌳"
        case .southPhilly: return "🍕"
        case .manayunk: return "🏔️"
        case .fairmount: return "🎨"
        case .all: return "📍"
        }
    }
}

