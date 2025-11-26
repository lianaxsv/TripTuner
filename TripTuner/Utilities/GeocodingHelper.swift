//
//  GeocodingHelper.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import CoreLocation
import MapKit

class GeocodingHelper {
    static let shared = GeocodingHelper()
    
    private let geocoder = CLGeocoder()
    
    private init() {}
    
    func geocodeAddress(_ address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        // For Philadelphia addresses, try to parse or use a default location
        // In a real app, you'd use CLGeocoder here
        
        // Check if address contains Philadelphia
        if address.lowercased().contains("philadelphia") || address.lowercased().contains("philly") {
            // Try to extract street address and use geocoding
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    completion(location.coordinate)
                } else {
                    // Default to Center City Philadelphia if geocoding fails
                    completion(CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652))
                }
            }
        } else {
            // If no Philadelphia in address, add it and try again
            let phillyAddress = address + ", Philadelphia, PA"
            geocoder.geocodeAddressString(phillyAddress) { placemarks, error in
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    completion(location.coordinate)
                } else {
                    // Default to Center City Philadelphia
                    completion(CLLocationCoordinate2D(latitude: 39.9526, longitude: -75.1652))
                }
            }
        }
    }
}

