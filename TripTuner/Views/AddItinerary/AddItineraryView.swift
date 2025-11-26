//
//  AddItineraryView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI
import PhotosUI
import CoreLocation

struct AddItineraryView: View {
    @Environment(\.dismiss) var dismiss
    private let itinerariesManager = ItinerariesManager.shared
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: ItineraryCategory = .restaurants
    @State private var selectedRegion: PhiladelphiaRegion = .all
    @State private var timeEstimate: Double = 2
    @State private var cost: String = ""
    @State private var stops: [EditableStop] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !stops.isEmpty &&
        selectedCategory != .all
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Photos (Optional)") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedPhotos.isEmpty ? "Add Photos" : "\(selectedPhotos.count) photo(s) selected")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Basic Information *") {
                    TextField("Title *", text: $title)
                    
                    TextField("Description *", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category *", selection: $selectedCategory) {
                        ForEach(ItineraryCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    Picker("Region", selection: $selectedRegion) {
                        ForEach(PhiladelphiaRegion.allCases, id: \.self) { region in
                            HStack {
                                Text(region.emoji)
                                Text(region.rawValue)
                            }
                            .tag(region)
                        }
                    }
                }
                
                Section("Trip Details *") {
                    VStack(alignment: .leading) {
                        Text("Time Estimate: \(Int(timeEstimate)) hours *")
                        Slider(value: $timeEstimate, in: 1...12, step: 1)
                    }
                    
                    TextField("Cost (optional)", text: $cost)
                        .keyboardType(.decimalPad)
                }
                
                Section("Stops * (At least 1 required)") {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        NavigationLink(destination: EditStopView(
                            locationName: Binding(
                                get: { stops[index].locationName },
                                set: { stops[index].locationName = $0 }
                            ),
                            address: Binding(
                                get: { stops[index].address },
                                set: { stops[index].address = $0 }
                            ),
                            notes: Binding(
                                get: { stops[index].notes ?? "" },
                                set: { stops[index].notes = $0.isEmpty ? nil : $0 }
                            )
                        )) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(stop.locationName.isEmpty ? "New Stop" : stop.locationName)
                                    .font(.system(size: 16, weight: .semibold))
                                if !stop.address.isEmpty {
                                    Text(stop.address)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteStops)
                    
                    Button(action: {
                        let newStop = EditableStop(
                            locationName: "",
                            address: "",
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
            .navigationTitle("Create Itinerary")
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
                    .disabled(!isValid || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func deleteStops(at offsets: IndexSet) {
        stops.remove(atOffsets: offsets)
        // Reorder stops
        for (index, _) in stops.enumerated() {
            stops[index].order = index + 1
        }
    }
    
    private func submitItinerary() {
        // Validate
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Title is required"
            showError = true
            return
        }
        
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Description is required"
            showError = true
            return
        }
        
        guard !stops.isEmpty else {
            errorMessage = "At least one stop is required"
            showError = true
            return
        }
        
        guard selectedCategory != .all else {
            errorMessage = "Please select a category"
            showError = true
            return
        }
        
        // Validate stops
        for stop in stops {
            if stop.locationName.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "All stops must have a location name"
                showError = true
                return
            }
        }
        
        isLoading = true
        
        // Convert editable stops to Stop objects
        let convertedStops = stops.map { editableStop in
            Stop(
                locationName: editableStop.locationName,
                address: editableStop.address,
                latitude: editableStop.latitude,
                longitude: editableStop.longitude,
                notes: editableStop.notes,
                order: editableStop.order
            )
        }
        
        // Create new itinerary
        let newItinerary = Itinerary(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            category: selectedCategory,
            authorID: MockData.currentUserId,
            authorName: MockData.currentUser.username,
            authorHandle: MockData.currentUser.handle,
            stops: convertedStops,
            photos: [],
            likes: 0,
            comments: 0,
            timeEstimate: Int(timeEstimate),
            cost: cost.isEmpty ? nil : Double(cost)
        )
        
        // Add to shared manager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            itinerariesManager.addItinerary(newItinerary)
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Editable Stop
class EditableStop: Identifiable, ObservableObject {
    let id = UUID()
    @Published var locationName: String
    @Published var address: String
    @Published var latitude: Double
    @Published var longitude: Double
    @Published var notes: String?
    @Published var order: Int
    
    init(locationName: String, address: String, latitude: Double, longitude: Double, notes: String? = nil, order: Int) {
        self.locationName = locationName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.order = order
    }
}

// MARK: - Edit Stop View
struct EditStopView: View {
    @Binding var locationName: String
    @Binding var address: String
    @Binding var notes: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Location Information *") {
                TextField("Location Name *", text: $locationName)
                TextField("Address *", text: $address)
            }
            
            Section("Notes (Optional)") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Edit Stop")
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

#Preview {
    AddItineraryView()
}
