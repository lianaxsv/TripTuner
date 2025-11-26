//
//  MockData.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import CoreLocation

struct MockData {
    static let currentUserId = "current-user-id"
    
    static let currentUser = User(
        id: currentUserId,
        username: "Alex Morgan",
        email: "alex@example.com",
        profileImageURL: nil,
        year: "2025",
        streak: 15,
        points: 2190,
        achievements: [
            Achievement(title: "Explorer", description: "Visited 5+ neighborhoods", emoji: "🏆", unlockedAt: Date()),
            Achievement(title: "Top Contributor", description: "Posted 10+ itineraries", emoji: "⭐", unlockedAt: Date()),
            Achievement(title: "Coffee Connoisseur", description: "Visited 10+ cafes", emoji: "☕", unlockedAt: Date()),
            Achievement(title: "Goal Crusher", description: "Completed 20+ trips", emoji: "🎯", unlockedAt: Date())
        ],
        handle: "@alexexplores"
    )
    
    static let sampleUsers = [
        User(username: "Sarah", email: "sarah@example.com", streak: 20, points: 2840, handle: "@sarahtravels"),
        User(username: "Emma", email: "emma@example.com", streak: 18, points: 2650, handle: "@emmawanders"),
        User(username: "Mike", email: "mike@example.com", streak: 15, points: 2410, handle: "@mikeexplores"),
        User(username: "Alex Kim", email: "alexkim@example.com", streak: 12, points: 2190, handle: "@alexadventures"),
        User(username: "Jordan Lee", email: "jordan@example.com", streak: 10, points: 1980, handle: "@jordanwanders"),
        User(username: "Taylor Martinez", email: "taylor@example.com", streak: 8, points: 1840, handle: "@taylortrips"),
        User(username: "Casey Brown", email: "casey@example.com", streak: 7, points: 1720, handle: "@caseycafe")
    ]
    
    static let sampleStops = [
        Stop(locationName: "Rittenhouse Square", address: "Rittenhouse Square, Philadelphia, PA", latitude: 39.9496, longitude: -75.1717, notes: "Start here for a beautiful park experience", order: 1),
        Stop(locationName: "South Street", address: "South Street, Philadelphia, PA", latitude: 39.9417, longitude: -75.1550, notes: "Eclectic shopping and dining", order: 2)
    ]
    
    static let sampleItinerary = Itinerary(
        title: "Rittenhouse Square to South Street",
        description: "Shop, dine, and explore from upscale Rittenhouse Square down to eclectic South Street.",
        category: .attractions,
        authorID: "1",
        authorName: "Amanda White",
        authorHandle: "@amandawhite",
        stops: sampleStops,
        photos: [],
        likes: 167,
        comments: 27,
        timeEstimate: 4,
        cost: 50.0
    )
    
    static let sampleItineraries: [Itinerary] = [
        Itinerary(
            title: "Rittenhouse Square to South Street",
            description: "Shop, dine, and explore from upscale Rittenhouse Square down to eclectic South Street.",
            category: .attractions,
            authorID: "1",
            authorName: "Amanda White",
            authorHandle: "@amandawhite",
            stops: sampleStops,
            photos: [],
            likes: 167,
            comments: 27,
            timeEstimate: 4,
            cost: 50.0,
            costLevel: .medium,
            noiseLevel: .moderate,
            region: .rittenhouse,
            isSaved: true
        ),
        Itinerary(
            title: "Best Coffee Shops in University City",
            description: "A caffeine-fueled journey through the best local roasters.",
            category: .cafes,
            authorID: "2",
            authorName: "John Doe",
            authorHandle: "@johndoe",
            stops: [
                Stop(locationName: "La Colombe", address: "130 S 19th St, Philadelphia, PA", latitude: 39.9500, longitude: -75.1700, order: 1),
                Stop(locationName: "Elixr Coffee", address: "207 S 15th St, Philadelphia, PA", latitude: 39.9480, longitude: -75.1650, order: 2)
            ],
            photos: [],
            likes: 89,
            comments: 12,
            timeEstimate: 2,
            cost: 20.0,
            costLevel: .low,
            noiseLevel: .quiet,
            region: .universityCity,
            isSaved: true
        ),
        Itinerary(
            title: "Foodie Tour of Fishtown",
            description: "Discover the best restaurants in this trendy neighborhood.",
            category: .restaurants,
            authorID: "3",
            authorName: "Jane Smith",
            authorHandle: "@janesmith",
            stops: [
                Stop(locationName: "Suraya", address: "1528 Frankford Ave, Philadelphia, PA", latitude: 39.9700, longitude: -75.1300, order: 1),
                Stop(locationName: "Pizzeria Beddia", address: "1313 N Lee St, Philadelphia, PA", latitude: 39.9680, longitude: -75.1280, order: 2)
            ],
            photos: [],
            likes: 234,
            comments: 45,
            timeEstimate: 3,
            cost: 60.0,
            costLevel: .high,
            noiseLevel: .loud,
            region: .fishtown,
            isSaved: true
        )
    ]
    
    static let leaderboardEntries: [LeaderboardEntry] = [
        LeaderboardEntry(user: sampleUsers[0], rank: 1, points: 2840, tripCount: 42, badgeEmoji: "⭐"),
        LeaderboardEntry(user: sampleUsers[1], rank: 2, points: 2650, tripCount: 38, badgeEmoji: "🍓"),
        LeaderboardEntry(user: sampleUsers[2], rank: 3, points: 2410, tripCount: 35, badgeEmoji: "⭐"),
        LeaderboardEntry(user: sampleUsers[3], rank: 4, points: 2190, tripCount: 35, badgeEmoji: "⭐"),
        LeaderboardEntry(user: sampleUsers[4], rank: 5, points: 1980, tripCount: 31, badgeEmoji: "🍓"),
        LeaderboardEntry(user: sampleUsers[5], rank: 6, points: 1840, tripCount: 28, badgeEmoji: "⭐"),
        LeaderboardEntry(user: sampleUsers[6], rank: 7, points: 1720, tripCount: 26, badgeEmoji: "☕")
    ]
    
    static let neighborhoods = ["Fishtown", "Old City", "Rittenhouse", "University City", "South Philly", "Northern Liberties", "Center City"]
    
    static let achievements = [
        Achievement(title: "Explorer", description: "Visited 5+ neighborhoods", emoji: "🏆", unlockedAt: Date()),
        Achievement(title: "Top Contributor", description: "Posted 10+ itineraries", emoji: "⭐", unlockedAt: Date()),
        Achievement(title: "Coffee Connoisseur", description: "Visited 10+ cafes", emoji: "☕", unlockedAt: Date()),
        Achievement(title: "Goal Crusher", description: "Completed 20+ trips", emoji: "🎯", unlockedAt: Date()),
        Achievement(title: "Foodie", description: "Visited 20+ restaurants", emoji: "🍽️"),
        Achievement(title: "Social Butterfly", description: "Received 100+ likes", emoji: "🦋")
    ]
}

