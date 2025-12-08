//
//  TimeEstimate.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

enum TimeEstimate: String, Codable, CaseIterable {
    case any = "Any"
    case short = "1-2 hours"
    case medium = "3-4 hours"
    case long = "5-6 hours"
    case veryLong = "7+ hours"
    
    var displayName: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .any: return "⏱️"
        case .short: return "🕐"
        case .medium: return "🕐"
        case .long: return "🕑"
        case .veryLong: return "🕒"
        }
    }
    
    func contains(_ hours: Int) -> Bool {
        switch self {
        case .any: return true
        case .short: return hours >= 1 && hours <= 2
        case .medium: return hours >= 3 && hours <= 4
        case .long: return hours >= 5 && hours <= 6
        case .veryLong: return hours >= 7
        }
    }
}

