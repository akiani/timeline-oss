// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import EventKit
import UIKit

@MainActor
class RemindersService: ObservableObject {
    static let shared = RemindersService()
    
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    private init() {
        updateAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Refresh cached Reminders authorization status.
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    }
    
    /// Request access to Reminders, returning whether creation is permitted.
    /// Throws when access is explicitly denied or unknown.
    func requestRemindersAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        
        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            throw RemindersError.accessDenied
        case .notDetermined:
            return try await requestAuthorization()
        case .fullAccess:
            return true
        case .writeOnly:
            return true // Write-only access is sufficient for creating reminders
        @unknown default:
            throw RemindersError.unknownAuthorizationStatus
        }
    }
    
    private func requestAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            if #available(iOS 17.0, *) {
                eventStore.requestFullAccessToReminders { granted, error in
                    DispatchQueue.main.async {
                        self.updateAuthorizationStatus()
                        
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
            } else {
                eventStore.requestAccess(to: .reminder) { granted, error in
                    DispatchQueue.main.async {
                        self.updateAuthorizationStatus()
                        
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Reminders Creation
    
    /// Create a single reminder for a doctor question.
    /// - Returns: The reminder identifier for future removal.
    func createSingleDoctorQuestionReminder(
        question: DoctorQuestion,
        clusterDate: String
    ) async throws -> String {
        // Request access first
        let hasAccess = try await requestRemindersAccess()
        guard hasAccess else {
            throw RemindersError.accessDenied
        }
        
        // Create or find the calendar for our reminders
        let calendar = try findOrCreateRemindersCalendar()
        
        // Create reminder
        let reminder = EKReminder(eventStore: eventStore)
        
        // Set basic properties - just the question itself
        reminder.title = question.question
        reminder.calendar = calendar
        
        // Save reminder
        try eventStore.save(reminder, commit: true)
        
        // Return the identifier for later removal
        return reminder.calendarItemIdentifier
    }
    
    /// Remove a previously created doctor question reminder by identifier.
    func removeDoctorQuestionReminder(reminderID: String) async throws {
        // Request access first
        let hasAccess = try await requestRemindersAccess()
        guard hasAccess else {
            throw RemindersError.accessDenied
        }
        
        // Find and remove the reminder
        if let reminder = eventStore.calendarItem(withIdentifier: reminderID) as? EKReminder {
            try eventStore.remove(reminder, commit: true)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Find an existing or create a new calendar to store reminders.
    private func findOrCreateRemindersCalendar() throws -> EKCalendar {
        let calendarTitle = "Yari Questions"
        
        // First, try to find existing calendar
        let calendars = eventStore.calendars(for: .reminder)
        if let existingCalendar = calendars.first(where: { $0.title == calendarTitle }) {
            return existingCalendar
        }
        
        // Create new calendar if not found
        let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        newCalendar.title = calendarTitle
        newCalendar.cgColor = UIColor.systemBlue.cgColor
        
        // Find default source for reminders
        guard let source = eventStore.defaultCalendarForNewReminders()?.source ??
                          eventStore.sources.first(where: { $0.sourceType == .local }) else {
            throw RemindersError.noValidSource
        }
        
        newCalendar.source = source
        
        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }
    
    
    // MARK: - Utility Methods
    
    /// Open the Reminders app if installed.
    func openRemindersApp() {
        if let remindersURL = URL(string: "x-apple-reminderkit://") {
            if UIApplication.shared.canOpenURL(remindersURL) {
                UIApplication.shared.open(remindersURL)
            }
        }
    }
    
    /// Indicate whether the app currently has permission to create reminders.
    func canCreateReminders() -> Bool {
        if #available(iOS 17.0, *) {
            return authorizationStatus == .fullAccess || authorizationStatus == .writeOnly
        } else {
            return authorizationStatus == .authorized
        }
    }
}

// MARK: - Error Types

enum RemindersError: LocalizedError {
    case accessDenied
    case noValidSource
    case unknownAuthorizationStatus
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to Reminders was denied. Please grant access in Settings > Privacy & Security > Reminders."
        case .noValidSource:
            return "No valid calendar source found for creating reminders."
        case .unknownAuthorizationStatus:
            return "Unknown authorization status for Reminders access."
        case .saveFailed(let error):
            return "Failed to save reminders: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return "Go to Settings > Privacy & Security > Reminders and enable access for Timeline."
        case .noValidSource:
            return "Please ensure you have a valid Reminders account set up on your device."
        case .unknownAuthorizationStatus:
            return "Please restart the app and try again."
        case .saveFailed:
            return "Please try again. If the issue persists, restart the app."
        }
    }
}
