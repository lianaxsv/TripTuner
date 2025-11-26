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
    var latitude: Double
    var longitude: Double
    var notes: String?
    var order: Int
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(id: String = UUID().uuidString,
         locationName: String,
         address: String,
         latitude: Double,
         longitude: Double,
         notes: String? = nil,
         order: Int) {
        self.id = id
        self.locationName = locationName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.notes = notes
        self.order = order
    }
}

