//
//  TripTunerApp.swift
//  TripTuner
//
//  Created by Liana Veerasamy on 11/18/25.
//

import SwiftUI
import FirebaseCore
import UIKit
import SwiftUI
import FirebaseCore
import UIKit
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct TripTunerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        // Reload itineraries when user logs in
                        ItinerariesManager.shared.reloadItineraries()
                        // Load blocked users for content moderation
                        ContentModerationManager.shared.loadBlockedUsers()
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .onAppear {
                        // Clear itineraries and listener when user logs out
                        ItinerariesManager.shared.clearItineraries()
                    }
            }
        }
    }
}
