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
    @Published var selectedRegion: PhiladelphiaRegion = .all
    @Published var selectedCostLevel: CostLevel?
    @Published var selectedNoiseLevel: NoiseLevel?
    @Published var selectedTimeEstimate: TimeEstimate?
    @Published var selectedItinerary: Itinerary?
    // Default Philadelphia region - always reset to this
    private let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652), // Philadelphia
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var isMapExpanded = false {
        didSet {
            // When map is collapsed (exited), reset to default position
            if !isMapExpanded {
                resetMapToDefault()
            }
        }
    }
    
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
        var filtered = itineraries
        
        // Filter by category - MUST match exactly
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by region - only if a specific region is selected
        if selectedRegion != .all {
            filtered = filtered.filter { itinerary in
                // Only include if itinerary has a region AND it matches
                if let itineraryRegion = itinerary.region {
                    return itineraryRegion == selectedRegion
                }
                // If itinerary doesn't have a region set, exclude it when filtering by region
                return false
            }
        }
        
        // Filter by cost level - only if a specific cost level is selected
        if let costLevel = selectedCostLevel {
            filtered = filtered.filter { itinerary in
                // Only include if itinerary has a cost level AND it matches
                if let itineraryCostLevel = itinerary.costLevel {
                    return itineraryCostLevel == costLevel
                }
                // If itinerary doesn't have a cost level set, exclude it when filtering by cost
                return false
            }
        }
        
        // Filter by noise level - only if a specific noise level is selected
        if let noiseLevel = selectedNoiseLevel {
            filtered = filtered.filter { itinerary in
                // Only include if itinerary has a noise level AND it matches
                if let itineraryNoiseLevel = itinerary.noiseLevel {
                    return itineraryNoiseLevel == noiseLevel
                }
                // If itinerary doesn't have a noise level set, exclude it when filtering by noise
                return false
            }
        }
        
        // Filter by time estimate - only if a specific time estimate is selected
        if let timeEstimate = selectedTimeEstimate {
            filtered = filtered.filter { timeEstimate.contains($0.timeEstimate) }
        }
        
        return filtered
    }
    
    func selectCategory(_ category: ItineraryCategory) {
        selectedCategory = category
        // Ensure other filters don't interfere when only category is selected
        // Only reset other filters if they would exclude results
        // But keep them if user explicitly set them
    }
    
    func selectItinerary(_ itinerary: Itinerary) {
        selectedItinerary = itinerary
    }
    
    func toggleMapExpansion() {
        // Don't reset filters when collapsing - keep them active
        isMapExpanded.toggle()
    }
    
    func resetMapToDefault() {
        // Always reset map to default Philadelphia region
        cameraPosition = .region(defaultRegion)
    }
    
    func clearAllFilters() {
        selectedCategory = .all
        selectedRegion = .all
        selectedCostLevel = nil
        selectedNoiseLevel = nil
        selectedTimeEstimate = nil
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

