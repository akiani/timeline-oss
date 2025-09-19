// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import FirebaseVertexAI

// MARK: - Data Models

struct DoctorQuestionsList: Codable {
    let questions: [DoctorQuestion]
}

struct DoctorQuestion: Codable, Identifiable {
    let id = UUID()
    let question: String
    let category: String
    let priority: String
    let whyAsk: String
    var isInReminders: Bool = false
    var reminderID: String? // Store EventKit reminder ID for removal
    
    // Custom coding keys to exclude UI state from Codable
    private enum CodingKeys: String, CodingKey {
        case question, category, priority, whyAsk
    }
    
    init(question: String, category: String, priority: String, whyAsk: String, isInReminders: Bool = false, reminderID: String? = nil) {
        self.question = question
        self.category = category
        self.priority = priority
        self.whyAsk = whyAsk
        self.isInReminders = isInReminders
        self.reminderID = reminderID
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        question = try container.decode(String.self, forKey: .question)
        category = try container.decode(String.self, forKey: .category)
        priority = try container.decode(String.self, forKey: .priority)
        whyAsk = try container.decode(String.self, forKey: .whyAsk)
        isInReminders = false // Default UI state
        reminderID = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(question, forKey: .question)
        try container.encode(category, forKey: .category)
        try container.encode(priority, forKey: .priority)
        try container.encode(whyAsk, forKey: .whyAsk)
    }
}

enum QuestionCategory: String, CaseIterable {
    case symptoms = "symptoms"
    case tests = "tests"
    case treatment = "treatment"
    case followUp = "follow_up"
    case lifestyle = "lifestyle"
    
    var displayName: String {
        switch self {
        case .symptoms:
            return "Symptoms"
        case .tests:
            return "Tests & Results"
        case .treatment:
            return "Treatment"
        case .followUp:
            return "Follow-up"
        case .lifestyle:
            return "Lifestyle"
        }
    }
    
}

enum QuestionPriority: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    
    var sortOrder: Int {
        switch self {
        case .high:
            return 0
        case .medium:
            return 1
        case .low:
            return 2
        }
    }
}

// MARK: - Doctor Questions Service

@MainActor
class DoctorQuestionsService: ObservableObject {
    static let shared = DoctorQuestionsService()
    
    private let geminiService: GeminiService
    private let fhirService: FHIRTimelineService
    
    init(geminiService: GeminiService? = nil,
         fhirService: FHIRTimelineService? = nil) {
        self.geminiService = geminiService ?? .shared
        self.fhirService = fhirService ?? .shared
    }
    
    /// Generate doctor questions for a specific care event cluster using structured data
    func generateDoctorQuestions(for cluster: CareEventCluster, excludingQuestions: [DoctorQuestion] = []) async throws -> [DoctorQuestion] {
        // Collect FHIR resources for this cluster
        var clusterResources: [String: Any] = [:]
        for event in cluster.events {
            if let fhirResource = fhirService.fhirResources[event.fhirResourceId] {
                clusterResources[event.fhirResourceId] = fhirResource
            }
        }
        
        // Create the prompt for doctor questions
        let prompt = createDoctorQuestionsPrompt(from: clusterResources, cluster: cluster, existingQuestions: excludingQuestions)
        
        // Create schema for doctor questions response
        let doctorQuestionsSchema = Schema.object(
            properties: [
                "questions": .array(
                    items: .object(
                        properties: [
                            "question": .string(description: "Specific, actionable question to ask the doctor"),
                            "category": .string(description: "Question category: symptoms, tests, treatment, follow_up, or lifestyle"),
                            "priority": .string(description: "Priority level: high, medium, or low"),
                            "whyAsk": .string(description: "Plain language explanation of why this question is important for the patient to ask")
                        ]
                    )
                )
            ]
        )
        
        // Use GeminiService to generate structured questions
        let questionsList = try await geminiService.generateStructuredContent(
            prompt: prompt,
            responseType: DoctorQuestionsList.self,
            schema: doctorQuestionsSchema,
            modelName: PromptsConfiguration.ModelNames.doctorQuestions,
            usageDescription: PromptsConfiguration.UsageDescriptions.doctorQuestions(date: cluster.date)
        )
        
        return questionsList.questions
    }
    
    /// Create prompt for doctor questions generation
    private func createDoctorQuestionsPrompt(from fhirResources: [String: Any], cluster: CareEventCluster, existingQuestions: [DoctorQuestion] = []) -> String {
        // Build FHIR resources JSON string with sorted ordering for consistent caching
        var fhirResourcesJson = ""
        
        // Sort resources by key for deterministic ordering
        let sortedResourceKeys = fhirResources.keys.sorted()
        
        for key in sortedResourceKeys {
            if let resource = fhirResources[key] {
                // Use sortedKeys option for deterministic JSON serialization
                if let jsonData = try? JSONSerialization.data(withJSONObject: resource, options: [.sortedKeys]),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    fhirResourcesJson += "\n\n--- Resource \(key) ---\n"
                    fhirResourcesJson += jsonString
                }
            }
        }
        
        // Get timeline event context if available
        let timelineContext = cluster.timelineEvent?.description ?? "Health events from \(cluster.date)"
        
        return PromptsConfiguration.doctorQuestionsPrompt(
            date: cluster.date,
            fhirResourcesJson: fhirResourcesJson,
            timelineContext: timelineContext,
            existingQuestions: existingQuestions.map { $0.question }
        )
    }
}
