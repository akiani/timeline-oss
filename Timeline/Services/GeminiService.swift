// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import FirebaseVertexAI
import SwiftUI

// MARK: - Usage Models

struct GeminiUsageEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let usageDescription: String
    let inputTokens: Int
    let outputTokens: Int
    let latencyMs: Int
    let modelName: String
    let sessionId: String? // Track which timeline generation session this belongs to
    
    var totalTokens: Int {
        inputTokens + outputTokens
    }
    
    init(date: Date, usageDescription: String, inputTokens: Int, outputTokens: Int, latencyMs: Int, modelName: String, sessionId: String? = nil) {
        self.id = UUID()
        self.date = date
        self.usageDescription = usageDescription
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.latencyMs = latencyMs
        self.modelName = modelName
        self.sessionId = sessionId
    }
}

struct GeminiUsageSummary: Codable {
    let totalCalls: Int
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalLatencyMs: Int
    let entries: [GeminiUsageEntry]
    
    var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }
    
    var averageLatencyMs: Int {
        totalCalls > 0 ? totalLatencyMs / totalCalls : 0
    }
}

// MARK: - Gemini Service

@MainActor
class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    private let vertexAI = VertexAI.vertexAI()
    private let userDefaults = UserDefaults.standard
    private let usageKey = "gemini_usage_entries"
    
    @Published var usageEntries: [GeminiUsageEntry] = []
    
    // Session tracking for merging timeline generation calls
    private var currentSessionId: String?
    private var sessionStartTime: Date?
    private let sessionTimeoutMinutes: TimeInterval = 5 // Merge calls within 5 minutes
    
    private init() {
        loadUsageEntries()
    }
    
    // MARK: - API Methods
    
    /// Generate content using Gemini with automatic usage tracking and caching
    func generateContent(
        prompt: String,
        modelName: String,
        schema: Schema? = nil,
        usageDescription: String
    ) async throws -> String {
        // Create cache key
        let cacheKey = GeminiCacheKey(prompt: prompt, modelName: modelName, schema: schema)
        
        // Check cache first
        if let cachedResponse = GeminiCacheStore.shared.getCachedResponse(for: cacheKey) {
            // Log cache hit as zero-cost usage (for tracking purposes)
            logUsage(
                usageDescription: "\(usageDescription) [CACHED]",
                inputTokens: 0,
                outputTokens: 0,
                latencyMs: 0,
                modelName: modelName
            )
            return cachedResponse
        }
        
        let startTime = Date()
        
        // Configure safety settings
        let safetySettings = createSafetySettings()
        
        // Create model with optional schema and thinking disabled
        let model: GenerativeModel
        if let schema = schema {
            let generationConfig = createGenerationConfig(
                modelName: modelName,
                responseMIMEType: "application/json",
                responseSchema: schema
            )
            model = vertexAI.generativeModel(
                modelName: modelName,
                generationConfig: generationConfig,
                safetySettings: safetySettings
            )
        } else {
            let generationConfig = createGenerationConfig(modelName: modelName)
            model = vertexAI.generativeModel(
                modelName: modelName,
                generationConfig: generationConfig,
                safetySettings: safetySettings
            )
        }
        
        // Make API call
        let response = try await model.generateContent(prompt)
        let endTime = Date()
        
        // Calculate metrics
        let latencyMs = Int((endTime.timeIntervalSince(startTime)) * 1000)
        
        // Get actual token counts from response metadata
        guard let usageMetadata = response.usageMetadata else {
            throw GeminiServiceError.missingUsageMetadata
        }
        
        let inputTokens = usageMetadata.promptTokenCount
        let outputTokens = usageMetadata.candidatesTokenCount
        
        // Log usage
        logUsage(
            usageDescription: usageDescription,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            latencyMs: latencyMs,
            modelName: modelName
        )
        
        guard let responseText = response.text, !responseText.isEmpty else {
            throw GeminiServiceError.emptyResponse
        }
        
        // Cache the response for future use
        GeminiCacheStore.shared.setCachedResponse(responseText, for: cacheKey)
        
        return responseText
    }
    
    /// Generate structured JSON content
    func generateStructuredContent<T: Codable>(
        prompt: String,
        responseType: T.Type,
        schema: Schema,
        modelName: String,
        usageDescription: String
    ) async throws -> T {
        let responseText = try await generateContent(
            prompt: prompt,
            modelName: modelName,
            schema: schema,
            usageDescription: usageDescription
        )
        
        guard let jsonData = responseText.data(using: .utf8) else {
            throw GeminiServiceError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: jsonData)
        } catch {
            throw GeminiServiceError.decodingFailed(error)
        }
    }
    
    // Streaming generation method removed as unused.
    
    // MARK: - Session Management
    
    /// Start (or reuse within timeout) an AI generation session for grouping usage metrics.
    func startTimelineGenerationSession() {
        let now = Date()
        
        // Check if we can reuse the current session (within timeout)
        if let sessionStart = sessionStartTime,
           now.timeIntervalSince(sessionStart) < sessionTimeoutMinutes * 60 {
            // Continue current session
            return
        }
        
        // Start new session
        currentSessionId = UUID().uuidString
        sessionStartTime = now
    }
    
    /// End the current AI generation session and stop grouping usage entries.
    func endTimelineGenerationSession() {
        currentSessionId = nil
        sessionStartTime = nil
    }
    
    // MARK: - Usage Tracking
    
    private func logUsage(
        usageDescription: String,
        inputTokens: Int,
        outputTokens: Int,
        latencyMs: Int,
        modelName: String
    ) {
        let entry = GeminiUsageEntry(
            date: Date(),
            usageDescription: usageDescription,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            latencyMs: latencyMs,
            modelName: modelName,
            sessionId: currentSessionId
        )
        
        usageEntries.append(entry)
        saveUsageEntries()
    }
    
    private func loadUsageEntries() {
        guard let data = userDefaults.data(forKey: usageKey),
              let entries = try? JSONDecoder().decode([GeminiUsageEntry].self, from: data) else {
            usageEntries = []
            return
        }
        usageEntries = entries
    }
    
    private func saveUsageEntries() {
        if let data = try? JSONEncoder().encode(usageEntries) {
            userDefaults.set(data, forKey: usageKey)
        }
    }
    
    // MARK: - Usage Summary
    
    /// Summary of calls, tokens, and latency aggregated by session and time.
    var usageSummary: GeminiUsageSummary {
        let mergedEntries = getMergedUsageEntries()
        
        let totalInputTokens = mergedEntries.reduce(0) { $0 + $1.inputTokens }
        let totalOutputTokens = mergedEntries.reduce(0) { $0 + $1.outputTokens }
        let totalLatencyMs = mergedEntries.reduce(0) { $0 + $1.latencyMs }
        
        return GeminiUsageSummary(
            totalCalls: mergedEntries.count,
            totalInputTokens: totalInputTokens,
            totalOutputTokens: totalOutputTokens,
            totalLatencyMs: totalLatencyMs,
            entries: mergedEntries.sorted { $0.date > $1.date }
        )
    }
    
    // MARK: - Session Merging
    
    private func getMergedUsageEntries() -> [GeminiUsageEntry] {
        var mergedEntries: [GeminiUsageEntry] = []
        var sessionGroups: [String: [GeminiUsageEntry]] = [:]
        var standaloneEntries: [GeminiUsageEntry] = []
        
        // Group entries by session ID
        for entry in usageEntries {
            if let sessionId = entry.sessionId {
                if sessionGroups[sessionId] == nil {
                    sessionGroups[sessionId] = []
                }
                sessionGroups[sessionId]?.append(entry)
            } else {
                standaloneEntries.append(entry)
            }
        }
        
        // Merge entries from the same session
        for (sessionId, sessionEntries) in sessionGroups {
            let sortedEntries = sessionEntries.sorted { $0.date < $1.date }
            guard let firstEntry = sortedEntries.first else { continue }
            
            let totalInputTokens = sessionEntries.reduce(0) { $0 + $1.inputTokens }
            let totalOutputTokens = sessionEntries.reduce(0) { $0 + $1.outputTokens }
            let totalLatencyMs = sessionEntries.reduce(0) { $0 + $1.latencyMs }
            
            let mergedEntry = GeminiUsageEntry(
                date: firstEntry.date, // Use start time of session
                usageDescription: "Timeline generation session (\(sessionEntries.count) clusters)",
                inputTokens: totalInputTokens,
                outputTokens: totalOutputTokens,
                latencyMs: totalLatencyMs,
                modelName: firstEntry.modelName,
                sessionId: sessionId
            )
            
            mergedEntries.append(mergedEntry)
        }
        
        // Add standalone entries (non-session entries like FHIR record summaries)
        mergedEntries.append(contentsOf: standaloneEntries)
        
        return mergedEntries
    }
    
    // MARK: - Helper Methods
    
    /// Create generation configuration with appropriate thinking budget for each model
    private func createGenerationConfig(
        modelName: String,
        responseMIMEType: String? = nil,
        responseSchema: Schema? = nil
    ) -> GenerationConfig {
        // Configure thinking budget based on model capabilities
        // All Gemini 2.5 models support configurable thinking budgets
        let thinkingBudget: Int
        if modelName.contains("2.5-pro") || modelName.contains("2.5-flash") {
            thinkingBudget = PromptsConfiguration.ThinkingBudgetConfig.modelThinkingBudget
        } else {
            thinkingBudget = 0 // Disable thinking for other models
        }
        
        let thinkingConfig = ThinkingConfig(thinkingBudget: thinkingBudget)
        
        // Create generation config with thinking configuration
        if let responseMIMEType = responseMIMEType, let responseSchema = responseSchema {
            return GenerationConfig(
                responseMIMEType: responseMIMEType,
                responseSchema: responseSchema,
                thinkingConfig: thinkingConfig
            )
        } else {
            return GenerationConfig(
                thinkingConfig: thinkingConfig
            )
        }
    }
    
    private func createSafetySettings() -> [SafetySetting] {
        return [
            SafetySetting(harmCategory: .harassment, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .hateSpeech, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .sexuallyExplicit, threshold: .blockOnlyHigh),
            SafetySetting(harmCategory: .dangerousContent, threshold: .blockOnlyHigh)
        ]
    }
    

    
    // MARK: - Data Management
    
    /// Remove all persisted usage entries.
    func clearUsageHistory() {
        usageEntries.removeAll()
        userDefaults.removeObject(forKey: usageKey)
    }
    
    /// Export a JSON snapshot of the current usage summary.
    func exportUsageData() -> Data? {
        return try? JSONEncoder().encode(usageSummary)
    }
}

// MARK: - Errors

enum GeminiServiceError: LocalizedError {
    case emptyResponse
    case invalidResponse
    case decodingFailed(Error)
    case missingUsageMetadata
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "The AI model returned an empty response. This may be due to a content filter or a network issue."
        case .invalidResponse:
            return "The AI model returned an invalid or unparseable response."
        case .decodingFailed(let error):
            return "Failed to decode the AI model's response. Error: \(error.localizedDescription)"
        case .missingUsageMetadata:
            return "The AI model's response is missing essential usage metadata for token counting."
        case .underlying(let error):
            return "An underlying error occurred: \(error.localizedDescription)"
        }
    }
}
