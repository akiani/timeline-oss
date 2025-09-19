// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import HealthKit

/// Manages mapping between FHIR resource IDs and HealthKit records
/// In-memory mapping between FHIR resource IDs and HealthKit records.
final class FHIRMappingService {
    private var fhirToHealthKitMap: [String: String] = [:]
    private var clinicalRecordCache: [String: HKClinicalRecord] = [:]

    /// Clear all cached mappings and records.
    func reset() {
        fhirToHealthKitMap.removeAll()
        clinicalRecordCache.removeAll()
    }

    /// Store an association between a HealthKit record and FHIR ID.
    func storeClinicalRecord(_ record: HKClinicalRecord, fhirId: String) {
        let uuidString = record.uuid.uuidString
        fhirToHealthKitMap[fhirId] = uuidString
        clinicalRecordCache[uuidString] = record
    }

    /// Get the HealthKit UUID string for a FHIR ID.
    func getHealthKitId(for fhirId: String) -> String? {
        fhirToHealthKitMap[fhirId]
    }

    /// Get the cached HealthKit record for a FHIR ID.
    func getHealthKitRecord(for fhirId: String) -> HKClinicalRecord? {
        guard let uuidString = getHealthKitId(for: fhirId) else { return nil }
        return clinicalRecordCache[uuidString]
    }
}
