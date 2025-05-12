//
//  HobbyActivityGridView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI

struct HobbyActivityGridView: View {
    let hobby: Hobby
    let isInteractive: Bool
    let onToggle: ((Date) -> Void)?
    
    @State private var gridData: [[Date]] = [] // 2D array for GitHub-style grid
    @State private var todayIndices: (column: Int, row: Int)? = nil
    
    // Number of columns to show (represents a full year of data)
    private var columnsToDisplay: Int {
        return 52
    }
    
    // Number of rows per column based on frequency
    private var rowsPerColumn: Int {
        return 7
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Scrollable horizontal GitHub-style grid
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(0..<gridData.count, id: \.self) { colIndex in
                            VStack(spacing: 2) {
                                ForEach(0..<min(gridData[colIndex].count, rowsPerColumn), id: \.self) { rowIndex in
                                    let date = gridData[colIndex][rowIndex]
                                    let isToday = Calendar.current.isDateInToday(date)
                                    
                                    DateCell(
                                        date: date,
                                        hobby: hobby,
                                        isInteractive: isInteractive,
                                        onToggle: onToggle,
                                        isHighlighted: isToday
                                    )
                                    .frame(width: 8, height: 8)
                                }
                            }
                            .id(colIndex)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .onAppear {
                    // Scroll to the end of the grid (most recent dates) with a trailing anchor
                    // This ensures we start with the most recent dates visible
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            // Scroll to the last element with a trailing anchor
                            if gridData.count > 0 {
                                proxy.scrollTo(gridData.count - 1, anchor: .trailing)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            loadDates()
        }
    }
    
    private func loadDates() {
        let calendar = Calendar.current
        let today = Date()
        var columnsData: [[Date]] = []
        
        // Find the start of the week containing today
        let todayWeekStart = calendar.startOfWeek(for: today)
        var foundToday = false
        
        // Generate 52 weeks, starting with today's week and going backward
        for weekOffset in (0..<columnsToDisplay).reversed() {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: todayWeekStart) {
                var weekDays: [Date] = []
                
                // Add each day of the week
                for day in 0..<7 {
                    if let dayDate = calendar.date(byAdding: .day, value: day, to: weekStart) {
                        weekDays.append(dayDate)
                        
                        // Check if this is today
                        if calendar.isDateInToday(dayDate) {
                            todayIndices = (columnsData.count, day)
                            foundToday = true
                        }
                    }
                }
                
                // Add to the end (so oldest dates are first, newest are last)
                columnsData.append(weekDays)
            }
        }
        
        // Now gridData has oldest dates first, newest dates last (chronological order)
        gridData = columnsData
        
        if let indices = todayIndices {
            print("Today found at column \(indices.column), row \(indices.row)")
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(color)
                .frame(width: 10, height: 10)
                .cornerRadius(2)
            
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// Update DateCell to better highlight today
struct DateCell: View {
    let date: Date
    let hobby: Hobby
    let isInteractive: Bool
    let onToggle: ((Date) -> Void)?
    let isHighlighted: Bool
    
    @State private var isHovered = false
    
    private var isCompleted: Bool {
        hobby.hasEntry(for: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isPast: Bool {
        date <= Date()
    }
    
    private var isValid: Bool {
        return date <= Date()
    }
    
    var body: some View {
        Button(action: {
            if isInteractive && isValid && onToggle != nil {
                onToggle?(date)
            }
        }) {
            RoundedRectangle(cornerRadius: 2)
                .fill(cellColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(
                            isHighlighted ? Color.white : (isHovered && isInteractive && isValid ? Color.white.opacity(0.5) : Color.clear),
                            lineWidth: isHighlighted ? 2 : 1
                        )
                )
                .shadow(color: isHighlighted ? Color.black.opacity(0.3) : Color.clear, radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .disabled(!isInteractive || !isValid)
        .tooltip(tooltipText) // Add tooltip to show date on hover
    }
    
    private var tooltipText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date) + (isToday ? " (Today)" : "")
    }
    
    private var cellColor: Color {
        let baseColor = Color(hex: hobby.colorHex ?? "#4CAF50")
        
        if isCompleted {
            return baseColor // Green for completed
        } else if isToday {
            return baseColor.opacity(0.3) // Make today's color stronger
        } else if isPast {
            return Color.gray.opacity(0.2) // Gray for not completed past days
        } else {
            return Color.gray.opacity(0.1) // Light gray for future dates
        }
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)!
    }
    
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)!
    }
}

extension View {
    func tooltip(_ text: String) -> some View {
        self.overlay(
            GeometryReader { geometry in
                ZStack {
                    EmptyView()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        #if os(macOS)
                        NSCursor.pointingHand.push()
                        #endif
                    } else {
                        #if os(macOS)
                        NSCursor.pop()
                        #endif
                    }
                }
                .popover(isPresented: .constant(false)) {
                    Text(text)
                        .font(.caption)
                        .padding(5)
                }
            }
        )
    }
}

struct HobbyActivityGridView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Sample Preview")
        }
    }
}
