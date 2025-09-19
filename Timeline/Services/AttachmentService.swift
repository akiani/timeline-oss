// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import HealthKit

/// Extracts and enriches FHIR DocumentReference resources with attachment content
/// Lookup capability for resolving a FHIR resource ID to a HealthKit record.
protocol HealthKitRecordLookup {
    @MainActor func getHealthKitRecord(for fhirId: String) -> HKClinicalRecord?
}

/// Helper to enrich DocumentReference resources with inline or fetched attachment content.
final class AttachmentService {
    private let lookup: HealthKitRecordLookup
    private let healthKitService: HealthKitService

    init(lookup: HealthKitRecordLookup, healthKitService: HealthKitService) {
        self.lookup = lookup
        self.healthKitService = healthKitService
    }

    /// Process all DocumentReference entries and embed decoded attachment text when available.
    func processAttachments(in resources: [String: Any]) async -> [String: Any] {
        var enhanced = resources
        for (key, value) in resources {
            if let dict = value as? [String: Any],
               let type = dict["resourceType"] as? String, type == "DocumentReference" {
                if let enriched = await extractAttachmentContent(from: dict) {
                    enhanced[key] = enriched
                }
            }
        }
        return enhanced
    }

    /// Extract and embed decoded attachment content for a single DocumentReference resource.
    func extractAttachmentContent(from resource: [String: Any]) async -> [String: Any]? {
        var enhanced = resource
        guard let content = resource["content"] as? [[String: Any]], !content.isEmpty else { return nil }
        let resourceId = resource["id"] as? String ?? ""

        if let first = content.first, let attachment = first["attachment"] as? [String: Any] {
            // Inline base64 data
            if let dataString = attachment["data"] as? String, let data = Data(base64Encoded: dataString) {
                if let text = String(data: data, encoding: .utf8) {
                    enhanced["attachment_content"] = text
                    enhanced["has_decoded_attachment"] = true
                    return enhanced
                } else {
                    enhanced["attachment_binary_detected"] = true
                }
            }

            // URL reference — try HealthKit fetch (iOS 17+)
            if let urlString = attachment["url"] as? String {
                enhanced["attachment_url"] = urlString
                if #available(iOS 17.0, *), !resourceId.isEmpty,
                   let clinicalRecord = await MainActor.run(resultType: HKClinicalRecord?.self, body: { lookup.getHealthKitRecord(for: resourceId) }) {
                    do {
                        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
                            healthKitService.fetchAttachmentData(for: clinicalRecord) { data, error in
                                if let error = error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume(returning: data)
                                }
                            }
                        }
                        if let data = data, let text = String(data: data, encoding: .utf8) {
                            enhanced["attachment_content"] = text
                            enhanced["has_decoded_attachment"] = true
                        }
                    } catch {
                        // Best-effort — leave as is
                    }
                }
            }
        }

        return enhanced
    }

    /// Return only the decoded attachment text (if any) for a DocumentReference.
    func extractAttachmentText(from resource: [String: Any]) async -> String? {
        // Inline base64 data path
        if let content = resource["content"] as? [[String: Any]],
           let first = content.first,
           let attachment = first["attachment"] as? [String: Any],
           let dataString = attachment["data"] as? String,
           let data = Data(base64Encoded: dataString),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        // HealthKit fetch path
        if #available(iOS 17.0, *),
           let id = resource["id"] as? String,
           let record = await MainActor.run(resultType: HKClinicalRecord?.self, body: { lookup.getHealthKitRecord(for: id) }) {
            do {
                let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
                    healthKitService.fetchAttachmentData(for: record) { data, error in
                        if let error = error { continuation.resume(throwing: error) }
                        else { continuation.resume(returning: data) }
                    }
                }
                if let data = data, let text = String(data: data, encoding: .utf8) { return text }
            } catch {
                return nil
            }
        }
        return nil
    }
}
