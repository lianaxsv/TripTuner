//
//  HomeView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI
import MapKit

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showItineraryDetail = false
    @State private var showAddItinerary = false
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.05).ignoresSafeArea()
            
            if viewModel.isMapExpanded {
                // Expanded Map View
                expandedMapView
            } else {
                // Normal Home View
                normalHomeView
            }
        }
        .sheet(isPresented: $showItineraryDetail) {
            if let itinerary = viewModel.selectedItinerary {
                ItineraryDetailView(itinerary: itinerary)
            }
        }
        .sheet(isPresented: $showAddItinerary) {
            AddItineraryView()
        }
    }
    
    // MARK: - Normal Home View
    private var normalHomeView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Discover Philly")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.pennRed)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            viewModel.toggleMapExpansion()
                        }) {
                            Image(systemName: "map")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: {
                            showAddItinerary = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)
                
                // Top Itineraries of the Week
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Top Itineraries This Week")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.topItinerariesOfWeek) { itinerary in
                                TopItineraryCard(itinerary: itinerary) {
                                    viewModel.selectItinerary(itinerary)
                                    showItineraryDetail = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 24)
                
                // Map Section (Collapsed)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Explore on Map")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Button(action: {
                            viewModel.toggleMapExpansion()
                        }) {
                            Text("Expand")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.pennRed)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Small Map Preview
                    Button(action: {
                        viewModel.toggleMapExpansion()
                    }) {
                        ZStack {
                            Map(position: $viewModel.cameraPosition) {
                                ForEach(viewModel.filteredItineraries) { itinerary in
                                    if let coordinate = itinerary.stops.first?.coordinate {
                                        Annotation(itinerary.title, coordinate: coordinate) {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(pinColor(for: itinerary.category))
                                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .allowsHitTesting(false) // Disable map interaction, use button instead
                            
                            // Overlay to indicate it's tappable
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(12)
                            }
                        }
                    }
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
                
                // Category Filters (only show if category is selected)
                if viewModel.selectedCategory != .all {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Filtering: \(viewModel.selectedCategory.rawValue)")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(ItineraryCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                    CategoryFilterChip(
                                        category: category,
                                        isSelected: viewModel.selectedCategory == category,
                                        action: {
                                            viewModel.selectCategory(category)
                                        }
                                    )
                                }
                                
                                // Clear filter button
                                Button(action: {
                                    viewModel.selectCategory(.all)
                                }) {
                                    Text("Clear")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 24)
                }
                
                // Bottom Footer (clean, no map)
                VStack(spacing: 8) {
                    Text("Discover amazing trips in Philadelphia")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Select a category to filter itineraries on the map")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white)
            }
        }
        .refreshable {
            viewModel.refreshItineraries()
        }
    }
    
    // MARK: - Expanded Map View
    private var expandedMapView: some View {
        ZStack {
            // Full Map
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.filteredItineraries) { itinerary in
                    if let coordinate = itinerary.stops.first?.coordinate {
                        Annotation(itinerary.title, coordinate: coordinate) {
                            Button(action: {
                                viewModel.selectItinerary(itinerary)
                                showItineraryDetail = true
                            }) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(pinColor(for: itinerary.category))
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack {
                // Top Bar with Close Button
                HStack {
                    Button(action: {
                        viewModel.toggleMapExpansion()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Explore Map")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Category Filters (always visible in expanded map)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ItineraryCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            CategoryFilterChip(
                                category: category,
                                isSelected: viewModel.selectedCategory == category,
                                action: {
                                    viewModel.selectCategory(category)
                                }
                            )
                        }
                        
                        // Clear filter button
                        Button(action: {
                            viewModel.selectCategory(.all)
                        }) {
                            Text("All")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(viewModel.selectedCategory == .all ? .white : .black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(viewModel.selectedCategory == .all ? Color.pennRed : Color.white)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func pinColor(for category: ItineraryCategory) -> Color {
        switch category {
        case .restaurants: return .red
        case .cafes: return .yellow
        case .attractions: return .blue
        case .all: return .gray
        }
    }
}

// MARK: - Top Itinerary Card
struct TopItineraryCard: View {
    let itinerary: Itinerary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // Image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.pennRed.opacity(0.6), Color.pennBlue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 120)
                    
                    VStack {
                        Text(itinerary.category.emoji)
                            .font(.system(size: 40))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(itinerary.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("\(itinerary.timeEstimate) hours")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("•")
                            .foregroundColor(.gray)
                        Text(costString)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .frame(width: 200)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private var costString: String {
        if let cost = itinerary.cost {
            if cost < 25 { return "$" }
            else if cost < 50 { return "$$" }
            else { return "$$$" }
        }
        return "Free"
    }
}

struct CategoryFilterChip: View {
    let category: ItineraryCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.emoji)
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.pennRed : Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

#Preview {
    HomeView()
}
