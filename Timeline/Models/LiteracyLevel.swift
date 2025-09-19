// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

/// Reading level for AI-generated summaries shown in the UI.
enum LiteracyLevel: String, CaseIterable {
    case everyday = "everyday"
    case slightlyTechnical = "slightly_technical"
    case doctorLanguage = "doctor_language"
    
    /// User-facing label for the literacy level.
    var displayName: String {
        switch self {
        case .everyday:
            return "Simple Language"
        case .slightlyTechnical:
            return "Detailed Language"
        case .doctorLanguage:
            return "Clinical Language"
        }
    }
}
