// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import HealthKit
import FirebaseVertexAI
import Combine

@MainActor
class FHIRTimelineService: ObservableObject {
    /// Orchestrates fetching HealthKit clinical records, enriching FHIR with attachments,
    /// and assembling user-facing care event clusters and AI timelines.
    // MARK: - Properties
    
    static let shared = FHIRTimelineService()
    
    private let healthKitService: HealthKitService
    let geminiService: GeminiService
    
    // Published properties for UI updates

    
    // Care Events (New System)
    @Published var careEventClusters: [CareEventCluster] = []
    @Published var isLoadingCareEvents = false
    @Published var hasAttemptedCareEventsLoad = false
    @Published var isRefreshing = false
    
    // Progressive loading tracking
    @Published var processedClusterCount = 0
    @Published var isLoadingMoreTimelines = false
    
    // Store raw FHIR resources
    @Published var fhirResources: [String: Any] = [:]
    
    // Token limits for Gemini model
    private let safeInputTokens: Int = 900_000 // Leave buffer for safety
    
    // MARK: - Helpers
    private let mapping = FHIRMappingService()
    private lazy var attachments = AttachmentService(lookup: self, healthKitService: healthKitService)
    private let assembler = TimelineBuilder()
    
    /// Store a clinical record with its FHIR id for later retrieval
    /// Store a HealthKit record reference for a given FHIR resource ID.
    /// - Parameters:
    ///   - record: The `HKClinicalRecord` to retain.
    ///   - fhirId: The corresponding FHIR resource identifier.
    func storeClinicalRecord(_ record: HKClinicalRecord, fhirId: String) {
        mapping.storeClinicalRecord(record, fhirId: fhirId)
    }
    
    /// Get HealthKit UUID for a FHIR record ID
    /// Get the HealthKit UUID string that maps to a FHIR resource ID.
    /// - Parameter fhirId: The FHIR resource identifier.
    /// - Returns: The HealthKit UUID string, if available.
    func getHealthKitId(for fhirId: String) -> String? {
        mapping.getHealthKitId(for: fhirId)
    }
    
    /// Get HealthKit clinical record for a FHIR record ID
    /// Get the cached `HKClinicalRecord` for a FHIR resource ID.
    /// - Parameter fhirId: The FHIR resource identifier.
    /// - Returns: The clinical record if present in cache.
    func getHealthKitRecord(for fhirId: String) -> HKClinicalRecord? {
        mapping.getHealthKitRecord(for: fhirId)
    }
    
    // MARK: - Computed Properties for Progressive Loading
    
    var hasMoreClustersToProcess: Bool {
        processedClusterCount < careEventClusters.count
    }
    
    var remainingClustersCount: Int {
        max(0, careEventClusters.count - processedClusterCount)
    }
    
    var displayedClusters: [CareEventCluster] {
        // Return clusters that have been processed or are being processed
        Array(careEventClusters.prefix(processedClusterCount))
    }
    
    // MARK: - Initialization
    
    init(healthKitService: HealthKitService? = nil, geminiService: GeminiService? = nil) {
        self.healthKitService = healthKitService ?? .shared
        self.geminiService = geminiService ?? .shared
    }
    
    // MARK: - Core Methods
    

    

    
    /// Silent version of fetchAndConvertToFHIR that doesn't update UI properties during processing
    private func fetchAndConvertToFHIRSilent() async throws -> [String: Any] {
        let fetcher = FHIRResourceService(healthKitService: healthKitService, mapping: mapping, safeInputTokens: safeInputTokens)
        return try await fetcher.fetchFHIRResources()
    }
    
    /// Process and enhance resources that contain attachments
    private func processAttachments(in resources: [String: Any]) async -> [String: Any] {
        await attachments.processAttachments(in: resources)
    }
    
    /// Extract attachment content from a DocumentReference resource
    private func extractAttachmentContent(from resource: [String: Any]) async -> [String: Any]? {
        await attachments.extractAttachmentContent(from: resource)
    }
    
