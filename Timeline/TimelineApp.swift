// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI
import HealthKit
import FirebaseCore
import FirebaseVertexAI
import FirebaseAppCheck

class YourAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    #if targetEnvironment(simulator)
    // Use the debug provider on the simulator.
    return AppCheckDebugProvider(app: app)
    #else
    // Use App Attest on physical devices.
    return AppAttestProvider(app: app)
    #endif
  }
}

@main
struct TimelineApp: App {
    // Initialize services early in the app lifecycle
    @StateObject private var healthKitService = HealthKitService.shared
    @StateObject private var timelineService = FHIRTimelineService.shared
    @StateObject private var authorizationStateService = AuthorizationStateService.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var didCheckForMockData = false
    
    init() {
        #if targetEnvironment(simulator)
        // Set the debug token in your app's launch arguments.
        // Go to Product > Scheme > Edit Scheme > Run > Arguments > Arguments Passed On Launch
        // and add `FIRAAppCheckDebugToken` as the name and the token from the console as the value.
        #endif
        
        // Configure Firebase
        AppCheck.setAppCheckProviderFactory(YourAppCheckProviderFactory())
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(timelineService)
                .environmentObject(healthKitService)
                .environmentObject(authorizationStateService)
                .preferredColorScheme(.light)
                .onAppear {
                    if !didCheckForMockData {
                        if ProcessInfo.processInfo.arguments.contains("--use-mock-data") {
                            timelineService.loadColonCancerMockData()
                        }
                        didCheckForMockData = true
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    // Handle scene phase changes
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Always check authorization when app becomes active
            authorizationStateService.updateHealthKitAuthorization()
        case .background, .inactive:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Main App View

struct RootView: View {
    @EnvironmentObject private var timelineService: FHIRTimelineService
    @EnvironmentObject private var authorizationStateService: AuthorizationStateService
    @State private var hasShownSplash = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // Show splash only for users who need to see ContentView (onboarding/permission)
            let needsContentView = !authorizationStateService.hasSeenOnboarding || !authorizationStateService.isHealthKitAuthorized
            
            if showSplash && needsContentView {
                SplashScreen(onComplete: {
                    withAnimation {
                        showSplash = false
                        hasShownSplash = true
                    }
                })
            } else {
                // Navigation based on onboarding and authorization status
                if !authorizationStateService.hasSeenOnboarding {
                    // First-time users see onboarding
                    OnboardingView()
                } else if authorizationStateService.isHealthKitAuthorized {
                    // Returning users with authorization see timeline directly (no splash)
                    TimelineView()
                } else {
                    // Returning users without authorization see permission request
                    OnboardingView()
                }
            }
        }
    }
}
