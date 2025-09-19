// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import UIKit

// MARK: - Medical Term Annotation Models

struct MedicalTermAnnotation: Codable, Identifiable, Equatable {
    let id = UUID()
    let term: String         // The medical term (no positioning needed)
    let explanation: String  // Simple layperson explanation
    let category: String     // "medical_term", "procedure", "anatomy", etc.
    let alternatives: [String] // Alternative forms: ["T3", "T3 staging", "T3 tumor"]
    
    // Custom coding keys to exclude UI state from Codable
    private enum CodingKeys: String, CodingKey {
        case term, explanation, category, alternatives
    }
    
    init(term: String, explanation: String, category: String, alternatives: [String] = []) {
        self.term = term
        self.explanation = explanation
        self.category = category
        self.alternatives = alternatives
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        term = try container.decode(String.self, forKey: .term)
        explanation = try container.decode(String.self, forKey: .explanation)
        category = try container.decode(String.self, forKey: .category)
        alternatives = try container.decodeIfPresent([String].self, forKey: .alternatives) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(term, forKey: .term)
        try container.encode(explanation, forKey: .explanation)
        try container.encode(category, forKey: .category)
        try container.encode(alternatives, forKey: .alternatives)
    }
}

struct DocumentSection: Codable, Identifiable {
    let id = UUID()
    let title: String            // Section title (e.g., "Findings", "Procedure Details", "Recommendations")
    let content: String          // Plain text from the document, clinically significant content only
    let isImportant: Bool        // Flag for visual emphasis
    
    private enum CodingKeys: String, CodingKey {
        case title, content, isImportant
    }
}

struct ProcessedArtifact: Codable {
    let title: String
    let sections: [DocumentSection]      // Document sections with titles and content
    let medicalTerms: [MedicalTermAnnotation]
}

// MARK: - Runtime Matching Models

struct MatchedAnnotation {
    let annotation: MedicalTermAnnotation
    let ranges: [NSRange]           // All locations where term appears in text
}

// MARK: - Category Styling

extension MedicalTermAnnotation {
    var categoryColor: UIColor {
        switch category.lowercased() {
        case "medical_term":
            return .systemBlue
        case "procedure":
            return .systemGreen
        case "anatomy":
            return .systemOrange
        case "measurement":
            return .systemPurple
        case "condition":
            return .systemRed
        case "medication":
            return .systemTeal
        default:
            return .systemBlue
        }
    }
    
    var categoryDisplayName: String {
        switch category.lowercased() {
        case "medical_term":
            return "Medical Term"
        case "procedure":
            return "Procedure"
        case "anatomy":
            return "Anatomy"
        case "measurement":
            return "Measurement"
        case "condition":
            return "Condition"
        case "medication":
            return "Medication"
        default:
            return "Medical Term"
        }
    }
}

// MARK: - Processing Errors

enum ArtifactProcessingError: LocalizedError {
    case resourceNotFound
    case invalidFHIRData
    case aiProcessingFailed(String)
    case noTextExtracted
    
    var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return "Medical record not found"
        case .invalidFHIRData:
            return "Invalid medical record format"
        case .aiProcessingFailed(let message):
            return "Processing failed: \(message)"
        case .noTextExtracted:
            return "No readable content found in document"
        }
    }
}
