//
//  TripTunerApp.swift
//  TripTuner
//
//  Created by Liana Veerasamy on 11/18/25.
//

import SwiftUI

@main
struct TripTunerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
