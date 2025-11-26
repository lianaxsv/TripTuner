//
//  TripTunerApp.swift
//  TripTuner
//
//  Created by Liana Veerasamy on 11/18/25.
//

import SwiftUI

@main
struct TripTunerApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