    /// Helper method to fetch clinical records asynchronously
    private func fetchClinicalRecords(for clinicalType: HKSampleType) async throws -> [HKClinicalRecord] {
        try await FHIRResourceService.fetchClinicalRecords(for: clinicalType, via: healthKitService)
    }
    

    
    /// Get a FHIR resource by identifier.
    func getFHIRResource(id: String) -> Any? {
        if let resource = fhirResources[id] {
            return resource
        } else {
            return nil
        }
    }
    

    

    
    // MARK: - Care Events Methods
    
    /// Reset service state for a fresh data load (used by pull-to-refresh or retries).
    func resetForRefresh() async {
        await MainActor.run {
            // Clear existing timeline data
            self.careEventClusters.removeAll()
            self.fhirResources.removeAll()
            
            // Reset load state flags to allow fresh loading
            self.hasAttemptedCareEventsLoad = false
            self.isLoadingCareEvents = false
            
            // Reset progressive loading state
            self.processedClusterCount = 0
            self.isLoadingMoreTimelines = false
        }
        
        // Clear caches
        mapping.reset()
    }
    
    /// Refresh care events without clearing existing data (for UI refresh).
    func refreshCareEvents() async throws {
        guard AuthorizationStateService.shared.isHealthKitAuthorized else {
            throw NSError(domain: "FHIRTimelineService", code: 1, 
                          userInfo: [NSLocalizedDescriptionKey: "HealthKit access not authorized."])
        }
        
        // Set refresh state
        await MainActor.run {
            self.isRefreshing = true
        }
        
        do {
            // Clear caches but keep existing UI data visible
            mapping.reset()
            
            // Fetch FHIR data
            let fhirData = try await fetchAndConvertToFHIRSilent()
            
            // Process and enhance resources with attachment content
            let enhancedFhirData = await processAttachments(in: fhirData)
            
            // Extract care events from FHIR data
            let events = extractCareEventsFromFHIR(enhancedFhirData)
            
            // Cluster events by date
            let clusters = clusterCareEventsByDate(events)
            
            // Update all properties at once to reduce flickering
            await MainActor.run {
                self.fhirResources = enhancedFhirData
                self.careEventClusters = clusters
                self.isRefreshing = false
                // Reset progressive loading for fresh data
                self.processedClusterCount = 0
            }
            
            // Start automatic timeline generation for all clusters
            await self.startAutomaticTimelineGeneration()
            
        } catch {
            await MainActor.run {
                self.isRefreshing = false
            }
            throw error
        }
    }
    
    /// Load care events immediately from FHIR data without AI processing
    func loadCareEvents() async throws {
        guard AuthorizationStateService.shared.isHealthKitAuthorized else {
            throw NSError(domain: "FHIRTimelineService", code: 1, 
                          userInfo: [NSLocalizedDescriptionKey: "HealthKit access not authorized."])
        }
        
        // Set flags to prevent multiple calls and show loading state
        await MainActor.run {
            self.hasAttemptedCareEventsLoad = true
            self.isLoadingCareEvents = true
        }
        
        do {
            // Fetch FHIR data (reuse existing logic but with reduced UI updates)
            let fhirData = try await fetchAndConvertToFHIRSilent()
            
            // Process and enhance resources with attachment content
            let enhancedFhirData = await processAttachments(in: fhirData)
            
            // Extract care events from FHIR data
            let events = extractCareEventsFromFHIR(enhancedFhirData)
            
            // Cluster events by date
            let clusters = clusterCareEventsByDate(events)
            
            // Update all properties at once to reduce flickering
            await MainActor.run {
                self.fhirResources = enhancedFhirData
                self.careEventClusters = clusters
                self.isLoadingCareEvents = false
                // Reset progressive loading for fresh data
                self.processedClusterCount = 0
            }
            
            // Start automatic timeline generation for all clusters
            await self.startAutomaticTimelineGeneration()
            
        } catch {
            await MainActor.run {
                self.isLoadingCareEvents = false
    
            }
            throw error
        }
    }
    
    /// Extract care events directly from FHIR resources
    private func extractCareEventsFromFHIR(_ fhirData: [String: Any]) -> [CareEvent] { assembler.extractCareEvents(from: fhirData) }
    
