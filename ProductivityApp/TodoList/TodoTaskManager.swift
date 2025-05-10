//
//  TodoTaskManager.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ProductivityApp")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    // MARK: - Core Data Saving Support
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Todo Task Operations
    
    func createTask(title: String, description: String, dueDate: Date?, priority: TaskPriority, tags: [String] = []) -> TodoTask {
        let context = persistentContainer.viewContext
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
        let context = persistentContainer.viewContext
        context.delete(task)
        saveContext()
    }
    
    func toggleTaskCompletion(_ task: TodoTask) {
        task.isCompleted.toggle()
        task.lastModified = Date()
        saveContext()
    }
    
    func fetchTasks(isCompleted: Bool? = nil, searchText: String? = nil, priorityFilter: TaskPriority? = nil, tagFilter: String? = nil) -> [TodoTask] {
        let context = persistentContainer.viewContext
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
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching tasks: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchTaskCount(isCompleted: Bool? = nil) -> Int {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        
        if let isCompleted = isCompleted {
            fetchRequest.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: isCompleted))
        }
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("Error counting tasks: \(error.localizedDescription)")
            return 0
        }
    }
    
    func fetchTask(withID id: UUID) -> TodoTask? {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let tasks = try context.fetch(fetchRequest)
            return tasks.first
        } catch {
            print("Error fetching task with ID \(id): \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchAllTags() -> [String] {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        
        do {
            let tasks = try context.fetch(fetchRequest)
            let allTags = tasks.flatMap { task in
                return task.tagArray
            }
            return Array(Set(allTags)).sorted()
        } catch {
            print("Error fetching all tags: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Helper Methods
    
    func getTodaysTasks() -> [TodoTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == %@", startOfDay as NSDate, endOfDay as NSDate, NSNumber(value: false))
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching today's tasks: \(error.localizedDescription)")
            return []
        }
    }
    
    func getUpcomingTasks(days: Int = 7) -> [TodoTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfPeriod = calendar.date(byAdding: .day, value: days, to: startOfDay)!
        
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate <= %@ AND isCompleted == %@", startOfDay as NSDate, endOfPeriod as NSDate, NSNumber(value: false))
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching upcoming tasks: \(error.localizedDescription)")
            return []
        }
    }
    
    func getOverdueTasks() -> [TodoTask] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TodoTask> = TodoTask.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dueDate < %@ AND isCompleted == %@", startOfDay as NSDate, NSNumber(value: false))
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching overdue tasks: \(error.localizedDescription)")
            return []
        }
    }
}
