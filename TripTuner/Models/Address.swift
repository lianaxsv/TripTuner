//
//  Address.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation

struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    
    var fullAddress: String {
        "\(street), \(city), \(state) \(zipCode)"
    }
    
    init(street: String = "", city: String = "Philadelphia", state: String = "PA", zipCode: String = "") {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
    }
}

