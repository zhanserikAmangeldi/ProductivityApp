//
//  CoreDataService.swift
//  ProductivityApp
//
//  Created by Kassiman Alikhan on 12.05.2025.
//

import Foundation
import CoreData

class CoreDataService {
    static let shared = CoreDataService()
    
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
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
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
    
    // MARK: - Batch Operations
    
    func execute<T>(_ fetchRequest: NSFetchRequest<T>) -> [T] {
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error executing fetch request: \(error.localizedDescription)")
            return []
        }
    }
    
    func count<T>(_ fetchRequest: NSFetchRequest<T>) -> Int {
        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("Error counting entities: \(error.localizedDescription)")
            return 0
        }
    }
    
    private init() {}
}
