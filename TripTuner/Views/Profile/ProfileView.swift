//
//  ProfileView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel(user: MockData.currentUser)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                ZStack {
                    LinearGradient(
                        colors: [Color.pennRed, Color.pennBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                        
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
                        
                        Spacer()
                    }
                    .padding(20)
                }
                
                // November Wrapped
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
                
                // Achievements
                VStack(alignment: .leading, spacing: 16) {
                    Text("Achievements")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(MockData.achievements) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Neighborhoods Explored
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
                
                // User's Itineraries Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("My Itineraries")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                        ForEach(0..<9) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.gray.opacity(0.1))
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
    
    var body: some View {
        Button(action: {}) {
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

