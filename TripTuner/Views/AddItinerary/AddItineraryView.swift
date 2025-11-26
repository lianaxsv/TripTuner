//
//  AddItineraryView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct AddItineraryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: ItineraryCategory = .restaurants
    @State private var timeEstimate: Double = 2
    @State private var cost: String = ""
    @State private var stops: [Stop] = []
    @State private var photos: [String] = []
    @State private var showImagePicker = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Photos") {
                    if photos.isEmpty {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Add Photos")
                            }
                            .foregroundColor(.blue)
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(photos, id: \.self) { photo in
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "photo.fill")
                                                .foregroundColor(.gray)
                                        )
                                }
                                
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                        }
                    }
                }
                
                Section("Basic Information") {
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ItineraryCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section("Trip Details") {
                    VStack(alignment: .leading) {
                        Text("Time Estimate: \(Int(timeEstimate)) hours")
                        Slider(value: $timeEstimate, in: 1...12, step: 1)
                    }
                    
                    TextField("Cost (optional)", text: $cost)
                        .keyboardType(.decimalPad)
                }
                
                Section("Stops") {
                    ForEach(stops) { stop in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(stop.locationName)
                                .font(.system(size: 16, weight: .semibold))
                            Text(stop.address)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            if let notes = stop.notes {
                                Text(notes)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteStops)
                    
                    Button(action: {
                        // Add new stop
                        let newStop = Stop(
                            locationName: "New Stop",
                            address: "Address",
                            latitude: 39.9526,
                            longitude: -75.1652,
                            order: stops.count + 1
                        )
                        stops.append(newStop)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Stop")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("New Itinerary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        submitItinerary()
                    }
                    .disabled(title.isEmpty || stops.isEmpty)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                // Image picker would go here
                Text("Image Picker")
            }
        }
    }
    
    private func deleteStops(at offsets: IndexSet) {
        stops.remove(atOffsets: offsets)
    }
    
    private func submitItinerary() {
        isLoading = true
        // Mock submission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    AddItineraryView()
}

