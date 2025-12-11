//
//  ProfileView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showImagePicker = false
    @State private var showDeleteConfirmation = false
    @State private var isDeletingAccount = false
    
    @State private var selectedItinerary: Itinerary?
    @State private var selectedPhoto: PhotosPickerItem?

    
    init(authViewModel: AuthViewModel? = nil) {
        // SwiftUI will inject the real one later
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: authViewModel ?? AuthViewModel()))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                monthlyWrapped
                achievementsSection
                neighborhoodsSection
                myItinerariesSection
                savedItinerariesSection
                signOutSection
            }
        }
        .onAppear {
            viewModel.setAuthViewModel(authViewModel)
            viewModel.refreshStats()
        }
        .photosPicker(
            isPresented: $showImagePicker,
            selection: $selectedPhoto,
            matching: .images
        )
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.profileImage = image
                        // Upload to Firebase Storage
                        uploadProfilePicture(image)
                    }
                }
            }
        }
        .sheet(item: $selectedItinerary) { itinerary in
            ItineraryDetailView(itinerary: itinerary)
        }
        .sheet(item: $viewModel.selectedAchievement) { achievement in
            AchievementDetailView(achievement: achievement)
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
                } else if let imageURL = viewModel.profileImageURL,
                          let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .overlay(ProgressView().tint(.white))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Circle()
                                .fill(Color.white.opacity(0.3))
                        @unknown default:
                            Circle()
                                .fill(Color.white.opacity(0.3))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
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
            if let user = viewModel.user {
                Text(user.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(user.handle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(user.streak) day streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .padding(.top, 8)

            } else {
                // fallback placeholder
                Text("Loading user…")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    
    
    // MARK: - Monthly Wrapped
    private var monthlyWrapped: some View {
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let monthName = monthFormatter.string(from: Date())
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.pennRed)
                Text("\(monthName) Wrapped")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            HStack(spacing: 20) {
                StatTile(icon: "tag.fill", value: "\(viewModel.categoriesExplored)", label: "categories", color: .pennRed)
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
                if let achievements = viewModel.user?.achievements {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement) {
                            viewModel.selectedAchievement = achievement
                        }
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
                ForEach(viewModel.neighborhoods, id: \.self) { neighborhood in
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
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.completedItineraries) { itinerary in
                Button(action: {
                    selectedItinerary = itinerary
                }) {
                    ItineraryGridItem(itinerary: itinerary, gradientColors: [Color.green.opacity(0.6), Color.pennBlue.opacity(0.6)])
                }
                .buttonStyle(PlainButtonStyle())
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
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(viewModel.savedItineraries) { itinerary in
                Button(action: {
                    selectedItinerary = itinerary
                }) {
                    ItineraryGridItem(itinerary: itinerary, gradientColors: [Color.pennBlue.opacity(0.6), Color.pennRed.opacity(0.6)])
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Sign Out Section
    private var signOutSection: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.top, 20)
            
            // Delete Account Button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                    Text("Delete Account")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .disabled(isDeletingAccount)
            
            Divider()
            
            // Sign Out Button
            Button(action: {
                authViewModel.logout()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                        .font(.system(size: 18))
                    Text("Sign Out")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .disabled(isDeletingAccount)
            
            Divider()
        }
        .padding(.bottom, 20)
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone. All your data, including itineraries, comments, and likes, will be permanently deleted.")
        }
    }
    
    // MARK: - Helper Functions
    private func deleteAccount() {
        isDeletingAccount = true
        authViewModel.deleteAccount { success, error in
            DispatchQueue.main.async {
                self.isDeletingAccount = false
                if let error = error {
                    print("Error deleting account: \(error.localizedDescription)")
                    // You could show an error alert here if needed
                }
                // If successful, logout() is called inside deleteAccount, so we don't need to do anything
            }
        }
    }
    
    private func uploadProfilePicture(_ image: UIImage) {
        guard let userID = authViewModel.currentUser?.id else {
            return
        }
        
        StorageHelper.shared.uploadProfilePicture(image, userID: userID) { result in
            switch result {
            case .success(let url):
                // Update profile image URL in Firestore
                let db = Firestore.firestore()
                db.collection("users").document(userID).updateData([
                    "profileImageURL": url
                ]) { error in
                    if let error = error {
                        print("Error updating profile image URL: \(error.localizedDescription)")
                    } else {
                        // Update local user object
                        DispatchQueue.main.async {
                            self.viewModel.profileImageURL = url
                            if var user = self.viewModel.user {
                                user.profileImageURL = url
                                self.viewModel.user = user
                            }
                            // Update AuthViewModel
                            if var currentUser = self.authViewModel.currentUser {
                                currentUser.profileImageURL = url
                                self.authViewModel.currentUser = currentUser
                            }
                        }
                        
                        // Update all itineraries created by this user
                        self.updateItinerariesWithNewProfileImage(userID: userID, imageURL: url)
                        
                        // Update all comments by this user
                        self.updateCommentsWithNewProfileImage(userID: userID, imageURL: url)
                    }
                }
            case .failure(let error):
                print("Error uploading profile picture: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateItinerariesWithNewProfileImage(userID: String, imageURL: String) {
        let db = Firestore.firestore()
        db.collection("itineraries")
            .whereField("authorID", isEqualTo: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error updating itineraries with new profile image: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let batch = db.batch()
                for document in documents {
                    batch.updateData(["authorProfileImageURL": imageURL], forDocument: document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error batch updating itineraries: \(error.localizedDescription)")
                    } else {
                        // Reload itineraries to reflect changes
                        ItinerariesManager.shared.reloadItineraries()
                    }
                }
            }
    }
    
    private func updateCommentsWithNewProfileImage(userID: String, imageURL: String) {
        let db = Firestore.firestore()
        // Get all itineraries to update comments
        db.collection("itineraries").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching itineraries for comment update: \(error.localizedDescription)")
                return
            }
            
            guard let itineraryDocs = snapshot?.documents else { return }
            
            for itineraryDoc in itineraryDocs {
                db.collection("itineraries").document(itineraryDoc.documentID)
                    .collection("comments")
                    .whereField("authorID", isEqualTo: userID)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error updating comments: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let commentDocs = snapshot?.documents else { return }
                        
                        let batch = db.batch()
                        for commentDoc in commentDocs {
                            batch.updateData(["authorProfileImageURL": imageURL], forDocument: commentDoc.reference)
                        }
                        
                        batch.commit { error in
                            if let error = error {
                                print("Error batch updating comments: \(error.localizedDescription)")
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Supporting Views
struct ItineraryGridItem: View {
    let itinerary: Itinerary
    let gradientColors: [Color]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Show photo if available, otherwise show emoji
                if let firstPhotoURL = itinerary.photos.first, !firstPhotoURL.isEmpty,
                   let url = URL(string: firstPhotoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            VStack(spacing: 4) {
                                Text(itinerary.category.emoji)
                                    .font(.system(size: 30))
                                Text(itinerary.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 4)
                            }
                        case .success(let image):
                            ZStack(alignment: .bottom) {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .clipped()
                                
                                // Title overlay
                                VStack {
                                    Spacer()
                                    Text(itinerary.title)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.black.opacity(0.7), Color.clear],
                                                startPoint: .bottom,
                                                endPoint: .top
                                            )
                                        )
                                }
                            }
                        case .failure:
                            VStack(spacing: 4) {
                                Text(itinerary.category.emoji)
                                    .font(.system(size: 30))
                                Text(itinerary.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 4)
                            }
                        @unknown default:
                            VStack(spacing: 4) {
                                Text(itinerary.category.emoji)
                                    .font(.system(size: 30))
                                Text(itinerary.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 4) {
                        Text(itinerary.category.emoji)
                            .font(.system(size: 30))
                        Text(itinerary.title)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .aspectRatio(1, contentMode: .fit)
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