    /// Extract date from FHIR resource using various date fields
    private func extractDateFromFHIRResource(_ resource: [String: Any]) -> String? { assembler.extractDate(from: resource) }
    
    /// Normalize date string to YYYY-MM-DD format
    private func normalizeDate(_ dateString: String) -> String? { assembler.normalizeDate(dateString) }
    
    /// Create a basic title from FHIR resource
    private func createTitleFromFHIRResource(_ resource: [String: Any], resourceType: String) -> String { assembler.makeTitle(from: resource, resourceType: resourceType) }
    
    /// Cluster care events by date
    private func clusterCareEventsByDate(_ events: [CareEvent]) -> [CareEventCluster] { assembler.clusterByDate(events) }
    
    /// Generate individual timeline event for a care event cluster using Gemini
    func generateTimelineForCareEventCluster(cluster: CareEventCluster) async throws -> IndividualTimelineEvent {
        // Collect all FHIR resources for the cluster
        var clusterResources: [String: Any] = [:]
        
        for event in cluster.events {
            if let fhirResource = fhirResources[event.fhirResourceId] {
                clusterResources[event.fhirResourceId] = fhirResource
            }
        }
        
        guard !clusterResources.isEmpty else {
            throw NSError(domain: "FHIRTimelineService", code: 4,
                          userInfo: [NSLocalizedDescriptionKey: "No FHIR resources found for care event cluster"])
        }
        
        // Create simplified prompt for cluster
        let prompt = createClusterPrompt(from: clusterResources, cluster: cluster)
        
        // Create schema for cluster event response with artifacts
        let clusterEventSchema = Schema.object(
            properties: [
                "title": .string(description: "Brief title of the health event"),
                "description": .string(description: "Brief description of what happened"),
                "icon": .string(description: "SF Symbol icon name that best represents this health event"),
                "artifacts": .array(
                    items: .object(properties: [
                        "id": .string(description: "FHIR resource ID containing significant natural language text"),
                        "title": .string(description: "Max 4 word title describing the document type"),
                        "resourceType": .string(description: "FHIR resource type (e.g., DiagnosticReport, DocumentReference)")
                    ])
                )
            ]
        )
        
        // Use GeminiService to generate the timeline event
        do {
            let timelineEvent = try await geminiService.generateStructuredContent(
                prompt: prompt,
                responseType: IndividualTimelineEvent.self,
                schema: clusterEventSchema,
                modelName: PromptsConfiguration.ModelNames.clusterTimeline,
                usageDescription: PromptsConfiguration.UsageDescriptions.clusterTimeline(date: cluster.date, eventCount: cluster.events.count)
            )
            return timelineEvent
        } catch {
            throw NSError(domain: "FHIRTimelineService", code: 6,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to generate timeline for care event cluster: \(error.localizedDescription)"])
        }
    }
    
    /// Create simplified prompt for cluster timeline generation
    private func createClusterPrompt(from fhirResources: [String: Any], cluster: CareEventCluster) -> String {
        // Build FHIR resources JSON string with stable ordering
        var fhirResourcesJson = ""
        
        // Sort resources by key for consistent ordering
        let sortedKeys = fhirResources.keys.sorted()
        
        for key in sortedKeys {
            if let resource = fhirResources[key],
               let jsonData = try? JSONSerialization.data(withJSONObject: resource, options: [.sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                fhirResourcesJson += "\n\n--- Resource \(key) ---\n"
                fhirResourcesJson += jsonString
            }
        }
        
        return PromptsConfiguration.clusterTimelinePrompt(
            date: cluster.date,
            fhirResourcesJson: fhirResourcesJson
        )
    }
    
    /// Start automatic timeline generation for initial clusters only
    private func startAutomaticTimelineGeneration() async {
        // Process only the first 5 clusters initially
        let initialBatchSize = 5
        let clustersToProcess = await MainActor.run {
            // Get first 5 clusters that don't already have timeline events
            let allClusters = self.careEventClusters
            let firstBatch = Array(allClusters.prefix(initialBatchSize))
            
            // Update the processed count to match initial batch
            self.processedClusterCount = min(initialBatchSize, allClusters.count)
            
            // Filter to only process those without timeline events
            return firstBatch.filter { $0.timelineEvent == nil && !$0.isGeneratingTimeline }
        }
        
        guard !clustersToProcess.isEmpty else { 
            return 
        }
        
        // Start a timeline generation session for usage tracking
        await MainActor.run {
            self.geminiService.startTimelineGenerationSession()
        }
        
        // Process the initial batch concurrently
        await withTaskGroup(of: Void.self) { group in
            for cluster in clustersToProcess {
                group.addTask { [weak self] in
                    await self?.generateTimelineForClusterSilently(cluster: cluster)
                }
            }
            
            // Wait for all tasks in this batch to complete
            for await _ in group {}
        }
        
        // End the timeline generation session
        await MainActor.run {
            self.geminiService.endTimelineGenerationSession()
        }
    }
    
    /// Load the next batch of timeline events (public method for UI to call)
    func loadNextBatchOfTimelines() async {
        // Prevent concurrent calls
        guard !isLoadingMoreTimelines else { return }
        
        await MainActor.run {
            self.isLoadingMoreTimelines = true
        }
        
        let batchSize = 5
        let currentCount = await MainActor.run { self.processedClusterCount }
        let totalCount = await MainActor.run { self.careEventClusters.count }
        
        // Calculate the next batch range
        let startIndex = currentCount
        let endIndex = min(startIndex + batchSize, totalCount)
        
        guard startIndex < endIndex else {
            await MainActor.run {
                self.isLoadingMoreTimelines = false
            }
            return
        }
        
        // Get the next batch of clusters to process
        let nextBatch = await MainActor.run {
            let clusters = Array(self.careEventClusters[startIndex..<endIndex])
            // Update the processed count
            self.processedClusterCount = endIndex
            return clusters.filter { $0.timelineEvent == nil && !$0.isGeneratingTimeline }
        }
        
        guard !nextBatch.isEmpty else {
            await MainActor.run {
                self.isLoadingMoreTimelines = false
            }
            return
        }
        
        // Start a timeline generation session for usage tracking
        await MainActor.run {
            self.geminiService.startTimelineGenerationSession()
        }
        
        // Process the batch concurrently
        await withTaskGroup(of: Void.self) { group in
            for cluster in nextBatch {
                group.addTask { [weak self] in
                    await self?.generateTimelineForClusterSilently(cluster: cluster)
                }
            }
            
            // Wait for all tasks in this batch to complete
            for await _ in group {}
        }
        
        // End the timeline generation session
        await MainActor.run {
            self.geminiService.endTimelineGenerationSession()
            self.isLoadingMoreTimelines = false
        }
    }
    
    /// Generate timeline for cluster without UI interaction (for automatic generation)
    private func generateTimelineForClusterSilently(cluster: CareEventCluster) async {
        await MainActor.run {
            cluster.isGeneratingTimeline = true
            // Force UI update by updating the published array
            if let index = self.careEventClusters.firstIndex(where: { $0.id == cluster.id }) {
                self.careEventClusters[index] = cluster
            }
        }
        
        do {
            // Add timeout to prevent hanging
            let timelineEvent = try await withTimeout(seconds: 30) {
                try await self.generateTimelineForCareEventCluster(cluster: cluster)
            }
            
            await MainActor.run {
                cluster.isGeneratingTimeline = false
                cluster.timelineEvent = timelineEvent
                // Force UI update by updating the published array
                if let index = self.careEventClusters.firstIndex(where: { $0.id == cluster.id }) {
                    self.careEventClusters[index] = cluster
                }
            }
        } catch {
            await MainActor.run {
                cluster.isGeneratingTimeline = false
                // Force UI update by updating the published array
                if let index = self.careEventClusters.firstIndex(where: { $0.id == cluster.id }) {
                    self.careEventClusters[index] = cluster
                }
                // Silently fail - don't show error messages for automatic generation
            }
        }
    }
    
    /// Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "TimeoutError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out after \(seconds) seconds"])
            }
            
            guard let result = try await group.next() else {
                throw NSError(domain: "TimeoutError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No result returned"])
            }
            
