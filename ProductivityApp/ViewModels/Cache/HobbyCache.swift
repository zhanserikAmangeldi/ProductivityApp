//
//  HobbyCache.swift
//  ProductivityApp
//
//  Created by Alikhan Kassiman on 12.05.2025.
//

import Foundation
import CoreData

class HobbyCache {
    static let shared = HobbyCache()
    
    private init() {}
    
    // Cache for entries arrays
    private var entriesArrayCache: [UUID: [HobbyEntry]] = [:]
    private var entriesUpdateTimestamps: [UUID: Date] = [:]
    
    // Cache for entry date checks
    private var entryDateCache: [String: Bool] = [:] // format: "hobbyID-dateString": hasEntry
    
    // Get cached entries array
    func getEntriesArray(for hobby: Hobby) -> [HobbyEntry]? {
        guard let hobbyId = hobby.id else { return nil }
        
        if let cachedEntries = entriesArrayCache[hobbyId],
           let lastUpdate = entriesUpdateTimestamps[hobbyId],
           Date().timeIntervalSince(lastUpdate) <= 3 {
            return cachedEntries
        }
        
        return nil
    }
    
    // Store entries array in cache
    func storeEntriesArray(for hobby: Hobby, entries: [HobbyEntry]) {
        guard let hobbyId = hobby.id else { return }
        
        entriesArrayCache[hobbyId] = entries
        entriesUpdateTimestamps[hobbyId] = Date()
    }
    
    // Check if date has entry (from cache)
    func hasEntry(for hobby: Hobby, on date: Date) -> Bool? {
        guard let hobbyId = hobby.id else { return nil }
        
        let cacheKey = "\(hobbyId.uuidString)-\(formatDateKey(date))"
        return entryDateCache[cacheKey]
    }
    
    // Store date entry status
    func storeHasEntry(_ hasEntry: Bool, for hobby: Hobby, on date: Date) {
        guard let hobbyId = hobby.id else { return }
        
        let cacheKey = "\(hobbyId.uuidString)-\(formatDateKey(date))"
        entryDateCache[cacheKey] = hasEntry
    }
    
    // Invalidate cache for a specific hobby
    func invalidateCache(for hobby: Hobby) {
        guard let hobbyId = hobby.id else { return }
        
        entriesArrayCache.removeValue(forKey: hobbyId)
        entriesUpdateTimestamps.removeValue(forKey: hobbyId)
        
        // Remove all date cache entries for this hobby
        let prefix = "\(hobbyId.uuidString)-"
        entryDateCache = entryDateCache.filter { key, _ in
            !key.hasPrefix(prefix)
        }
    }
    
    // Format date for cache key
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Clear all caches
    func clearAllCaches() {
        entriesArrayCache.removeAll()
        entriesUpdateTimestamps.removeAll()
        entryDateCache.removeAll()
    }
}
