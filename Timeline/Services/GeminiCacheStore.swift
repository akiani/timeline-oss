// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import CoreData

/// Manages Core Data operations for Gemini API response caching
class GeminiCacheStore {
    static let shared = GeminiCacheStore()
    
    private let maxCacheSize = 10000
    private let cacheExpirationDays = 30
    
    private init() {
        // Private initializer for singleton
        // Initialize Core Data first, then perform maintenance
        DispatchQueue.main.async {
            // Force lazy initialization of persistent container
            _ = self.persistentContainer
            
            // Then perform maintenance tasks
            Task {
                await self.performMaintenanceTasks()
            }
        }
    }
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Create the managed object model programmatically
        let model = createManagedObjectModel()
        let container = NSPersistentContainer(name: "GeminiCache", managedObjectModel: model)
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                Log.data.error("Core Data error: \(String(describing: error)), \(error.userInfo.description)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    /// Create the Core Data model programmatically
    private func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Create GeminiCacheEntry entity
        let entity = NSEntityDescription()
        entity.name = "GeminiCacheEntry"
        entity.managedObjectClassName = "GeminiCacheEntry"
        
        // Create attributes
        let promptHashAttribute = NSAttributeDescription()
        promptHashAttribute.name = "promptHash"
        promptHashAttribute.attributeType = .stringAttributeType
        promptHashAttribute.isOptional = false
        
        let modelNameAttribute = NSAttributeDescription()
        modelNameAttribute.name = "modelName"
        modelNameAttribute.attributeType = .stringAttributeType
        modelNameAttribute.isOptional = false
        
        let responseAttribute = NSAttributeDescription()
        responseAttribute.name = "response"
        responseAttribute.attributeType = .stringAttributeType
        responseAttribute.isOptional = false
        
        let createdDateAttribute = NSAttributeDescription()
        createdDateAttribute.name = "createdDate"
        createdDateAttribute.attributeType = .dateAttributeType
        createdDateAttribute.isOptional = false
        
        let lastAccessedDateAttribute = NSAttributeDescription()
        lastAccessedDateAttribute.name = "lastAccessedDate"
        lastAccessedDateAttribute.attributeType = .dateAttributeType
        lastAccessedDateAttribute.isOptional = false
        
        // Add attributes to entity
        entity.properties = [
            promptHashAttribute,
            modelNameAttribute,
            responseAttribute,
            createdDateAttribute,
            lastAccessedDateAttribute
        ]
        
        // Add entity to model
        model.entities = [entity]
        
        return model
    }
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Public Interface
    
    /// Retrieve cached response for the given cache key
    func getCachedResponse(for key: GeminiCacheKey) -> String? {
        // Ensure persistent container is loaded
        _ = persistentContainer
        
        let request = NSFetchRequest<GeminiCacheEntry>(entityName: "GeminiCacheEntry")
        request.predicate = NSPredicate(format: "promptHash == %@", key.hash)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let entry = results.first {
                // Update last accessed date for LRU
                entry.lastAccessedDate = Date()
                saveContext()
                
                return entry.response
            } else {
                return nil
            }
        } catch {
            Log.data.error("Error fetching cached response: \(String(describing: error))")
            return nil
        }
    }
    
    /// Store a new response in the cache
    func setCachedResponse(_ response: String, for key: GeminiCacheKey) {
        // Ensure persistent container is loaded
        _ = persistentContainer
        
        
        // Check if entry already exists (shouldn't happen, but safety check)
        let existingRequest = NSFetchRequest<GeminiCacheEntry>(entityName: "GeminiCacheEntry")
        existingRequest.predicate = NSPredicate(format: "promptHash == %@", key.hash)
        existingRequest.fetchLimit = 1
        
        do {
            let existing = try context.fetch(existingRequest)
            if !existing.isEmpty {
                return
            }
        } catch {
            Log.data.error("Error checking for existing entry: \(String(describing: error))")
            return
        }
        
        // Get the entity description
        guard let entity = NSEntityDescription.entity(forEntityName: "GeminiCacheEntry", in: context) else {
            Log.data.error("Error: Could not find GeminiCacheEntry entity")
            return
        }
        
        // Create new cache entry
        let entry = GeminiCacheEntry(entity: entity, insertInto: context)
        entry.promptHash = key.hash
        entry.modelName = key.modelName
        entry.response = response
        entry.createdDate = Date()
        entry.lastAccessedDate = Date()
        
        do {
            try context.save()
        } catch {
            Log.data.error("Error saving cached response: \(String(describing: error))")
        }
        
        // Perform maintenance if needed
        Task {
            await performMaintenanceIfNeeded()
        }
    }
    
    /// Clear all cached responses
    func clearAllCache() {
        // Ensure persistent container is loaded
        _ = persistentContainer
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "GeminiCacheEntry")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            Log.data.error("Error clearing cache: \(String(describing: error))")
        }
    }
    
    /// Get cache statistics (for debugging/monitoring)
    func getCacheStats() -> (count: Int, oldestEntry: Date?, newestEntry: Date?) {
        // Ensure persistent container is loaded
        _ = persistentContainer
        
        let request = NSFetchRequest<GeminiCacheEntry>(entityName: "GeminiCacheEntry")
        request.sortDescriptors = [NSSortDescriptor(key: "createdDate", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            let count = results.count
            let oldest = results.first?.createdDate
            let newest = results.last?.createdDate
            return (count: count, oldestEntry: oldest, newestEntry: newest)
        } catch {
            Log.data.error("Error getting cache stats: \(String(describing: error))")
            return (count: 0, oldestEntry: nil, newestEntry: nil)
        }
    }
    
    // MARK: - Private Maintenance Methods
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Log.data.error("Error saving Core Data context: \(String(describing: error))")
            }
        }
    }
    
    private func performMaintenanceTasks() async {
        await cleanupExpiredEntries()
        await enforceMaxCacheSize()
    }
    
    private func performMaintenanceIfNeeded() async {
        // Only run maintenance occasionally to avoid performance impact
        let shouldRunMaintenance = Int.random(in: 1...20) == 1 // 5% chance
        if shouldRunMaintenance {
            await performMaintenanceTasks()
        }
    }
    
    /// Remove entries older than the expiration period
    private func cleanupExpiredEntries() async {
        let calendar = Calendar.current
        guard let expirationDate = calendar.date(byAdding: .day, value: -cacheExpirationDays, to: Date()) else {
            return
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "GeminiCacheEntry")
        request.predicate = NSPredicate(format: "createdDate < %@", expirationDate as NSDate)
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            Log.data.error("Error cleaning up expired entries: \(String(describing: error))")
        }
    }
    
    /// Enforce maximum cache size using LRU eviction
    private func enforceMaxCacheSize() async {
        let countRequest = NSFetchRequest<GeminiCacheEntry>(entityName: "GeminiCacheEntry")
        
        do {
            let totalCount = try context.count(for: countRequest)
            
            if totalCount > maxCacheSize {
                let excessCount = totalCount - maxCacheSize
                
                // Get oldest entries by last accessed date
                let request = NSFetchRequest<GeminiCacheEntry>(entityName: "GeminiCacheEntry")
                request.sortDescriptors = [NSSortDescriptor(key: "lastAccessedDate", ascending: true)]
                request.fetchLimit = excessCount
                
                let oldestEntries = try context.fetch(request)
                
                // Delete oldest entries
                for entry in oldestEntries {
                    context.delete(entry)
                }
                
                saveContext()
            }
        } catch {
            Log.data.error("Error enforcing cache size: \(String(describing: error))")
        }
    }
}
