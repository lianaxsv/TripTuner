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
    @EnvironmentObject var authViewModel: AuthViewModel
    private let itinerariesManager = ItinerariesManager.shared
    
    // Form state with UserDefaults persistence
    @AppStorage("draftItineraryTitle") private var title = ""
    @AppStorage("draftItineraryDescription") private var description = ""
    @AppStorage("draftItineraryCategory") private var savedCategory: String = ""
    @AppStorage("draftItineraryRegion") private var savedRegion: String = ""
    @AppStorage("draftItineraryCost") private var savedCost: String = ""
    @AppStorage("draftItineraryNoiseLevel") private var savedNoiseLevel: Double = 2.0
    @AppStorage("draftItineraryTimeEstimate") private var timeEstimate: Double = 2
    
    @State private var selectedCategory: ItineraryCategory? = nil
    @State private var selectedRegion: PhiladelphiaRegion? = nil
    @State private var selectedCostLevel: CostLevel? = nil
    @State private var noiseLevel: Double = 2.0
    @State private var stops: [EditableStop] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !stops.isEmpty &&
        !selectedPhotos.isEmpty && // At least one photo required
        selectedCategory != nil &&
        selectedCategory != .all &&
        selectedRegion != nil &&
        selectedRegion != .all &&
        selectedCostLevel != nil
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
                Section("Photos *") {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text(selectedPhotos.isEmpty ? "Add at least 1 photo" : "\(selectedPhotos.count) photo(s) selected")
                        }
                        .foregroundColor(.blue)
                    }
                    if selectedPhotos.isEmpty {
                        Text("At least one photo is required")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                
                Section("Basic Information *") {
                    TextField("Title *", text: $title)
                    
                    TextField("Description *", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category *", selection: Binding(
                        get: { selectedCategory },
                        set: { 
                            selectedCategory = $0
                            savedCategory = $0?.rawValue ?? ""
                        }
                    )) {
                        Text("Select Category").tag(nil as ItineraryCategory?)
                        ForEach(ItineraryCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Text("\(category.emoji) \(category.rawValue)")
                                .tag(category as ItineraryCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Region *", selection: Binding(
                        get: { selectedRegion },
                        set: { 
                            selectedRegion = $0
                            savedRegion = $0?.rawValue ?? ""
                        }
                    )) {
                        Text("Select Region").tag(nil as PhiladelphiaRegion?)
                        ForEach(PhiladelphiaRegion.allCases.filter { $0 != .all }, id: \.self) { region in
                            Text("\(region.emoji) \(region.rawValue)")
                                .tag(region as PhiladelphiaRegion?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Trip Details *") {
                    VStack(alignment: .leading) {
                        Text("Time Estimate: \(Int(timeEstimate)) hours *")
                        Slider(value: $timeEstimate, in: 1...12, step: 1)
                    }
                    
                    Picker("Cost *", selection: Binding(
                        get: { selectedCostLevel },
                        set: { 
                            selectedCostLevel = $0
                            savedCost = $0?.rawValue ?? ""
                        }
                    )) {
                        Text("Select Cost Level").tag(nil as CostLevel?)
                        ForEach(CostLevel.allCases, id: \.self) { cost in
                            Text(cost.description)
                                .tag(cost as CostLevel?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading) {
                        Text("Noise Level: \(currentNoiseLevel.emoji) \(currentNoiseLevel.displayName)")
                            .fontWeight(.semibold)
                        Slider(value: Binding(
                            get: { noiseLevel },
                            set: { 
                                noiseLevel = $0
                                savedNoiseLevel = $0
                            }
                        ), in: 1...4, step: 1)
                    }
                }
                
                Section("Stops * (At least 1 required)") {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        NavigationLink(destination: EditStopView(
                            stop: Binding(
                                get: { stops[index] },
                                set: { 
                                    stops[index] = $0
                                    saveDraftState()
                                }
                            ),
                            onGeocode: { address in
                                GeocodingHelper.shared.geocodeAddress(address) { coordinate in
                                    if let coordinate = coordinate,
                                       !coordinate.latitude.isNaN && !coordinate.longitude.isNaN,
                                       !coordinate.latitude.isInfinite && !coordinate.longitude.isInfinite {
                                        stops[index].latitude = coordinate.latitude
                                        stops[index].longitude = coordinate.longitude
                                    } else {
                                        // Use default Philadelphia coordinates if geocoding fails
                                        stops[index].latitude = 39.9526
                                        stops[index].longitude = -75.1652
                                    }
                                    saveDraftState()
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
                        saveDraftState()
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
                        // Save draft state before dismissing
                        saveDraftState()
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
            .onAppear {
                loadDraftState()
            }
            .onDisappear {
                saveDraftState()
            }
        }
    }
    
    private func loadDraftState() {
        // Load category
        if !savedCategory.isEmpty {
            selectedCategory = ItineraryCategory.allCases.first { $0.rawValue == savedCategory && $0 != .all }
        }
        
        // Load region
        if !savedRegion.isEmpty {
            selectedRegion = PhiladelphiaRegion.allCases.first { $0.rawValue == savedRegion && $0 != .all }
        }
        
        // Load cost
        if !savedCost.isEmpty {
            selectedCostLevel = CostLevel.allCases.first { $0.rawValue == savedCost }
        }
        
        // Load noise level
        noiseLevel = savedNoiseLevel
        
        // Load stops from UserDefaults
        if let stopsData = UserDefaults.standard.data(forKey: "draftItineraryStops"),
           let decodedStops = try? JSONDecoder().decode([DraftStop].self, from: stopsData) {
            stops = decodedStops.map { draftStop in
                EditableStop(
                    locationName: draftStop.locationName,
                    address: draftStop.address,
                    addressComponents: draftStop.addressComponents,
                    latitude: draftStop.latitude,
                    longitude: draftStop.longitude,
                    notes: draftStop.notes,
                    order: draftStop.order
                )
            }
        }
    }
    
    private func saveDraftState() {
        // Save category
        savedCategory = selectedCategory?.rawValue ?? ""
        
        // Save region
        savedRegion = selectedRegion?.rawValue ?? ""
        
        // Save cost
        savedCost = selectedCostLevel?.rawValue ?? ""
        
        // Save noise level
        savedNoiseLevel = noiseLevel
        
        // Save stops to UserDefaults
        let draftStops = stops.map { stop in
            DraftStop(
                locationName: stop.locationName,
                address: stop.address,
                addressComponents: stop.addressComponents,
                latitude: stop.latitude,
                longitude: stop.longitude,
                notes: stop.notes,
                order: stop.order
            )
        }
        
        if let encoded = try? JSONEncoder().encode(draftStops) {
            UserDefaults.standard.set(encoded, forKey: "draftItineraryStops")
        }
    }
    
    private func deleteStops(at offsets: IndexSet) {
        stops.remove(atOffsets: offsets)
        // Reorder stops
        for (index, _) in stops.enumerated() {
            stops[index].order = index + 1
        }
        saveDraftState()
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
        
        guard let category = selectedCategory, category != .all else {
            errorMessage = "Please select a category"
            showError = true
            return
        }
        
        guard let region = selectedRegion, region != .all else {
            errorMessage = "Please select a region"
            showError = true
            return
        }
        
        guard let costLevel = selectedCostLevel else {
            errorMessage = "Please select a cost level"
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
                if let coordinate = coordinate,
                   !coordinate.latitude.isNaN && !coordinate.longitude.isNaN,
                   !coordinate.latitude.isInfinite && !coordinate.longitude.isInfinite {
                    stops[index].latitude = coordinate.latitude
                    stops[index].longitude = coordinate.longitude
                } else {
                    // Use default Philadelphia coordinates if geocoding fails
                    stops[index].latitude = 39.9526
                    stops[index].longitude = -75.1652
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
            
            // Get current user info
            guard let currentUser = self.authViewModel.currentUser else {
                self.isLoading = false
                self.errorMessage = "You must be logged in to create an itinerary."
                self.showError = true
                return
            }
            
            // Generate itinerary ID first (needed for photo upload path)
            let itineraryID = UUID().uuidString
            
            // Upload photos if any are selected
            if !self.selectedPhotos.isEmpty {
                self.uploadPhotos(itineraryID: itineraryID, userID: currentUser.id) { photoURLs in
                    // Create new itinerary with uploaded photo URLs
                    let newItinerary = Itinerary(
                        id: itineraryID,
                        title: self.title.trimmingCharacters(in: .whitespaces),
                        description: self.description.trimmingCharacters(in: .whitespaces),
                        category: category,
                        authorID: currentUser.id,
                        authorName: currentUser.name,
                        authorHandle: currentUser.handle,
                        authorProfileImageURL: currentUser.profileImageURL,
                        stops: convertedStops,
                        photos: photoURLs,
                        likes: 0,
                        comments: 0,
                        timeEstimate: Int(self.timeEstimate),
                        cost: costLevel.numericValue,
                        costLevel: costLevel,
                        noiseLevel: self.currentNoiseLevel,
                        region: region
                    )
                    
                    // Add to shared manager
                    self.itinerariesManager.addItinerary(newItinerary)
                    self.isLoading = false
                    
                    // Clear draft state after successful submission
                    self.clearDraftState()
                    
                    self.dismiss()
                }
            } else {
                // No photos to upload, create itinerary directly
                let newItinerary = Itinerary(
                    id: itineraryID,
                    title: self.title.trimmingCharacters(in: .whitespaces),
                    description: self.description.trimmingCharacters(in: .whitespaces),
                    category: category,
                    authorID: currentUser.id,
                    authorName: currentUser.name,
                    authorHandle: currentUser.handle,
                    authorProfileImageURL: currentUser.profileImageURL,
                    stops: convertedStops,
                    photos: [],
                    likes: 0,
                    comments: 0,
                    timeEstimate: Int(self.timeEstimate),
                    cost: costLevel.numericValue,
                    costLevel: costLevel,
                    noiseLevel: self.currentNoiseLevel,
                    region: region
                )
                
                // Add to shared manager
                self.itinerariesManager.addItinerary(newItinerary)
                self.isLoading = false
                
                // Clear draft state after successful submission
                self.clearDraftState()
                
                self.dismiss()
            }
        }
    }
    
    private func uploadPhotos(itineraryID: String, userID: String, completion: @escaping ([String]) -> Void) {
        guard !selectedPhotos.isEmpty else {
            completion([])
            return
        }
        
        let uploadGroup = DispatchGroup()
        var uploadedImages: [UIImage] = []
        
        // Convert PhotosPickerItems to UIImage
        for photoItem in selectedPhotos {
            uploadGroup.enter()
            Task {
                if let data = try? await photoItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        uploadedImages.append(image)
                    }
                }
                uploadGroup.leave()
            }
        }
        
        uploadGroup.notify(queue: .main) {
            guard !uploadedImages.isEmpty else {
                completion([])
                return
            }
            
            // Upload images to Firebase Storage
            let basePath = "itineraries/\(userID)/\(itineraryID)"
            
            StorageHelper.shared.uploadImages(uploadedImages, basePath: basePath) { result in
                switch result {
                case .success(let urls):
                    completion(urls)
                case .failure(let error):
                    print("Error uploading photos: \(error.localizedDescription)")
                    completion([]) // Continue with empty photos array if upload fails
                }
            }
        }
    }
    
    private func clearDraftState() {
        title = ""
        description = ""
        savedCategory = ""
        savedRegion = ""
        savedCost = ""
        savedNoiseLevel = 2.0
        timeEstimate = 2
        selectedCategory = nil
        selectedRegion = nil
        selectedCostLevel = nil
        noiseLevel = 2.0
        stops = []
        UserDefaults.standard.removeObject(forKey: "draftItineraryStops")
    }
}

// MARK: - Draft Stop (for UserDefaults encoding)
struct DraftStop: Codable {
    let locationName: String
    let address: String
    let addressComponents: Address?
    let latitude: Double
    let longitude: Double
    let notes: String?
    let order: Int
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
