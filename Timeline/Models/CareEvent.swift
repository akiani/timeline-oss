// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

/// A single patient event derived from a FHIR resource (e.g., lab, procedure).
class CareEvent: Identifiable, ObservableObject, Codable {
    let id: String
    let date: String
    let title: String
    let resourceType: String
    let fhirResourceId: String
    @Published var isGeneratingTimeline: Bool = false
    @Published var timelineEvent: IndividualTimelineEvent?
    
    /// Parse the `date` string (YYYY-MM-DD) into a Date for sorting/formatting.
    var displayDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    init(id: String, date: String, title: String, resourceType: String, fhirResourceId: String) {
        self.id = id
        self.date = date
        self.title = title
        self.resourceType = resourceType
        self.fhirResourceId = fhirResourceId
    }
    
    enum CodingKeys: String, CodingKey {
        case id, date, title, resourceType, fhirResourceId
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        date = try container.decode(String.self, forKey: .date)
        title = try container.decode(String.self, forKey: .title)
        resourceType = try container.decode(String.self, forKey: .resourceType)
        fhirResourceId = try container.decode(String.self, forKey: .fhirResourceId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(title, forKey: .title)
        try container.encode(resourceType, forKey: .resourceType)
        try container.encode(fhirResourceId, forKey: .fhirResourceId)
    }
}
