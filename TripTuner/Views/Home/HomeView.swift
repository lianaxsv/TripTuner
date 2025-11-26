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
            // Map View
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.filteredItineraries) { itinerary in
                MapAnnotation(coordinate: itinerary.stops.first?.coordinate ?? CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652)) {
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
            .ignoresSafeArea()
            
            VStack {
                // Top Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Homepage")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("TripTuner")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.pennRed)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {}) {
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
                .background(Color.white.opacity(0.95))
                
                // Search Bar
                HStack {
                    Image(systemName: "mappin")
                        .foregroundColor(.gray)
                    Text("Philadelphia, PA")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
                
                // Category Filters
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
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
                
                // Itinerary Card
                if let selectedItinerary = viewModel.selectedItinerary ?? viewModel.filteredItineraries.first {
                    ItineraryCard(itinerary: selectedItinerary) {
                        viewModel.selectItinerary(selectedItinerary)
                        showItineraryDetail = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
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
        .refreshable {
            viewModel.refreshItineraries()
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

struct ItineraryCard: View {
    let itinerary: Itinerary
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            
            Text(itinerary.title)
                .font(.system(size: 20, weight: .bold))
            
            Text("by \(itinerary.authorName)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(itinerary.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundColor(.gray)
                    Text("\(itinerary.likes)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .foregroundColor(.gray)
                    Text("\(itinerary.comments)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text("\(itinerary.timeEstimate) hours")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: action) {
                    Text("View")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    HomeView()
}

