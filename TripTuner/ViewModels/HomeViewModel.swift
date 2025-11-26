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
import Combine

class HomeViewModel: ObservableObject {
    @Published var itineraries: [Itinerary] = []
    private let itinerariesManager = ItinerariesManager.shared
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
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadItineraries()
        // Observe changes to shared manager
        itinerariesManager.$itineraries
            .sink { [weak self] newItineraries in
                self?.itineraries = newItineraries
            }
            .store(in: &cancellables)
    }
    
    func loadItineraries() {
        itineraries = itinerariesManager.itineraries
    }
    
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
        if isMapExpanded {
            // Reset to default state when collapsing
            selectedCategory = .all
        }
        isMapExpanded.toggle()
    }
    
    func refreshItineraries() {
        isLoading = true
        // Mock refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.itinerariesManager.loadItineraries()
            self.isLoading = false
        }
    }
}

