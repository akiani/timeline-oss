// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import CryptoKit
import FirebaseVertexAI

/// Generates unique cache keys for Gemini API requests based on essential parameters
struct GeminiCacheKey {
    let prompt: String
    let modelName: String
    let hasSchema: Bool
    
    // Lazy stored property for hash computation
    private let _computedHash: String
    
    /// Get the pre-computed hash for this cache key
    var hash: String {
        return _computedHash
    }
    
    /// Initialize and compute hash once
    init(prompt: String, modelName: String, hasSchema: Bool) {
        self.prompt = prompt
        self.modelName = modelName
        self.hasSchema = hasSchema
        
        // Compute hash once during initialization
        let components = [
            prompt,
            modelName,
            hasSchema ? "with_schema" : "no_schema"
        ]
        
        let combinedString = components.joined(separator: "|")
        let data = Data(combinedString.utf8)
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        self._computedHash = hashString
    }
}

/// Convenience initializer for creating cache keys from GeminiService parameters
extension GeminiCacheKey {
    init(prompt: String, modelName: String, schema: Schema?) {
        self.init(
            prompt: prompt,
            modelName: modelName,
            hasSchema: schema != nil
        )
    }
}
