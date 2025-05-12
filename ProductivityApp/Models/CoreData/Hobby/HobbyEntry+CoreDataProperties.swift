//
//  HobbyEntry+CoreDataProperties.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import CoreData

extension HobbyEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HobbyEntry> {
        return NSFetchRequest<HobbyEntry>(entityName: "HobbyEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var notes: String?
    @NSManaged public var hobby: Hobby?
    @NSManaged public var userId: String?

    public var formattedDate: String {
        guard let date = date else { return "Unknown date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return formatter.string(from: date)
    }

}

extension HobbyEntry : Identifiable {
    
    public static func createEntry(for hobby: Hobby, on date: Date = Date(), in context: NSManagedObjectContext) -> HobbyEntry {
        let entry = HobbyEntry(context: context)
        entry.id = UUID()
        entry.date = date
        entry.hobby = hobby
        entry.userId = CurrentUserService.shared.currentUserId

        return entry
    }
    
}
