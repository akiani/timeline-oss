// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

/// A group of `CareEvent`s that occurred on the same date.
class CareEventCluster: Identifiable, ObservableObject {
    let id = UUID()
    let date: String
    let events: [CareEvent]
    @Published var isGeneratingTimeline: Bool = false
    @Published var timelineEvent: IndividualTimelineEvent?
    @Published var summaryError: String?
    
    // Literacy-level summaries
    @Published var literacySummaries: [LiteracyLevel: ClusterSummaryResponse] = [:]
    @Published var isGeneratingSummary: [LiteracyLevel: Bool] = [:]
    @Published var summaryErrors: [LiteracyLevel: String] = [:]
    
    /// Parse the `date` string (YYYY-MM-DD) into a Date for sorting/formatting.
    var displayDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
    
    /// Counts of resource types represented by the cluster's events.
    var resourceTypeCounts: [String: Int] {
        let resourceTypes = events.map { $0.resourceType }
        return Dictionary(grouping: resourceTypes, by: { $0 }).mapValues { $0.count }
    }
    
    init(date: String, events: [CareEvent]) {
        self.date = date
        self.events = events
        
        for literacyLevel in LiteracyLevel.allCases {
            isGeneratingSummary[literacyLevel] = false
        }
    }
}
