//
//  TodoTask+CoreDataProperties.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//
//

import Foundation
import CoreData


extension TodoTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TodoTask> {
        return NSFetchRequest<TodoTask>(entityName: "TodoTask")
    }

    @NSManaged public var dateCreated: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var lastModified: Date?
    @NSManaged public var priority: Int16
    @NSManaged public var tags: String?
    @NSManaged public var taskDescription: String?
    @NSManaged public var title: String?
    
    // Computed property to handle tags as an array
    public var tagArray: [String] {
        get {
            if let tags = tags {
                return tags.components(separatedBy: ",").filter { !$0.isEmpty }
            }
            return []
        }
        set {
            tags = newValue.joined(separator: ",")
        }
    }
}

extension TodoTask : Identifiable {
    
    // Helper method to use for an empty task
    static func emptyTask(context: NSManagedObjectContext) -> TodoTask {
        let task = TodoTask(context: context)
        task.id = UUID()
        task.title = ""
        task.taskDescription = ""
        task.isCompleted = false
        task.priority = 1 // Medium priority as default
        task.dateCreated = Date()
        task.lastModified = Date()
        return task
    }
}

// Priority enum for type-safe access
enum TaskPriority: Int16, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2
    
    var id: Int16 { self.rawValue }
    
    var name: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}
