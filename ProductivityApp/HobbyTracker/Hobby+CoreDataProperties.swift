//
//  Hobby+CoreDataProperties.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import Foundation
import CoreData
import SwiftUI

extension Hobby {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Hobby> {
        return NSFetchRequest<Hobby>(entityName: "Hobby")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var hobbyDescription: String?
    @NSManaged public var iconName: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var lastModified: Date?
    @NSManaged public var entries: NSSet?
    @NSManaged public var userId: String?

    // Computed properties for convenience
    
    public var unwrappedTitle: String {
        title ?? "Unnamed Hobby"
    }
    
    public var unwrappedDescription: String {
        hobbyDescription ?? ""
    }
    
    public var unwrappedIconName: String {
        iconName ?? "star"
    }
    
    public var color: Color {
        get {
            Color(hex: colorHex ?? "#4CAF50") // Default to green if not set
        }
        set {
        }
    }
    
    public var entriesArray: [HobbyEntry] {
        let set = entries as? Set<HobbyEntry> ?? []
        return set.sorted {
            $0.date ?? Date() > $1.date ?? Date()
        }
    }
    
    // Helper to get entries for a specific date
    public func getEntry(for date: Date) -> HobbyEntry? {
        let calendar = Calendar.current
        let set = entries as? Set<HobbyEntry> ?? []
        
        return set.first { entry in
            guard let entryDate = entry.date else { return false }
            
            return calendar.isDate(entryDate, inSameDayAs: date)
        }
    }
    
    // Helper to check if there's an entry for a specific date
    public func hasEntry(for date: Date) -> Bool {
        return getEntry(for: date) != nil
    }
}

// MARK: Generated accessors for entries
extension Hobby {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: HobbyEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: HobbyEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

extension Hobby : Identifiable {
    
}

// Extension to support Color hex conversion
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}
