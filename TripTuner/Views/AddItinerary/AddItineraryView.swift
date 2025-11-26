//
//  AddItineraryView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI
import PhotosUI
import CoreLocation
import MapKit

struct AddItineraryView: View {
    @Environment(\.dismiss) var dismiss
    private let itinerariesManager = ItinerariesManager.shared
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: ItineraryCategory = .restaurants
    @State private var selectedRegion: PhiladelphiaRegion = .all
    @State private var selectedCostLevel: CostLevel = .free
    @State private var noiseLevel: Double = 2.0
    @State private var timeEstimate: Double = 2
    @State private var stops: [EditableStop] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !stops.isEmpty &&
        selectedCategory != .all &&
        selectedRegion != .all
    }
    
    var currentNoiseLevel: NoiseLevel {
        switch Int(noiseLevel) {
        case 1: return .quiet
        case 2: return .moderate
        case 3: return .loud
        case 4: return .veryLoud
        default: return .moderate
        }
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
                            Text("\(category.emoji) \(category.rawValue)")
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Region *", selection: $selectedRegion) {
                        ForEach(PhiladelphiaRegion.allCases.filter { $0 != .all }, id: \.self) { region in
                            Text("\(region.emoji) \(region.rawValue)")
                                .tag(region)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Trip Details *") {
                    VStack(alignment: .leading) {
                        Text("Time Estimate: \(Int(timeEstimate)) hours *")
                        Slider(value: $timeEstimate, in: 1...12, step: 1)
                    }
                    
                    Picker("Cost *", selection: $selectedCostLevel) {
                        ForEach(CostLevel.allCases, id: \.self) { cost in
                            Text(cost.description)
                                .tag(cost)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading) {
                        Text("Noise Level: \(currentNoiseLevel.emoji) \(currentNoiseLevel.displayName)")
                            .fontWeight(.semibold)
                        Slider(value: $noiseLevel, in: 1...4, step: 1)
                    }
                }
                
                Section("Stops * (At least 1 required)") {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        NavigationLink(destination: EditStopView(
                            stop: Binding(
                                get: { stops[index] },
                                set: { stops[index] = $0 }
                            ),
                            onGeocode: { address in
                                GeocodingHelper.shared.geocodeAddress(address) { coordinate in
                                    if let coordinate = coordinate {
                                        stops[index].latitude = coordinate.latitude
                                        stops[index].longitude = coordinate.longitude
                                    }
                                }
                            }
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
        
        guard selectedRegion != .all else {
            errorMessage = "Please select a region"
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
            if stop.addressComponents?.street.trimmingCharacters(in: .whitespaces).isEmpty ?? true {
                errorMessage = "All stops must have a street address"
                showError = true
                return
            }
        }
        
        isLoading = true
        
        // Geocode all stops
        let group = DispatchGroup()
        for (index, stop) in stops.enumerated() {
            group.enter()
            let addressString = stop.addressComponents?.fullAddress ?? stop.address
            GeocodingHelper.shared.geocodeAddress(addressString) { coordinate in
                if let coordinate = coordinate {
                    stops[index].latitude = coordinate.latitude
                    stops[index].longitude = coordinate.longitude
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Convert editable stops to Stop objects
            let convertedStops = self.stops.map { editableStop in
                Stop(
                    locationName: editableStop.locationName,
                    address: editableStop.addressComponents?.fullAddress ?? editableStop.address,
                    addressComponents: editableStop.addressComponents,
                    latitude: editableStop.latitude,
                    longitude: editableStop.longitude,
                    notes: editableStop.notes,
                    order: editableStop.order
                )
            }
            
            // Create new itinerary with 0 likes and 0 comments
            let newItinerary = Itinerary(
                title: self.title.trimmingCharacters(in: .whitespaces),
                description: self.description.trimmingCharacters(in: .whitespaces),
                category: self.selectedCategory,
                authorID: MockData.currentUserId,
                authorName: MockData.currentUser.username,
                authorHandle: MockData.currentUser.handle,
                stops: convertedStops,
                photos: [],
                likes: 0,
                comments: 0,
                timeEstimate: Int(self.timeEstimate),
                cost: self.selectedCostLevel.numericValue,
                costLevel: self.selectedCostLevel,
                noiseLevel: self.currentNoiseLevel,
                region: self.selectedRegion
            )
            
            // Add to shared manager
            self.itinerariesManager.addItinerary(newItinerary)
            self.isLoading = false
            self.dismiss()
        }
    }
}

// MARK: - Editable Stop
class EditableStop: Identifiable, ObservableObject {
    let id = UUID()
    @Published var locationName: String
    @Published var address: String
    @Published var addressComponents: Address?
    @Published var latitude: Double
    @Published var longitude: Double
    @Published var notes: String?
    @Published var order: Int
    
    init(locationName: String, address: String, addressComponents: Address? = nil, latitude: Double, longitude: Double, notes: String? = nil, order: Int) {
        self.locationName = locationName
        self.address = address
        self.addressComponents = addressComponents
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.order = order
    }
}

// MARK: - Edit Stop View
struct EditStopView: View {
    @Binding var stop: EditableStop
    var onGeocode: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var isGeocoding = false
    @State private var street = ""
    @State private var city = "Philadelphia"
    @State private var state = "PA"
    @State private var zipCode = ""
    
    var body: some View {
        Form {
            Section("Location Information *") {
                TextField("Location Name *", text: Binding(
                    get: { stop.locationName },
                    set: { stop.locationName = $0 }
                ))
                
                TextField("Street Address *", text: $street)
                    .onChange(of: street) { oldValue, newValue in
                        updateAddress()
                    }
                
                HStack {
                    TextField("City *", text: $city)
                        .onChange(of: city) { oldValue, newValue in
                            updateAddress()
                        }
                    
                    TextField("State *", text: $state)
                        .onChange(of: state) { oldValue, newValue in
                            updateAddress()
                        }
                }
                
                TextField("Zip Code", text: $zipCode)
                    .keyboardType(.numberPad)
                    .onChange(of: zipCode) { oldValue, newValue in
                        updateAddress()
                    }
                
                if isGeocoding {
                    HStack {
                        ProgressView()
                        Text("Finding location...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section("Notes (Optional)") {
                TextField("Notes", text: Binding(
                    get: { stop.notes ?? "" },
                    set: { stop.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            }
        }
        .navigationTitle("Edit Stop")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    updateAddress()
                    dismiss()
                }
            }
        }
        .onAppear {
            // Load existing address components
            if let components = stop.addressComponents {
                street = components.street
                city = components.city
                state = components.state
                zipCode = components.zipCode
            } else if !stop.address.isEmpty {
                // Try to parse existing address
                parseAddress(stop.address)
            }
        }
    }
    
    private func parseAddress(_ address: String) {
        // Simple parsing - in a real app, you'd use a more robust parser
        let parts = address.components(separatedBy: ",")
        if parts.count >= 2 {
            street = parts[0].trimmingCharacters(in: .whitespaces)
            let cityState = parts[1].trimmingCharacters(in: .whitespaces)
            let cityStateParts = cityState.components(separatedBy: " ")
            if cityStateParts.count >= 2 {
                city = cityStateParts[0]
                state = cityStateParts[1]
                if cityStateParts.count > 2 {
                    zipCode = cityStateParts[2]
                }
            }
        } else {
            street = address
        }
    }
    
    private func updateAddress() {
        let address = Address(
            street: street,
            city: city,
            state: state,
            zipCode: zipCode
        )
        stop.addressComponents = address
        stop.address = address.fullAddress
        
        // Geocode when we have enough info
        if !street.isEmpty && street.count > 5 {
            isGeocoding = true
            onGeocode(address.fullAddress)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isGeocoding = false
            }
        }
    }
}

#Preview {
    AddItineraryView()
}
