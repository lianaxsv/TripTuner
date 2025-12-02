//
//  Stop.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import CoreLocation

struct Stop: Identifiable, Codable {
    let id: String
    var locationName: String
    var address: String
    var addressComponents: Address?
    var latitude: Double
    var longitude: Double
    var notes: String?
    var order: Int
    
    var coordinate: CLLocationCoordinate2D {
        // Validate coordinates to prevent NaN errors
        let validLat = latitude.isNaN || latitude.isInfinite ? 39.9526 : latitude
        let validLon = longitude.isNaN || longitude.isInfinite ? -75.1652 : longitude
        return CLLocationCoordinate2D(latitude: validLat, longitude: validLon)
    }
    
    var isValidCoordinate: Bool {
        !latitude.isNaN && !latitude.isInfinite && 
        !longitude.isNaN && !longitude.isInfinite &&
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }
    
    init(id: String = UUID().uuidString,
         locationName: String,
         address: String,
         addressComponents: Address? = nil,
         latitude: Double,
         longitude: Double,
         notes: String? = nil,
         order: Int) {
        self.id = id
        self.locationName = locationName
        self.address = address
        self.addressComponents = addressComponents
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.order = order
    }
}

