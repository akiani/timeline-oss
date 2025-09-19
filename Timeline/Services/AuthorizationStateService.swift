// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import Combine

/// Service to manage both onboarding state and HealthKit authorization
class AuthorizationStateService: ObservableObject {
    static let shared = AuthorizationStateService()
    
    private let healthKitService: HealthKitService
    
    // UserDefaults key
    private let hasSeenOnboardingKey = "hasSeenOnboarding"
    
    // Published properties for UI
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: hasSeenOnboardingKey)
        }
    }
    
    @Published var isHealthKitAuthorized: Bool = false
    
    // Private initializer for singleton
    private init(healthKitService: HealthKitService? = nil) {
        self.healthKitService = healthKitService ?? .shared
        // Load persisted value
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
        
        // Check HealthKit authorization on init
        updateHealthKitAuthorization()
        
    }
    
    // MARK: - Onboarding State Management
    
    /// Mark that the user has completed onboarding.
    func markOnboardingSeen() {
        hasSeenOnboarding = true
    }
    
    /// Reset onboarding state (useful for testing).
    func resetOnboardingState() {
        hasSeenOnboarding = false
    }
    
    // MARK: - HealthKit Authorization Management
    
    /// Update the HealthKit authorization status using a lightweight query probe.
    func updateHealthKitAuthorization() {
        // Use the actual query test to verify access, not just authorization status
        healthKitService.canAccessHealthRecords { [weak self] hasAccess in
            DispatchQueue.main.async {
                self?.isHealthKitAuthorized = hasAccess
            }
        }
    }
    
    /// Request HealthKit authorization and refresh local authorization state on success.
    func requestHealthKitAuthorization() async {
        await withCheckedContinuation { continuation in
            healthKitService.requestHealthKitAuthorization { success, error in
                if success {
                    self.updateHealthKitAuthorization()
                }
                continuation.resume()
            }
        }
    }
}
