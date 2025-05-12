//
//  HobbyManager.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import CoreData
import SwiftUI

class HobbyManager {
    static let shared = HobbyManager()
    
    public let coreDataService = CoreDataService.shared
    private var context: NSManagedObjectContext {
        return coreDataService.viewContext
    }
    
    private init() {}
        
    // MARK: - Hobby CRUD Operations
    
    func createHobby(title: String, description: String, iconName: String, colorHex: String) -> Hobby {
        let hobby = Hobby(context: context)
        hobby.id = UUID()
        hobby.title = title
        hobby.hobbyDescription = description
        hobby.iconName = iconName
        hobby.colorHex = colorHex
        hobby.dateCreated = Date()
        hobby.lastModified = Date()
        hobby.userId = CurrentUserService.shared.currentUserId
        
        saveContext()
        return hobby
    }
    
    func updateHobby(_ hobby: Hobby) {
        hobby.lastModified = Date()
        saveContext()
    }
    
    func deleteHobby(_ hobby: Hobby) {
        context.delete(hobby)
        saveContext()
    }
    
    func fetchHobbies(searchText: String? = nil) -> [Hobby] {
        let fetchRequest: NSFetchRequest<Hobby> = Hobby.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        
        if let userId = CurrentUserService.shared.currentUserId {
            predicates.append(NSPredicate(format: "userId == %@", userId))
        }
        
        
        if let searchText = searchText, !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR hobbyDescription CONTAINS[cd] %@",
                                       searchText, searchText))
        }
        
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "lastModified", ascending: false)
        ]
        
        // Add batch size for better performance
        fetchRequest.fetchBatchSize = 20
        
        return coreDataService.execute(fetchRequest)
    }
    
    // Add this new async method to fetch hobbies in the background
    func fetchHobbiesAsync(searchText: String? = nil) async -> [Hobby] {
        return await withCheckedContinuation { continuation in
            let backgroundContext = coreDataService.persistentContainer.newBackgroundContext()
            backgroundContext.perform {
                let fetchRequest: NSFetchRequest<Hobby> = Hobby.fetchRequest()
                
                var predicates: [NSPredicate] = []
                
                if let userId = CurrentUserService.shared.currentUserId {
                    predicates.append(NSPredicate(format: "userId == %@", userId))
                }
                
                if let searchText = searchText, !searchText.isEmpty {
                    predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR hobbyDescription CONTAINS[cd] %@",
                                               searchText, searchText))
                }
                
                if !predicates.isEmpty {
                    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                }
                
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "lastModified", ascending: false)
                ]
                
                // Add batch size for better performance
                fetchRequest.fetchBatchSize = 20
                
                let results = (try? backgroundContext.fetch(fetchRequest)) ?? []
                
                // Convert to main context objects
                let objectIDs = results.map { $0.objectID }
                
                DispatchQueue.main.async {
                    let mainContextResults = objectIDs.compactMap {
                        self.context.object(with: $0) as? Hobby
                    }
                    continuation.resume(returning: mainContextResults)
                }
            }
        }
    }
    
    func fetchHobby(withID id: UUID) -> Hobby? {
        let fetchRequest: NSFetchRequest<Hobby> = Hobby.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        predicates.append(NSPredicate(format: "id == %@", id as CVarArg))
        
        
        if let userId = CurrentUserService.shared.currentUserId {
            predicates.append(NSPredicate(format: "userId == %@", userId))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.fetchLimit = 1
        
        let hobbies = coreDataService.execute(fetchRequest)
        return hobbies.first
    }
    
    // MARK: - Entry Management
    
    func toggleEntryCompletion(for hobby: Hobby, on date: Date) -> HobbyEntry? {
        let hobbyID = hobby.objectID
        let backgroundContext = coreDataService.persistentContainer.newBackgroundContext()
        
        backgroundContext.perform {
            guard let backgroundHobby = backgroundContext.object(with: hobbyID) as? Hobby else {
                return
            }
            
            // Check for existing entry more efficiently
            let calendar = Calendar.current
            let entriesSet = backgroundHobby.entries as? Set<HobbyEntry> ?? []
            let existingEntry = entriesSet.first { entry in
                guard let entryDate = entry.date else { return false }
                return calendar.isDate(entryDate, inSameDayAs: date)
            }
            
            if let existingEntry = existingEntry {
                backgroundContext.delete(existingEntry)
            } else {
                let entry = HobbyEntry(context: backgroundContext)
                entry.id = UUID()
                entry.date = date
                entry.hobby = backgroundHobby
                entry.userId = CurrentUserService.shared.currentUserId
            }
            
            try? backgroundContext.save()
            
            // Notify main context of changes
            DispatchQueue.main.async {
                self.context.refreshAllObjects()
                // Clear cache for this hobby
                if let mainHobby = self.fetchHobby(withID: hobby.id ?? UUID()) {
                    mainHobby.invalidateEntriesCache()
                }
            }
        }
        
        return nil // Async operation, don't wait for result
    }
    
    func setEntryCompletion(for hobby: Hobby, on date: Date, completed: Bool) -> HobbyEntry? {
        // Delete existing entry if present
        if let existingEntry = hobby.getEntry(for: date) {
            context.delete(existingEntry)
        }
        
        // If we want to mark as completed, create a new entry
        if completed {
            let entry = HobbyEntry.createEntry(for: hobby, on: date, in: context)
            saveContext()
            
            // Clear cache
            hobby.invalidateEntriesCache()
            
            return entry
        } else {
            saveContext()
            
            // Clear cache
            hobby.invalidateEntriesCache()
            
            return nil
        }
    }
    
    func addEntry(for hobby: Hobby, on date: Date, notes: String? = nil) -> HobbyEntry {
        // Check if there's an existing entry and remove it
        if let existingEntry = hobby.getEntry(for: date) {
            context.delete(existingEntry)
        }
        
        // Create a new entry
        let entry = HobbyEntry(context: context)
        entry.id = UUID()
        entry.date = date
        entry.notes = notes
        entry.hobby = hobby
        entry.userId = CurrentUserService.shared.currentUserId
        
        saveContext()
        
        // Clear cache
        hobby.invalidateEntriesCache()
        
        return entry
    }
    
    func deleteEntry(_ entry: HobbyEntry) {
        let hobby = entry.hobby
        context.delete(entry)
        saveContext()
        
        // Clear cache
        hobby?.invalidateEntriesCache()
    }
    
    func fetchEntries(for hobby: Hobby) -> [HobbyEntry] {
        let fetchRequest: NSFetchRequest<HobbyEntry> = HobbyEntry.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        predicates.append(NSPredicate(format: "hobby == %@", hobby))
        
        
        if let userId = CurrentUserService.shared.currentUserId {
            predicates.append(NSPredicate(format: "userId == %@", userId))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false)
        ]
        
        return coreDataService.execute(fetchRequest)
    }
    
    // MARK: - Statistics
   
    func getCurrentStreak(for hobby: Hobby) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var streak = 0
        
        // Check if today is completed
        if hobby.hasEntry(for: today) {
            streak = 1
        } else {
            // Today is not completed, we'll check yesterday and before
            return 0
        }
        
        var currentDate = calendar.date(byAdding: .day, value: -1, to: today) // Start from yesterday
        
        // Keep checking previous days
        while let date = currentDate, hobby.hasEntry(for: date) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: date)
        }
        
        return streak
    }
    
    func getLongestStreak(for hobby: Hobby) -> Int {
        let entries = fetchEntries(for: hobby).sorted {
            ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast)
        }
        
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for entry in entries {
            guard let entryDate = entry.date else { continue }
            
            if let lastDate = lastDate {
                let components = calendar.dateComponents([.day], from: lastDate, to: entryDate)
                
                // If the days are consecutive
                if components.day == 1 {
                    currentStreak += 1
                } else {
                    // Reset the streak
                    currentStreak = 1
                }
            } else {
                // First entry
                currentStreak = 1
            }
            
            longestStreak = max(longestStreak, currentStreak)
            lastDate = entryDate
        }
        
        return longestStreak
    }
    
    // MARK: - Utility Functions
    
    // Get dates for the visualization grid
    func getDatesForDisplay(for hobby: Hobby) -> [Date] {
        let today = Date()
        let calendar = Calendar.current
        let daysToDisplay = 7
        
        var dates: [Date] = []
        
        for i in (0..<daysToDisplay).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // Predefined color options
    static func getColorOptions() -> [(name: String, hex: String, color: Color)] {
        return [
            ("Red", "#F44336", Color(hex: "#F44336")),
            ("Pink", "#E91E63", Color(hex: "#E91E63")),
            ("Purple", "#9C27B0", Color(hex: "#9C27B0")),
            ("Deep Purple", "#673AB7", Color(hex: "#673AB7")),
            ("Indigo", "#3F51B5", Color(hex: "#3F51B5")),
            ("Blue", "#2196F3", Color(hex: "#2196F3")),
            ("Light Blue", "#03A9F4", Color(hex: "#03A9F4")),
            ("Cyan", "#00BCD4", Color(hex: "#00BCD4")),
            ("Teal", "#009688", Color(hex: "#009688")),
            ("Green", "#4CAF50", Color(hex: "#4CAF50")),
            ("Light Green", "#8BC34A", Color(hex: "#8BC34A")),
            ("Lime", "#CDDC39", Color(hex: "#CDDC39")),
            ("Yellow", "#FFEB3B", Color(hex: "#FFEB3B")),
            ("Amber", "#FFC107", Color(hex: "#FFC107")),
            ("Orange", "#FF9800", Color(hex: "#FF9800")),
            ("Deep Orange", "#FF5722", Color(hex: "#FF5722")),
            ("Brown", "#795548", Color(hex: "#795548")),
            ("Grey", "#9E9E9E", Color(hex: "#9E9E9E")),
            ("Blue Grey", "#607D8B", Color(hex: "#607D8B")),
        ]
    }
    
    // Predefined icon options
    static func getIconOptions() -> [(name: String, systemName: String)] {
        return [
            ("Star", "star.fill"),
            ("Heart", "heart.fill"),
            ("Running", "figure.run"),
            ("Swimming", "figure.pool.swim"),
            ("Cycling", "bicycle"),
            ("Gym", "dumbbell.fill"),
            ("Yoga", "figure.mind.and.body"),
            ("Reading", "book.fill"),
            ("Writing", "pencil"),
            ("Coding", "chevron.left.forwardslash.chevron.right"),
            ("Music", "music.note"),
            ("Art", "paintbrush.fill"),
            ("Cooking", "fork.knife"),
            ("Meditation", "brain.head.profile"),
            ("Language", "character.bubble"),
            ("Photography", "camera.fill"),
            ("Gaming", "gamecontroller.fill"),
            ("Gardening", "leaf.fill"),
            ("Film", "film.fill"),
            ("Learning", "graduationcap.fill"),
            ("Finances", "dollarsign.circle.fill"),
            ("Walking", "figure.walk"),
            ("Sleep", "bed.double.fill"),
            ("Water", "drop.fill")
        ]
    }
    
    // MARK: - Private methods
    
    private func saveContext() {
        coreDataService.saveContext()
    }
}
