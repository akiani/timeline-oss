// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import FirebaseVertexAI
import SwiftUI

// MARK: - Care Cluster Summarization Service

@MainActor
class ClusterSummarizationService: ObservableObject {
    static let shared = ClusterSummarizationService()
    
    private let geminiService: GeminiService
    
    init(geminiService: GeminiService? = nil) {
        self.geminiService = geminiService ?? .shared
    }
    
    // MARK: - Public Methods
    
    /// Generate summary for a care cluster at a specific literacy level
    func generateSummary(
        for cluster: CareEventCluster,
        at literacyLevel: LiteracyLevel,
        fhirResources: [String: Any]
    ) async throws -> ClusterSummaryResponse {
        
        // Build FHIR resources JSON string with sorted ordering for consistent caching
        var fhirResourcesJson = ""
        
        // Sort events by fhirResourceId for deterministic ordering
        let sortedEvents = cluster.events.sorted { $0.fhirResourceId < $1.fhirResourceId }
        
        for event in sortedEvents {
            if let resource = fhirResources[event.fhirResourceId] {
                // Use sortedKeys option for deterministic JSON serialization
                if let jsonData = try? JSONSerialization.data(withJSONObject: resource, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    fhirResourcesJson += "\n\n--- Resource ID: \(event.fhirResourceId) ---\n"
                    fhirResourcesJson += jsonString
                }
            }
        }
        
        let prompt = createPromptForLiteracyLevel(
            literacyLevel: literacyLevel,
            date: cluster.date,
            fhirResourcesJson: fhirResourcesJson
        )
        
        let schema = createSummaryResponseSchema()
        
        let response = try await geminiService.generateStructuredContent(
            prompt: prompt,
            responseType: ClusterSummaryResponse.self,
            schema: schema,
            modelName: PromptsConfiguration.ModelNames.clusterSummary,
            usageDescription: PromptsConfiguration.UsageDescriptions.clusterSummary(
                date: cluster.date,
                literacyLevel: literacyLevel.displayName
            )
        )
        
        return response
    }
    
    // MARK: - Private Methods
    
    private func createPromptForLiteracyLevel(
        literacyLevel: LiteracyLevel,
        date: String,
        fhirResourcesJson: String
    ) -> String {
        switch literacyLevel {
        case .everyday:
            return PromptsConfiguration.everydayLanguageSummaryPrompt(
                date: date,
                fhirResourcesJson: fhirResourcesJson
            )
        case .slightlyTechnical:
            return PromptsConfiguration.slightlyTechnicalSummaryPrompt(
                date: date,
                fhirResourcesJson: fhirResourcesJson
            )
        case .doctorLanguage:
            return PromptsConfiguration.doctorLanguageSummaryPrompt(
                date: date,
                fhirResourcesJson: fhirResourcesJson
            )
        }
    }
    
    private func createSummaryResponseSchema() -> Schema {
        return Schema.object(properties: [
            "events": Schema.array(
                items: Schema.object(properties: [
                    "headline": Schema.string(description: "5-8 word headline for the event"),
                    "subheadline": Schema.string(description: "10-12 word subheadline providing more context"),
                    "body": Schema.string(description: "Longer descriptive text in markdown format (bold, italic only)")
                ])
            )
        ])
    }
}
