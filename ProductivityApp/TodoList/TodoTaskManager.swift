//
//  TodoTaskManager.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import CoreData

class TodoTaskManager {
    static let shared = TodoTaskManager()
    
    private let coreDataService = CoreDataService.shared
    private var context: NSManagedObjectContext {
        return coreDataService.viewContext
    }
    
    private init() {}
    
    // MARK: - Todo Task Operations

    func createTask(title: String, description: String, dueDate: Date?, priority: TaskPriority, tags: [String] = []) -> TodoTask {
        let task = TodoTask(context: context)
        
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.dueDate = dueDate
        task.isCompleted = false
        task.priority = priority.rawValue
        task.dateCreated = Date()
        task.lastModified = Date()
        task.tagArray = tags
        
        saveContext()
        return task
    }
    
    func updateTask(_ task: TodoTask) {
        task.lastModified = Date()
        saveContext()
    }
    
    func deleteTask(_ task: TodoTask) {
        context.delete(task)
        saveContext()
    }
    
    func toggleTaskCompletion(_ task: TodoTask) {
        task.isCompleted.toggle()
        task.lastModified = Date()
        saveContext()
    }
    
    func fetchTasks(isCompleted: Bool? = nil, searchText: String? = nil, priorityFilter: TaskPriority? = nil, tagFilter: String? = nil) -> [TodoTask] {
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        
        // Build predicates for filtering
        var predicates: [NSPredicate] = []
        
        // Filter by completion status if specified
        if let isCompleted = isCompleted {
            predicates.append(NSPredicate(format: "isCompleted == %@", NSNumber(value: isCompleted)))
        }
        
        // Filter by search text if provided
        if let searchText = searchText, !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR taskDescription CONTAINS[cd] %@ OR tags CONTAINS[cd] %@", searchText, searchText, searchText))
        }
        
        // Filter by priority if specified
        if let priorityFilter = priorityFilter {
            predicates.append(NSPredicate(format: "priority == %@", NSNumber(value: priorityFilter.rawValue)))
        }
        
        // Filter by tag if specified
        if let tagFilter = tagFilter, !tagFilter.isEmpty {
            predicates.append(NSPredicate(format: "tags CONTAINS[cd] %@", tagFilter))
        }
        
        // Combine predicates if needed
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // Sort by due date, priority, and lastModified
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "isCompleted", ascending: true),
            NSSortDescriptor(key: "dueDate", ascending: true),
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "lastModified", ascending: false)
        ]
        
        return coreDataService.execute(fetchRequest)
    }
    
    func fetchTaskCount(isCompleted: Bool? = nil) -> Int {
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        
        if let isCompleted = isCompleted {
            fetchRequest.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: isCompleted))
        }
        
        return coreDataService.count(fetchRequest)
    }
    
    func fetchTask(withID id: UUID) -> TodoTask? {
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        let tasks = coreDataService.execute(fetchRequest)
        return tasks.first
    }
    
    func fetchAllTags() -> [String] {
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        
        let tasks = coreDataService.execute(fetchRequest)
        let allTags = tasks.flatMap { task in
            return task.tagArray
        }
        return Array(Set(allTags)).sorted()
    }
    
    // MARK: - Helper Methods
    
    func getTodaysTasks() -> [TodoTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == %@", startOfDay as NSDate, endOfDay as NSDate, NSNumber(value: false))
        
        return coreDataService.execute(fetchRequest)
    }
    
    func getUpcomingTasks(days: Int = 7) -> [TodoTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfPeriod = calendar.date(byAdding: .day, value: days, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate <= %@ AND isCompleted == %@", startOfDay as NSDate, endOfPeriod as NSDate, NSNumber(value: false))
        
        return coreDataService.execute(fetchRequest)
    }
    
    func getOverdueTasks() -> [TodoTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dueDate < %@ AND isCompleted == %@", startOfDay as NSDate, NSNumber(value: false))
        
        return coreDataService.execute(fetchRequest)
    }
    
    // MARK: - Private methods
    
    private func saveContext() {
        coreDataService.saveContext()
    }
}
