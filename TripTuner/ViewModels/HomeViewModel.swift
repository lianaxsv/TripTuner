//
//  HomeViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

class HomeViewModel: ObservableObject {
    @Published var itineraries: [Itinerary] = MockData.sampleItineraries
    @Published var selectedCategory: ItineraryCategory = .all
    @Published var selectedItinerary: Itinerary?
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var isMapExpanded = false
    
    var topItinerariesOfWeek: [Itinerary] {
        // Sort by likes and take top 5
        Array(itineraries.sorted { $0.likes > $1.likes }.prefix(5))
    }
    
    var filteredItineraries: [Itinerary] {
        if selectedCategory == .all {
            return itineraries
        }
        return itineraries.filter { $0.category == selectedCategory }
    }
    
    func selectCategory(_ category: ItineraryCategory) {
        selectedCategory = category
    }
    
    func selectItinerary(_ itinerary: Itinerary) {
        selectedItinerary = itinerary
    }
    
    func toggleMapExpansion() {
        isMapExpanded.toggle()
    }
    
    func refreshItineraries() {
        isLoading = true
        // Mock refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.itineraries = MockData.sampleItineraries
            self.isLoading = false
        }
    }
}

