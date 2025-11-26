//
//  ItineraryDetailView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct ItineraryDetailView: View {
    let itinerary: Itinerary
    @Environment(\.dismiss) var dismiss
    @State private var isLiked = false
    @State private var isSaved = false
    @State private var likeCount: Int
    @State private var showComments = false
    
    init(itinerary: Itinerary) {
        self.itinerary = itinerary
        _isLiked = State(initialValue: itinerary.isLiked)
        _isSaved = State(initialValue: itinerary.isSaved)
        _likeCount = State(initialValue: itinerary.likes)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Image
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pennRed.opacity(0.8), Color.pennBlue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 250)
                        
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(itinerary.title)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(itinerary.category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                Spacer()
                            }
                            .padding(20)
                        }
                    }
                    
                    // Metadata Bar
                    HStack {
                        // Author
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(itinerary.authorName)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(itinerary.authorHandle)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Text(itinerary.createdAt, style: .relative)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    
                    // Engagement Metrics
                    HStack(spacing: 24) {
                        Button(action: {
                            isLiked.toggle()
                            likeCount += isLiked ? 1 : -1
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                    .foregroundColor(isLiked ? .pennRed : .gray)
                                Text("\(likeCount)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        
                        Button(action: {
                            showComments = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left")
                                    .foregroundColor(.gray)
                                Text("\(itinerary.comments)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        
                        Button(action: {
                            isSaved.toggle()
                        }) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .foregroundColor(isSaved ? .pennRed : .gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Divider()
                    
                    // Trip Information
                    VStack(alignment: .leading, spacing: 20) {
                        Text(itinerary.description)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Stats
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text("\(itinerary.timeEstimate) hours")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            if let cost = itinerary.cost {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Cost")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("$\(Int(cost))")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Timeline
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Timeline")
                                .font(.system(size: 20, weight: .bold))
                                .padding(.horizontal, 20)
                            
                            ForEach(Array(itinerary.stops.enumerated()), id: \.element.id) { index, stop in
                                TimelineStopView(stop: stop, index: index, isLast: index == itinerary.stops.count - 1)
                            }
                        }
                        .padding(.top, 20)
                    }
                    
                    // I Did This Trip Button
                    Button(action: {
                        // Handle trip completion
                    }) {
                        Text("I Did This Trip!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.pennRed)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(itinerary: itinerary)
        }
    }
}

struct TimelineStopView: View {
    let stop: Stop
    let index: Int
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.pennRed)
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            
            // Stop content
            VStack(alignment: .leading, spacing: 8) {
                Text(stop.locationName)
                    .font(.system(size: 18, weight: .semibold))
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(stop.address)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                if let notes = stop.notes {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct CommentsView: View {
    let itinerary: Itinerary
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Comments")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Mock comments
                    ForEach(0..<5) { _ in
                        CommentRowView()
                            .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Comments")
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

struct CommentRowView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("User Name")
                    .font(.system(size: 14, weight: .semibold))
                
                Text("This looks amazing! Can't wait to try it.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack(spacing: 16) {
                    Text("2h ago")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Button("Reply") {
                        // Handle reply
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Button(action: {}) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Text("12")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Button(action: {}) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ItineraryDetailView(itinerary: MockData.sampleItinerary)
}

