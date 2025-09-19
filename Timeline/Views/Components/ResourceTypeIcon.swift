// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI

enum ResourceTypeIcon {
    static func symbol(for resourceType: String) -> String {
        switch resourceType.lowercased() {
        case "observation":
            return "chart.line.uptrend.xyaxis"
        case "documentreference":
            return "doc.text"
        case "medicationrequest", "medicationstatement":
            return "pills"
        case "immunization":
            return "syringe"
        case "procedure":
            return "cross.case"
        case "encounter":
            return "building.2"
        case "diagnosticreport":
            return "testtube.2"
        case "condition":
            return "heart.text.square"
        case "allergyintolerance":
            return "allergens"
        case "careplan":
            return "list.bullet.rectangle.portrait"
        case "servicerequest":
            return "paperplane"
        case "vitals", "vitalsigns":
            return "waveform.path.ecg"
        default:
            return "doc"
        }
    }
}

