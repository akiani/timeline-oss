// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import Foundation
import CoreData

@objc(GeminiCacheEntry)
public class GeminiCacheEntry: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeminiCacheEntry> {
        return NSFetchRequest<GeminiCacheEntry>(entityName: "GeminiCacheEntry")
    }

    @NSManaged public var promptHash: String
    @NSManaged public var modelName: String
    @NSManaged public var response: String
    @NSManaged public var createdDate: Date
    @NSManaged public var lastAccessedDate: Date
    
    // Override to work with programmatic model
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdDate = Date()
        lastAccessedDate = Date()
    }
}
