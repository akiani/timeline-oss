// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

/// Builds user-facing timeline structures from raw FHIR resources
/// Builds CareEvent lists and clusters from raw FHIR resources for UI consumption.
final class TimelineBuilder {
    /// Extract CareEvent rows from raw FHIR resources.
    func extractCareEvents(from fhirData: [String: Any]) -> [CareEvent] {
        var events: [CareEvent] = []
        for (fhirId, resource) in fhirData {
            guard let dict = resource as? [String: Any], let type = dict["resourceType"] as? String else { continue }
            if let date = extractDate(from: dict) {
                let title = makeTitle(from: dict, resourceType: type)
                let event = CareEvent(id: UUID().uuidString, date: date, title: title, resourceType: type, fhirResourceId: fhirId)
                events.append(event)
            }
        }
        return events.sorted { ($0.displayDate ?? .distantPast) > ($1.displayDate ?? .distantPast) }
    }

    /// Group CareEvents by their date string and sort newest first.
    func clusterByDate(_ events: [CareEvent]) -> [CareEventCluster] {
        let grouped = Dictionary(grouping: events) { $0.date }
        var clusters: [CareEventCluster] = []
        for (date, items) in grouped {
            clusters.append(CareEventCluster(date: date, events: items))
        }
        return clusters.sorted { ($0.displayDate ?? .distantPast) > ($1.displayDate ?? .distantPast) }
    }

    /// Resolve a normalized date (YYYY-MM-DD) from common FHIR date fields.
    func extractDate(from resource: [String: Any]) -> String? {
        let fields = ["date", "effectiveDateTime", "recordedDate", "onsetDateTime", "issued", "authoredOn"]
        for key in fields {
            if let value = resource[key] as? String, let normalized = normalizeDate(value) { return normalized }
        }
        return nil
    }

    /// Normalize a variety of date/time string formats to YYYY-MM-DD.
    func normalizeDate(_ input: String) -> String? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        for format in formats {
            let f = DateFormatter(); f.dateFormat = format
            if let date = f.date(from: input) {
                let out = DateFormatter(); out.dateFormat = "yyyy-MM-dd"
                return out.string(from: date)
            }
        }
        return nil
    }

    /// Create a concise title from typical FHIR coding fields or fall back to the resource type.
    func makeTitle(from resource: [String: Any], resourceType: String) -> String {
        if let code = resource["code"] as? [String: Any],
           let coding = code["coding"] as? [[String: Any]],
           let display = coding.first?["display"] as? String { return display }
        if let valueCodeable = resource["valueCodeableConcept"] as? [String: Any],
           let coding = valueCodeable["coding"] as? [[String: Any]],
           let display = coding.first?["display"] as? String { return display }
        if let medication = resource["medicationCodeableConcept"] as? [String: Any],
           let coding = medication["coding"] as? [[String: Any]],
           let display = coding.first?["display"] as? String { return display }
        if let vaccine = resource["vaccineCode"] as? [String: Any],
           let coding = vaccine["coding"] as? [[String: Any]],
           let display = coding.first?["display"] as? String { return display }
        if resourceType == "DocumentReference",
           let type = resource["type"] as? [String: Any],
           let coding = type["coding"] as? [[String: Any]],
           let display = coding.first?["display"] as? String { return display }
        return resourceType.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }
}
