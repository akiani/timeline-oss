// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import HealthKit

/// Fetches HealthKit clinical records and converts to FHIR JSON with metadata
/// Fetches clinical records, converts them to FHIR JSON, and applies token-based truncation.
final class FHIRResourceService {
    private let healthKitService: HealthKitService
    private let mapping: FHIRMappingService
    private let safeInputTokens: Int

    init(healthKitService: HealthKitService, mapping: FHIRMappingService, safeInputTokens: Int) {
        self.healthKitService = healthKitService
        self.mapping = mapping
        self.safeInputTokens = safeInputTokens
    }

    /// Fetch and assemble a dictionary of FHIR resources keyed by FHIR `id` (or HK UUID).
    func fetchFHIRResources() async throws -> [String: Any] {
        mapping.reset()

        var allRecordsWithMetadata: [(json: [String: Any], record: HKClinicalRecord, date: Date?, typeId: String)] = []

        try await withThrowingTaskGroup(of: (String, [[String: Any]], [HKClinicalRecord]).self) { group in
            for typeIdentifier in healthKitService.allClinicalTypeIdentifiers {
                guard let clinicalType = HKObjectType.clinicalType(forIdentifier: typeIdentifier) else { continue }
                group.addTask { [healthKitService] in
                    let samples = try await Self.fetchClinicalRecords(for: clinicalType, via: healthKitService)
                    var records: [[String: Any]] = []
                    var original: [HKClinicalRecord] = []
                    for rec in samples {
                        if let data = rec.fhirResource?.data,
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            records.append(json)
                            original.append(rec)
                        }
                    }
                    return (typeIdentifier.rawValue, records, original)
                }
            }
            for try await (typeId, records, originals) in group {
                for (i, json) in records.enumerated() where i < originals.count {
                    let record = originals[i]
                    let date = record.startDate
                    allRecordsWithMetadata.append((json: json, record: record, date: date, typeId: typeId))
                }
            }
        }

        // filter out vitals
        let nonVitals = allRecordsWithMetadata.filter { $0.typeId != HKClinicalTypeIdentifier.vitalSignRecord.rawValue }
        // sort newest first
        let sorted = nonVitals.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }

        var recordsToInclude = sorted
        if sorted.count > 1000 {
            var totalTokens = 0
            var included: [(json: [String: Any], record: HKClinicalRecord, date: Date?, typeId: String)] = []
            for meta in sorted {
                if let data = try? JSONSerialization.data(withJSONObject: meta.json, options: [.sortedKeys]),
                   let jsonString = String(data: data, encoding: .utf8) {
                    let recordTokens = jsonString.count / 4
                    if totalTokens + recordTokens <= safeInputTokens {
                        totalTokens += recordTokens
                        included.append(meta)
                    } else {
                        break
                    }
                }
            }
            recordsToInclude = included
        }

        var fhirResources: [String: Any] = [:]
        for meta in recordsToInclude {
            let record = meta.record
            let json = meta.json
            let key = (json["id"] as? String) ?? record.uuid.uuidString
            fhirResources[key] = json
            mapping.storeClinicalRecord(record, fhirId: key)
        }
        return fhirResources
    }

    /// Fetch raw clinical records for a given sample type via the provided HealthKit service.
    static func fetchClinicalRecords(for clinicalType: HKSampleType, via healthKitService: HealthKitService) async throws -> [HKClinicalRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: clinicalType,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { (_, samples, error) in
                if let error = error { continuation.resume(throwing: error); return }
                guard let clinical = samples as? [HKClinicalRecord] else { continuation.resume(returning: []) ; return }
                continuation.resume(returning: clinical)
            }
            healthKitService.executeQuery(query)
        }
    }
}
