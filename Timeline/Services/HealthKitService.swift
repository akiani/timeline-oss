// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import HealthKit

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    // Published properties for UI
    @Published var isHealthKitAuthorized = false
    
    // Track if we've received a successful authorization response
    // This helps work around a common iOS issue where status remains sharingDenied 
    // even when user grants permission
    @Published var didReceiveSuccessfulAuthorization = false
    

    
    // Clinical record types to request
    private var clinicalTypesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Add clinical record types
        let clinicalTypes: [HKClinicalTypeIdentifier] = [
            .allergyRecord,
            .conditionRecord,
            .immunizationRecord,
            .labResultRecord,
            .medicationRecord,
            .procedureRecord,
            .vitalSignRecord
        ]
        
        // Add all clinical types to the read set
        for typeIdentifier in clinicalTypes {
            if let clinicalType = HKObjectType.clinicalType(forIdentifier: typeIdentifier) {
                types.insert(clinicalType)
            }
        }
        
        // Add clinical note record for iOS 15+
        if #available(iOS 15.0, *) {
            if let clinicalNoteType = HKObjectType.clinicalType(forIdentifier: .clinicalNoteRecord) {
                types.insert(clinicalNoteType)
            }
        }
        
        return types
    }
    
    // Get all clinical type identifiers as array
    var allClinicalTypeIdentifiers: [HKClinicalTypeIdentifier] {
        var types: [HKClinicalTypeIdentifier] = [
            .allergyRecord,
            .conditionRecord,
            .immunizationRecord,
            .labResultRecord,
            .medicationRecord,
            .procedureRecord,
            .vitalSignRecord
        ]
        
        // Add clinical notes for iOS 15+
        if #available(iOS 15.0, *) {
            types.append(.clinicalNoteRecord)
        }
        
        return types
    }
    
    // Get friendly names for clinical types
    func getFriendlyName(for typeIdentifier: HKClinicalTypeIdentifier) -> String {
        switch typeIdentifier {
        case .allergyRecord:
            return "Allergies"
        case .conditionRecord:
            return "Conditions"
        case .immunizationRecord:
            return "Immunizations"
        case .labResultRecord:
            return "Lab Results"
        case .medicationRecord:
            return "Medications"
        case .procedureRecord:
            return "Procedures"
        case .vitalSignRecord:
            return "Vital Signs"
        case .clinicalNoteRecord:
            return "Clinical Notes"
        default:
            return typeIdentifier.rawValue
        }
    }
    
    // Private initializer for singleton
    private init() {
        // Check current authorization status on initialization
        checkHealthKitAuthorization()
    }
    
    // MARK: - Authorization
    
    /// Quick check if we can access health records by trying a lightweight query
    func canAccessHealthRecords(completion: @escaping (Bool) -> Void) {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        // First check authorization status for clinical records
        guard let allergyType = HKObjectType.clinicalType(forIdentifier: .allergyRecord) else {
            completion(false)
            return
        }
        
        let authStatus = healthStore.authorizationStatus(for: allergyType)
        
        // If explicitly authorized for writing, we likely have read access too
        if authStatus == .sharingAuthorized {
            completion(true)
            return
        }
        
        // For read permissions, Apple doesn't tell us the status directly
        // So we need to try a query to see if it works
        
        let query = HKSampleQuery(
            sampleType: allergyType,
            predicate: nil,
            limit: 1,  // Only fetch 1 record for speed
            sortDescriptors: nil
        ) { _, samples, error in
            DispatchQueue.main.async {
                if error != nil {
                    completion(false)
                } else {
                    // If query succeeds without error, user has granted access
                    completion(true)
                }
            }
        }
        
        healthStore.execute(query)
    }

    
    /// Check current HealthKit authorization status
    func checkHealthKitAuthorization() {
        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.isHealthKitAuthorized = false
            }
            return
        }
        

        
        // Check authorization status for at least one clinical type
        if let allergyType = HKObjectType.clinicalType(forIdentifier: .allergyRecord) {
            let status = healthStore.authorizationStatus(for: allergyType)
            let isSystemAuthorized = (status == .sharingAuthorized)
            
            // Consider either system status or our successful authorization flag
            // This works around the iOS bug where status remains sharingDenied despite user granting access
            let isAuthorized = isSystemAuthorized || self.didReceiveSuccessfulAuthorization
            
            DispatchQueue.main.async {
                self.isHealthKitAuthorized = isAuthorized
            }
        }
    }
    
    /// Request authorization for clinical record types
    func requestHealthKitAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "HealthKitService", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Request authorization - This should trigger the permission dialog
        healthStore.requestAuthorization(toShare: nil, read: clinicalTypesToRead) { [weak self] (success, error) in
            self?.handleAuthorizationResponse(success: success, error: error, completion: completion)
        }
    }
    
    // Helper to handle authorization response
    private func handleAuthorizationResponse(success: Bool, error: Error?, completion: @escaping (Bool, Error?) -> Void) {
        DispatchQueue.main.async {
            if success {
                self.isHealthKitAuthorized = true
                self.didReceiveSuccessfulAuthorization = true
            } else {
                self.didReceiveSuccessfulAuthorization = false
            }
            completion(success, error)
        }
    }
    
    /// Check authorization and request if needed
    func checkAndRequestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        // Check current authorization status
        if isHealthKitAuthorized {
            completion(true)
            return
        }
        
        // Request authorization if not authorized
        requestHealthKitAuthorization { success, _ in
            completion(success)
        }
    }
    
    // MARK: - Public Methods to Access HealthKit Store
    
    /// Execute a HealthKit query (public access method to healthStore)
    func executeQuery(_ query: HKQuery) {
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Clinical Records
    

    
    // MARK: - Document References (iOS 17+)
    

    
    /// Check if a clinical record has document attachments
    @available(iOS 15.0, *)
    func hasAttachment(clinicalRecord: HKClinicalRecord) -> Bool {
        guard let fhirData = clinicalRecord.fhirResource?.data,
              let json = try? JSONSerialization.jsonObject(with: fhirData, options: []),
              let resource = json as? [String: Any],
              let resourceType = resource["resourceType"] as? String,
              resourceType == "DocumentReference" else {
            return false
        }
        
        // Check for content array with attachments
        if let content = resource["content"] as? [[String: Any]] {
            for contentItem in content {
                if let attachment = contentItem["attachment"] as? [String: Any],
                   (attachment["data"] != nil || attachment["url"] != nil) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Fetch attachment data for a document reference (iOS 17+)
    @available(iOS 17.0, *)
    func fetchAttachmentData(for clinicalRecord: HKClinicalRecord, completion: @escaping (Data?, Error?) -> Void) {
        // Get attachment store
        let attachmentStore = HKAttachmentStore(healthStore: healthStore)
        
        // Get attachments asynchronously
        Task {
            do {
                // Get all attachments for this record
                let attachments = try await attachmentStore.attachments(for: clinicalRecord)
                
                if attachments.isEmpty {
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                    return
                }
                
                // Look for specific content types first (HTML, PDF, RTF)
                // Prioritize HTML and text formats which are most common for clinical notes
                var selectedAttachment = attachments[0] // Default to first
                
                for attachment in attachments {
                    if let metadataItems = attachment.metadata {
                        for item in metadataItems {
                            if item.key == "HKAttachmentContentType" {
                                if let contentType = item.value as? String {
                                    // Prioritize HTML and text formats
                                    if contentType.contains("html") || 
                                       contentType.contains("text/html") {
                                        selectedAttachment = attachment
                                        break
                                    } else if contentType.contains("rtf") {
                                        selectedAttachment = attachment
                                    } else if contentType.contains("pdf") && selectedAttachment == attachments[0] {
                                        // Prefer PDF over unknown types, but HTML/RTF over PDF
                                        selectedAttachment = attachment
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Get the selected attachment's data
                let dataReader = attachmentStore.dataReader(for: selectedAttachment)
                let data = try await dataReader.data
                
                // Extract content type from metadata if available
                var contentType = "application/octet-stream" // Default
                if let metadataItems = selectedAttachment.metadata {
                    for item in metadataItems {
                        if item.key == "HKAttachmentContentType", 
                           let value = item.value as? String {
                            contentType = value
                            break
                        }
                    }
                }
                
                // For RTF content, ensure we have proper data handling
                if contentType.contains("rtf") {
                    // RTF data should be intact as binary data
                    DispatchQueue.main.async {
                        completion(data, nil)
                    }
                    return
                }
                
                // For HTML, check if it needs any processing
                if contentType.contains("html") || detectHTMLContent(in: data) {
                    // Return as-is for the WebView in FHIRRecordView to handle
                    DispatchQueue.main.async {
                        completion(data, nil)
                    }
                    return
                }
                
                // For other types, return as is
                DispatchQueue.main.async {
                    completion(data, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
    }
    
    /// Helper to detect HTML content regardless of content type
    private func detectHTMLContent(in data: Data) -> Bool {
        // Try to convert to string
        guard let string = String(data: data, encoding: .utf8) else {
            return false
        }
        
        // Check for common HTML tags
        let containsHTMLTags = string.contains("<html") || 
                              string.contains("<div") || 
                              string.contains("<span") || 
                              string.contains("<p>") ||
                              string.contains("<body")
        
        return containsHTMLTags
    }
    
    /// Get content type of attachment data
    func determineContentType(for data: Data) -> String {
        // Try to determine content type from data
        if data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]) { // %PDF
            return "application/pdf"
        } else if let text = String(data: data.prefix(100), encoding: .utf8) {
            if text.hasPrefix("<?xml") {
                return "application/xml"
            } else if text.hasPrefix("<html") || text.contains("<html") {
                return "text/html"
            } else if text.hasPrefix("{") && (text.contains("\"resourceType\"") || text.contains("\"Resource\"")) {
                return "application/fhir+json"
            } else if text.hasPrefix("{") {
                return "application/json"
            }
        }
        
        // Default fallback
        return "application/octet-stream"
    }
} 
