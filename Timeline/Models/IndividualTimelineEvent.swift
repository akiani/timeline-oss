// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation

/// AI-generated narrative for a specific care event cluster.
struct IndividualTimelineEvent: Codable {
    let title: String
    let description: String
    let icon: String
    let artifacts: [FHIRArtifact]
    
    init(title: String, description: String, icon: String, artifacts: [FHIRArtifact] = []) {
        self.title = title
        self.description = description
        self.icon = icon
        self.artifacts = artifacts
    }
}