            group.cancelAll()
            return result
        }
    }
    

    // MARK: - Mock Data for Screenshots/Testing
    
    /// Loads a predefined set of mock data for a colon cancer patient.
    func loadColonCancerMockData() {
        // Ensure we're on the main thread for UI updates
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.loadColonCancerMockData() }
            return
        }

        // Set flags to simulate a successful data load
        // Note: Don't modify authorization state here - let AuthorizationStateService handle it
        self.isLoadingCareEvents = false
        self.hasAttemptedCareEventsLoad = true

        // Load mock FHIR resources from the dedicated struct
        self.fhirResources = MockFHIRData.colonCancerResources

        // --- Comprehensive Mock Care Events and Clusters with New Expanded Data ---
        
        // December 2023 - Adjuvant chemotherapy initiation
        let adjuvantChemoCluster = CareEventCluster(date: "2023-12-20", events: [
            CareEvent(id: "folfox-cycle1", date: "2023-12-20", title: "FOLFOX Cycle 1", resourceType: "MedicationRequest", fhirResourceId: "folfox-cycle1")
        ])
        
        let portPlacementCluster = CareEventCluster(date: "2023-12-18", events: [
            CareEvent(id: "port-placement", date: "2023-12-18", title: "Central Venous Port Placement", resourceType: "Procedure", fhirResourceId: "port-placement")
        ])
        
        let chemoBaselineCluster = CareEventCluster(date: "2023-12-15", events: [
            CareEvent(id: "oncology-adjuvant-consultation", date: "2023-12-15", title: "Adjuvant Chemotherapy Planning", resourceType: "Encounter", fhirResourceId: "oncology-adjuvant-consultation"),
            CareEvent(id: "chemo-baseline-labs", date: "2023-12-15", title: "Pre-chemotherapy Laboratory Studies", resourceType: "DiagnosticReport", fhirResourceId: "chemo-baseline-labs")
        ])
        
        // December 2023 - Post-operative follow-up
        let postopFollowupCluster = CareEventCluster(date: "2023-12-05", events: [
            CareEvent(id: "postop-surgical-followup", date: "2023-12-05", title: "Post-operative Surgical Follow-up", resourceType: "Encounter", fhirResourceId: "postop-surgical-followup"),
            CareEvent(id: "postop-cea-followup", date: "2023-12-05", title: "Post-operative CEA Baseline", resourceType: "Observation", fhirResourceId: "postop-cea-followup")
        ])
        
        // November 2023 - Hospital discharge
        let dischargeCluster = CareEventCluster(date: "2023-11-23", events: [
            CareEvent(id: "hospital-discharge", date: "2023-11-23", title: "Hospital Discharge", resourceType: "Encounter", fhirResourceId: "hospital-discharge"),
            CareEvent(id: "discharge-medications", date: "2023-11-23", title: "Discharge Medications", resourceType: "MedicationRequest", fhirResourceId: "discharge-medications")
        ])
        
        // November 2023 - Final surgical pathology
        let finalPathologyCluster = CareEventCluster(date: "2023-11-25", events: [
            CareEvent(id: "final-surgical-pathology", date: "2023-11-25", title: "Final Surgical Pathology Report", resourceType: "DiagnosticReport", fhirResourceId: "final-surgical-pathology")
        ])
        
        // November 2023 - Post-operative care
        let postopCareCluster = CareEventCluster(date: "2023-11-21", events: [
            CareEvent(id: "postop-day1-rounds", date: "2023-11-21", title: "Post-operative Day 1 Rounds", resourceType: "Encounter", fhirResourceId: "postop-day1-rounds"),
            CareEvent(id: "postop-lab-day1", date: "2023-11-21", title: "Post-operative Laboratory", resourceType: "DiagnosticReport", fhirResourceId: "postop-lab-day1")
        ])
        
        // November 2023 - Surgery day
        let surgeryCluster = CareEventCluster(date: "2023-11-20", events: [
            CareEvent(id: "anesthesia-preop-evaluation", date: "2023-11-20", title: "Anesthesia Pre-operative Assessment", resourceType: "Encounter", fhirResourceId: "anesthesia-preop-evaluation"),
            CareEvent(id: "sigmoid-colectomy-procedure", date: "2023-11-20", title: "Laparoscopic Sigmoid Colectomy", resourceType: "Procedure", fhirResourceId: "sigmoid-colectomy-procedure"),
            CareEvent(id: "detailed-operative-note", date: "2023-11-20", title: "Detailed Operative Report", resourceType: "DocumentReference", fhirResourceId: "detailed-operative-note"),
            CareEvent(id: "immediate-postop-vitals", date: "2023-11-20", title: "Immediate Post-operative Vitals", resourceType: "Observation", fhirResourceId: "immediate-postop-vitals"),
            CareEvent(id: "postop-pain-management", date: "2023-11-20", title: "Post-operative Pain Management", resourceType: "MedicationRequest", fhirResourceId: "postop-pain-management")
        ])
        
        // November 2023 - Pre-operative workup
        let preopWorkupCluster = CareEventCluster(date: "2023-11-15", events: [
            CareEvent(id: "preop-medical-clearance", date: "2023-11-15", title: "Pre-operative Medical Clearance", resourceType: "Encounter", fhirResourceId: "preop-medical-clearance"),
            CareEvent(id: "preop-laboratory-panel", date: "2023-11-15", title: "Pre-operative Laboratory Panel", resourceType: "DiagnosticReport", fhirResourceId: "preop-laboratory-panel"),
            CareEvent(id: "preop-cardiac-clearance", date: "2023-11-15", title: "Pre-operative EKG", resourceType: "DiagnosticReport", fhirResourceId: "preop-cardiac-clearance")
        ])
        
        // November 2023 - Surgery consultation
        let surgeryConsultCluster = CareEventCluster(date: "2023-11-10", events: [
            CareEvent(id: "surgical-consultation", date: "2023-11-10", title: "Surgical Oncology Consultation", resourceType: "Encounter", fhirResourceId: "surgical-consultation")
        ])
        
        // October 2023 - Diagnosis and oncology consultation
        let diagnosisCluster = CareEventCluster(date: "2023-10-25", events: [
            CareEvent(id: "biopsy-pathology-report", date: "2023-10-25", title: "Colon Biopsy Pathology Report", resourceType: "DiagnosticReport", fhirResourceId: "biopsy-pathology-report"),
            CareEvent(id: "oncology-consultation-1", date: "2023-10-25", title: "Initial Oncology Consultation", resourceType: "Encounter", fhirResourceId: "oncology-consultation-1")
        ])
        
        // October 2023 - Staging workup
        let stagingCluster = CareEventCluster(date: "2023-10-22", events: [
            CareEvent(id: "staging-ct-scan", date: "2023-10-22", title: "Staging CT Abdomen/Pelvis", resourceType: "ImagingStudy", fhirResourceId: "staging-ct-scan"),
            CareEvent(id: "staging-ct-detailed-report", date: "2023-10-22", title: "Detailed CT Report", resourceType: "DiagnosticReport", fhirResourceId: "staging-ct-detailed-report"),
            CareEvent(id: "cea-post-biopsy", date: "2023-10-22", title: "CEA Post-biopsy", resourceType: "Observation", fhirResourceId: "cea-post-biopsy")
        ])
        
        // October 2023 - Colonoscopy and biopsy
        let colonoscopyCluster = CareEventCluster(date: "2023-10-20", events: [
            CareEvent(id: "colonoscopy-procedure", date: "2023-10-20", title: "Diagnostic Colonoscopy with Biopsy", resourceType: "Procedure", fhirResourceId: "colonoscopy-procedure"),
            CareEvent(id: "colonoscopy-report", date: "2023-10-20", title: "Colonoscopy Procedure Report", resourceType: "DiagnosticReport", fhirResourceId: "colonoscopy-report"),
            CareEvent(id: "colonoscopy-sedation", date: "2023-10-20", title: "Conscious Sedation", resourceType: "MedicationAdministration", fhirResourceId: "colonoscopy-sedation"),
            CareEvent(id: "post-procedure-vitals", date: "2023-10-20", title: "Post-procedure Vitals", resourceType: "Observation", fhirResourceId: "post-procedure-vitals")
        ])
        
        // October 2023 - Bowel preparation
        let bowelPrepCluster = CareEventCluster(date: "2023-10-18", events: [
            CareEvent(id: "bowel-prep-medication", date: "2023-10-18", title: "Bowel Preparation for Colonoscopy", resourceType: "MedicationRequest", fhirResourceId: "bowel-prep-medication")
        ])
        
        // October 2023 - Initial presentation and comprehensive workup
        let initialSymptomsCluster = CareEventCluster(date: "2023-10-15", events: [
            CareEvent(id: "symptom-encounter-1", date: "2023-10-15", title: "Primary Care Visit - New Symptoms", resourceType: "Encounter", fhirResourceId: "symptom-encounter-1"),
            CareEvent(id: "vital-signs-1", date: "2023-10-15", title: "Heart Rate", resourceType: "Observation", fhirResourceId: "vital-signs-1"),
            CareEvent(id: "vital-signs-2", date: "2023-10-15", title: "Blood Pressure", resourceType: "Observation", fhirResourceId: "vital-signs-2"),
            CareEvent(id: "vital-signs-3", date: "2023-10-15", title: "Body Weight", resourceType: "Observation", fhirResourceId: "vital-signs-3"),
            CareEvent(id: "vital-signs-4", date: "2023-10-15", title: "Temperature", resourceType: "Observation", fhirResourceId: "vital-signs-4"),
            CareEvent(id: "physical-exam-1", date: "2023-10-15", title: "Abdominal Examination", resourceType: "Observation", fhirResourceId: "physical-exam-1"),
            CareEvent(id: "cbc-report-1", date: "2023-10-15", title: "Complete Blood Count", resourceType: "DiagnosticReport", fhirResourceId: "cbc-report-1"),
            CareEvent(id: "cmp-report-1", date: "2023-10-15", title: "Comprehensive Metabolic Panel", resourceType: "DiagnosticReport", fhirResourceId: "cmp-report-1"),
            CareEvent(id: "iron-studies-1", date: "2023-10-15", title: "Iron Studies Panel", resourceType: "DiagnosticReport", fhirResourceId: "iron-studies-1"),
            CareEvent(id: "cea-tumor-marker-1", date: "2023-10-15", title: "CEA Tumor Marker", resourceType: "Observation", fhirResourceId: "cea-tumor-marker-1"),
            CareEvent(id: "urgent-referral-1", date: "2023-10-15", title: "STAT Colonoscopy Referral", resourceType: "ServiceRequest", fhirResourceId: "urgent-referral-1")
        ])
        
        // Assign comprehensive clusters in chronological order (newest first)
        self.careEventClusters = [
            adjuvantChemoCluster, portPlacementCluster, chemoBaselineCluster,
            postopFollowupCluster, finalPathologyCluster, dischargeCluster, postopCareCluster,
            surgeryCluster, preopWorkupCluster, surgeryConsultCluster, diagnosisCluster,
            stagingCluster, colonoscopyCluster, bowelPrepCluster, initialSymptomsCluster
        ]
        
        // Start automatic timeline generation for all clusters
        Task {
            await self.startAutomaticTimelineGeneration()
        }
    }
}

// Conform to lookup protocol for attachment fetching
extension FHIRTimelineService: HealthKitRecordLookup {}

// MARK: - TimelineData

struct TimelineData: Codable {
    let summary: String
    let keyEvents: [KeyEvent]
    
    struct KeyEvent: Codable {
        let date: String
        let title: String
        let description: String
        let icon: String
        let recordIds: [RecordReference]
        let resourceTypeCounts: [String: Int]
        
        struct RecordReference: Codable {
            let id: String
            let title: String
        }
    }
}
