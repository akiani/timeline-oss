// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import FirebaseVertexAI
import SwiftUI

@MainActor
class ArtifactProcessingService {
    static let shared = ArtifactProcessingService()
    private let geminiService: GeminiService
    private let fhirService: FHIRTimelineService
    private let healthKitService: HealthKitService
    
    init(geminiService: GeminiService? = nil,
         fhirService: FHIRTimelineService? = nil,
         healthKitService: HealthKitService? = nil) {
        self.geminiService = geminiService ?? .shared
        self.fhirService = fhirService ?? .shared
        self.healthKitService = healthKitService ?? .shared
    }
    
    private lazy var attachmentService = AttachmentService(lookup: fhirService, healthKitService: healthKitService)

    /// Process a FHIR artifact to extract text and generate medical term annotations
    func processArtifact(fhirResourceId: String) async throws -> ProcessedArtifact {
        // Get FHIR resource from timeline service
        guard let fhirResourceAny = fhirService.getFHIRResource(id: fhirResourceId),
              let fhirResource = fhirResourceAny as? [String: Any] else {
            throw ArtifactProcessingError.resourceNotFound
        }
        
        // Include attachment content if available
        var enrichedResource = fhirResource
        if let attachmentContent = await attachmentService.extractAttachmentText(from: fhirResource) {
            enrichedResource["_attachmentContent"] = attachmentContent
        }
        
        // Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: enrichedResource, options: [.sortedKeys]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ArtifactProcessingError.invalidFHIRData
        }
        
        // Create schema for artifact processing response
        let artifactProcessingSchema = Schema.object(
            properties: [
                "title": .string(description: "Descriptive title for the document (2-4 words)"),
                "sections": .array(
                    items: .object(properties: [
                        "title": .string(description: "Section title (e.g., 'Findings', 'Procedure Details')"),
                        "content": .string(description: "Actual document text from this section"),
                        "isImportant": .boolean(description: "Whether this section contains critical findings")
                    ])
                ),
                "medicalTerms": .array(
                    items: .object(properties: [
                        "term": .string(description: "Primary medical term that needs explanation"),
                        "explanation": .string(description: "1-2 sentence layperson explanation"),
                        "category": .string(description: "medical_term|procedure|anatomy|measurement|condition|medication"),
                        "alternatives": .array(
                            items: .string(description: "Alternative forms of the term that might appear in text")
                        )
                    ])
                )
            ]
        )
        
        // Generate processed artifact via Gemini
        let prompt = PromptsConfiguration.artifactProcessingPrompt(
            fhirJson: jsonString,
            resourceId: fhirResourceId
        )
        
        do {
            let processedArtifact = try await geminiService.generateStructuredContent(
                prompt: prompt,
                responseType: ProcessedArtifact.self,
                schema: artifactProcessingSchema,
                modelName: PromptsConfiguration.ModelNames.artifactProcessing,
                usageDescription: PromptsConfiguration.UsageDescriptions.artifactProcessing(resourceId: fhirResourceId)
            )
            
            // Validate that we extracted meaningful sections
            guard !processedArtifact.sections.isEmpty else {
                throw ArtifactProcessingError.noTextExtracted
            }
            
            return processedArtifact
            
        } catch {
            if let error = error as? ArtifactProcessingError {
                throw error
            } else {
                throw ArtifactProcessingError.aiProcessingFailed(error.localizedDescription)
            }
        }
    }
    
}


// MARK: - ViewModel

@MainActor
class ArtifactViewerViewModel: ObservableObject {
    @Published var processedArtifact: ProcessedArtifact?
    @Published var isLoading = false
    @Published var error: ArtifactProcessingError?
    
    private let processingService = ArtifactProcessingService.shared
    
    func processArtifact(_ artifact: FHIRArtifact) async {
        isLoading = true
        error = nil
        processedArtifact = nil
        
        do {
            let processed = try await processingService.processArtifact(fhirResourceId: artifact.id)
            self.processedArtifact = processed
        } catch let processingError as ArtifactProcessingError {
            self.error = processingError
        } catch {
            self.error = .aiProcessingFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func retryProcessing(_ artifact: FHIRArtifact) async {
        await processArtifact(artifact)
    }
}
