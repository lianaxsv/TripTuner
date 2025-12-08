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
    @State private var showFilterSheet = false
    
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
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(viewModel: viewModel)
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
                        
                        Button(action: {
                            showFilterSheet = true
                        }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
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
                                .background(Color.pennRed)
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
                                ForEach(viewModel.filteredItineraries, id: \.id) { itinerary in
                                    if let firstStop = itinerary.stops.first,
                                       firstStop.isValidCoordinate {
                                        Annotation(itinerary.title, coordinate: firstStop.coordinate) {
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
                
                // Active Filters Display
                if hasActiveFilters {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Active Filters")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Button(action: {
                                viewModel.clearAllFilters()
                            }) {
                                Text("Clear All")
                                    .font(.system(size: 14))
                                    .foregroundColor(.pennRed)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if viewModel.selectedCategory != .all {
                                    FilterTag(text: viewModel.selectedCategory.rawValue, emoji: viewModel.selectedCategory.emoji) {
                                        viewModel.selectCategory(.all)
                                    }
                                }
                                
                                if viewModel.selectedRegion != .all {
                                    FilterTag(text: viewModel.selectedRegion.rawValue, emoji: viewModel.selectedRegion.emoji) {
                                        viewModel.selectedRegion = .all
                                    }
                                }
                                
                                if let cost = viewModel.selectedCostLevel {
                                    FilterTag(text: cost.description, emoji: nil) {
                                        viewModel.selectedCostLevel = nil
                                    }
                                }
                                
                                if let noise = viewModel.selectedNoiseLevel {
                                    FilterTag(text: noise.displayName, emoji: noise.emoji) {
                                        viewModel.selectedNoiseLevel = nil
                                    }
                                }
                                if let time = viewModel.selectedTimeEstimate {
                                    FilterTag(text: time.displayName, emoji: time.emoji) {
                                        viewModel.selectedTimeEstimate = nil
                                    }
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
                    Text("Use the filter icon to customize your search")
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
    
    private var hasActiveFilters: Bool {
        viewModel.selectedCategory != .all ||
        viewModel.selectedRegion != .all ||
        viewModel.selectedCostLevel != nil ||
        viewModel.selectedNoiseLevel != nil ||
        viewModel.selectedTimeEstimate != nil
    }
    
    // MARK: - Expanded Map View
    private var expandedMapView: some View {
        ZStack {
            // Full Map
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.filteredItineraries, id: \.id) { itinerary in
                    if let firstStop = itinerary.stops.first,
                       firstStop.isValidCoordinate {
                        Annotation(itinerary.title, coordinate: firstStop.coordinate) {
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
                // Top Bar with Close Button and Filter
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
                    
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            if hasActiveFilters {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.pennRed)
                            }
                        }
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Active Filters Display
                if hasActiveFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if viewModel.selectedCategory != .all {
                                FilterTag(text: viewModel.selectedCategory.rawValue, emoji: viewModel.selectedCategory.emoji) {
                                    viewModel.selectCategory(.all)
                                }
                            }
                            
                            if viewModel.selectedRegion != .all {
                                FilterTag(text: viewModel.selectedRegion.rawValue, emoji: viewModel.selectedRegion.emoji) {
                                    viewModel.selectedRegion = .all
                                }
                            }
                            
                            if let cost = viewModel.selectedCostLevel {
                                FilterTag(text: cost.description, emoji: nil) {
                                    viewModel.selectedCostLevel = nil
                                }
                            }
                            
                            if let noise = viewModel.selectedNoiseLevel {
                                FilterTag(text: noise.displayName, emoji: noise.emoji) {
                                    viewModel.selectedNoiseLevel = nil
                                }
                            }
                            
                            if let time = viewModel.selectedTimeEstimate {
                                FilterTag(text: time.displayName, emoji: time.emoji) {
                                    viewModel.selectedTimeEstimate = nil
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(viewModel: viewModel)
        }
    }
    
    private func pinColor(for category: ItineraryCategory) -> Color {
        switch category {
        case .restaurants: return .red
        case .cafes: return .orange
        case .attractions: return .blue
        case .shopping: return .pink
        case .nature: return .green
        case .nightlife: return .yellow
        case .fitness: return .purple
        case .all: return .gray
        }
    }
}

// MARK: - Filter Sheet View
struct FilterSheetView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        // Show "All" first
                        Text("\(ItineraryCategory.all.emoji) \(ItineraryCategory.all.rawValue)")
                            .tag(ItineraryCategory.all)
                        // Then show other categories
                        ForEach(ItineraryCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Text("\(category.emoji) \(category.rawValue)")
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Region") {
                    Picker("Region", selection: $viewModel.selectedRegion) {
                        // Show "All Regions" first
                        Text("\(PhiladelphiaRegion.all.emoji) \(PhiladelphiaRegion.all.rawValue)")
                            .tag(PhiladelphiaRegion.all)
                        // Then show other regions
                        ForEach(PhiladelphiaRegion.allCases.filter { $0 != .all }, id: \.self) { region in
                            Text("\(region.emoji) \(region.rawValue)")
                                .tag(region)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Cost") {
                    Picker("Cost", selection: Binding(
                        get: { viewModel.selectedCostLevel },
                        set: { viewModel.selectedCostLevel = $0 }
                    )) {
                        Text("Any Cost Level").tag(nil as CostLevel?)
                        ForEach(CostLevel.allCases, id: \.self) { cost in
                            Text(cost.description)
                                .tag(cost as CostLevel?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Noise Level") {
                    Picker("Noise Level", selection: Binding(
                        get: { viewModel.selectedNoiseLevel },
                        set: { viewModel.selectedNoiseLevel = $0 }
                    )) {
                        Text("Any Noise Level").tag(nil as NoiseLevel?)
                        ForEach(NoiseLevel.allCases, id: \.self) { noise in
                            Text("\(noise.emoji) \(noise.displayName)")
                                .tag(noise as NoiseLevel?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Time Estimate") {
                    Picker("Time Estimate", selection: Binding(
                        get: { viewModel.selectedTimeEstimate },
                        set: { viewModel.selectedTimeEstimate = $0 }
                    )) {
                        Text("Any Time").tag(nil as TimeEstimate?)
                        ForEach(TimeEstimate.allCases.filter { $0 != .any }, id: \.self) { time in
                            Text("\(time.emoji) \(time.displayName)")
                                .tag(time as TimeEstimate?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        viewModel.clearAllFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Filter Tag
struct FilterTag: View {
    let text: String
    let emoji: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji)
                }
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.pennRed)
            .cornerRadius(16)
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
                // Show photo if available, otherwise show gradient with emoji
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
                    
                    if let firstPhotoURL = itinerary.photos.first, !firstPhotoURL.isEmpty,
                       let url = URL(string: firstPhotoURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                VStack {
                                    Text(itinerary.category.emoji)
                                        .font(.system(size: 40))
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 200, height: 120)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure:
                                VStack {
                                    Text(itinerary.category.emoji)
                                        .font(.system(size: 40))
                                }
                            @unknown default:
                                VStack {
                                    Text(itinerary.category.emoji)
                                        .font(.system(size: 40))
                                }
                            }
                        }
                    } else {
                        VStack {
                            Text(itinerary.category.emoji)
                                .font(.system(size: 40))
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(itinerary.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.pennRed)
                            Text("\(LikedItinerariesManager.shared.getLikeCount(for: itinerary.id, defaultCount: itinerary.likes))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.pennRed)
                        }
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
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
        if let costLevel = itinerary.costLevel {
            return costLevel.displayName
        }
        if let cost = itinerary.cost {
            if cost < 25 { return "$" }
            else if cost < 50 { return "$$" }
            else { return "$$$" }
        }
        return "Free"
    }
}

#Preview {
    HomeView()
}
