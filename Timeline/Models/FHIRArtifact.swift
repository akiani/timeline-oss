// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

/// A minimal FHIR record reference used for UI associations.
struct FHIRArtifact: Codable, Identifiable {
    let id: String
    let title: String
    let resourceType: String
}
