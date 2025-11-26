//
//  CostLevel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

enum CostLevel: String, Codable, CaseIterable {
    case free = "Free"
    case low = "$"
    case medium = "$$"
    case high = "$$$"
    
    var displayName: String {
        return rawValue
    }
    
    var numericValue: Double {
        switch self {
        case .free: return 0
        case .low: return 15
        case .medium: return 40
        case .high: return 75
        }
    }
    
    var description: String {
        switch self {
        case .free: return "Free"
        case .low: return "$ (Under $25)"
        case .medium: return "$$ ($25-$50)"
        case .high: return "$$$ (Over $50)"
        }
    }
}

enum NoiseLevel: Int, Codable, CaseIterable {
    case quiet = 1
    case moderate = 2
    case loud = 3
    case veryLoud = 4
    
    var displayName: String {
        switch self {
        case .quiet: return "Quiet"
        case .moderate: return "Moderate"
        case .loud: return "Loud"
        case .veryLoud: return "Very Loud"
        }
    }
    
    var emoji: String {
        switch self {
        case .quiet: return "🔇"
        case .moderate: return "🔉"
        case .loud: return "🔊"
        case .veryLoud: return "📢"
        }
    }
}

