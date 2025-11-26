//
//  ProfileView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel(user: MockData.currentUser)
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showImagePicker = false
    @State private var selectedItinerary: Itinerary?
    @State private var showItineraryDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                novemberWrapped
                achievementsSection
                neighborhoodsSection
                myItinerariesSection
                savedItinerariesSection
            }
        }
        .background(Color.gray.opacity(0.1))
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhoto, matching: .images)
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.profileImage = image
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAchievementDetail) {
            if let achievement = viewModel.selectedAchievement {
                AchievementDetailView(achievement: achievement)
            }
        }
        .sheet(isPresented: $showItineraryDetail) {
            if let itinerary = selectedItinerary {
                ItineraryDetailView(itinerary: itinerary)
                    .onDisappear {
                        viewModel.refreshStats()
                    }
            }
        }
        .onAppear {
            viewModel.refreshStats()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.pennRed, Color.pennBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            
            HStack(alignment: .top, spacing: 16) {
                profilePictureButton
                profileInfo
                Spacer()
            }
            .padding(20)
        }
    }
    
    private var profilePictureButton: some View {
        Button(action: {
            showImagePicker = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                
                if let image = viewModel.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.pennRed)
                            .clipShape(Circle())
                    }
                }
                .frame(width: 80, height: 80)
            }
        }
    }
    
    private var profileInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.user.username)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(viewModel.user.handle)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(viewModel.user.streak) day streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .padding(.top, 8)
        }
    }
    
    // MARK: - November Wrapped
    private var novemberWrapped: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.pennRed)
                Text("November Wrapped")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            HStack(spacing: 20) {
                StatTile(icon: "chart.line.uptrend.xyaxis", value: "\(viewModel.milesTraveled)", label: "miles traveled", color: .pennRed)
                StatTile(icon: "mappin", value: "\(viewModel.neighborhoodsExplored)", label: "neighborhoods", color: .pennBlue)
                StatTile(icon: "target", value: "\(viewModel.tripsCompleted)", label: "trips done", color: .pennRed)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MockData.achievements) { achievement in
                    AchievementBadge(achievement: achievement) {
                        viewModel.showAchievement(achievement)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Neighborhoods Section
    private var neighborhoodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Neighborhoods Explored")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            FlowLayout(spacing: 8) {
                ForEach(MockData.neighborhoods, id: \.self) { neighborhood in
                    HStack(spacing: 4) {
                        Text(neighborhood)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.pennRed)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Completed Itineraries Section
    private var myItinerariesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Itineraries I Did")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            if viewModel.completedItineraries.isEmpty {
                emptyCompletedItinerariesView
            } else {
                completedItinerariesGrid
            }
        }
        .padding(.bottom, 20)
    }
    
    private var emptyCompletedItinerariesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text("No completed trips yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            Text("Complete an itinerary to see it here!")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var completedItinerariesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
            ForEach(viewModel.completedItineraries) { itinerary in
                Button(action: {
                    selectedItinerary = itinerary
                    showItineraryDetail = true
                }) {
                    ItineraryGridItem(itinerary: itinerary, gradientColors: [Color.green.opacity(0.6), Color.pennBlue.opacity(0.6)])
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Saved Itineraries Section
    private var savedItinerariesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Saved Itineraries")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            if viewModel.savedItineraries.isEmpty {
                emptySavedItinerariesView
            } else {
                savedItinerariesGrid
            }
        }
        .padding(.bottom, 20)
    }
    
    private var emptySavedItinerariesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text("No saved itineraries yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            Text("Save itineraries you want to try later!")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var savedItinerariesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
            ForEach(viewModel.savedItineraries) { itinerary in
                Button(action: {
                    selectedItinerary = itinerary
                    showItineraryDetail = true
                }) {
                    ItineraryGridItem(itinerary: itinerary, gradientColors: [Color.pennBlue.opacity(0.6), Color.pennRed.opacity(0.6)])
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Supporting Views
struct ItineraryGridItem: View {
    let itinerary: Itinerary
    let gradientColors: [Color]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
            
            VStack {
                Text(itinerary.category.emoji)
                    .font(.system(size: 30))
                Text(itinerary.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(achievement.emoji)
                    .font(.system(size: 32))
                
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(achievement.isUnlocked ? Color.white : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(achievement.isUnlocked ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .opacity(achievement.isUnlocked ? 1.0 : 0.5)
        }
    }
}

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(achievement.emoji)
                    .font(.system(size: 100))
                
                Text(achievement.title)
                    .font(.system(size: 32, weight: .bold))
                
                Text(achievement.description)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                if let unlockedAt = achievement.unlockedAt {
                    VStack(spacing: 8) {
                        Text("Unlocked on")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(unlockedAt, style: .date)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.top, 20)
                } else {
                    Text("Locked")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding(40)
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    ProfileView()
}
