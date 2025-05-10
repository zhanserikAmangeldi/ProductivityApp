//
//  HobbyDetailView.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI

struct HobbyDetailView: View {
    @StateObject private var viewModel: HobbyDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // View control properties
    @State private var showingColorPicker = false
    @State private var showingIconPicker = false
    @State private var viewOnly: Bool
    private var hobby: Hobby?
    
    var onSave: (() -> Void)?
    
    init(hobby: Hobby? = nil, viewOnly: Bool = false, onSave: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: HobbyDetailViewModel(hobby: hobby))
        self._viewOnly = State(initialValue: viewOnly)
        self.onSave = onSave
        self.hobby = hobby
    }
    
    var body: some View {
        Group {
            if viewOnly {
                detailContent
                    .navigationTitle(viewModel.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                dismiss()
                            }
                        }
                    }
            } else {
                Form {
                    editContent
                }
                .navigationTitle(viewModel.pageTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            if viewModel.saveHobby() {
                                onSave?()
                                dismiss()
                            }
                        }
                        .disabled(!viewModel.isValid || viewModel.isSaving)
                    }
                }
                .overlay {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                    }
                }
                .alert("Error", isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    }
                }
                .sheet(isPresented: $showingColorPicker) {
                    ColorPickerView(
                        selectedColorHex: $viewModel.selectedColorHex,
                        colors: viewModel.colorOptions
                    )
                }
                .sheet(isPresented: $showingIconPicker) {
                    IconPickerView(
                        selectedIconName: $viewModel.selectedIconName,
                        icons: viewModel.iconOptions,
                        colorHex: viewModel.selectedColorHex
                    )
                }
            }
        }
    }
    
    // MARK: - Detail View (Read-Only)
    
    private var detailContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with icon and stats
                hobbyHeader
                
                // Activity grid
                activityGridSection
                
                // Stats cards
                statsCardsSection
            }
            .padding()
        }
    }
    
    private var hobbyHeader: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: viewModel.selectedIconName)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 70, height: 70)
                .background(viewModel.buttonColor)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            
            // Title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !viewModel.description.isEmpty {
                    Text(viewModel.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var activityGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)
            
            // Calendar grid with the new component
            HobbyActivityGridView(
                hobby: createTemporaryHobbyForDisplay(),
                isInteractive: !viewOnly,
                onToggle: { date in
                    viewModel.toggleCompletion(for: date)
                }
            )
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Legend
            HStack(spacing: 12) {
                legendItem(color: viewModel.buttonColor, label: "Completed")
                legendItem(color: viewModel.buttonColor.opacity(0.3), label: "Today")
                legendItem(color: Color.gray.opacity(0.2), label: "Not Completed")
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // Helper to get a hobby instance for the display
    private func createTemporaryHobbyForDisplay() -> Hobby {
        // If we have a real hobby, use it
        if let existingHobby = hobby {
            return existingHobby
        }
        
        // Otherwise, create a temporary one from viewModel data
        return viewModel.createTemporaryHobby()
    }
    
    private var statsCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Current streak card
                statCard(
                    value: "\(viewModel.currentStreak)",
                    label: "Current Streak",
                    icon: "flame.fill"
                )
                
                // Longest streak card
                statCard(
                    value: "\(viewModel.longestStreak)",
                    label: "Longest Streak",
                    icon: "trophy.fill"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.buttonColor)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(viewModel.buttonColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(viewModel.buttonColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Edit Content (Form)
    
    private var editContent: some View {
        Group {
            // Basic info section
            Section(header: Text("Basic Information")) {
                TextField("Hobby Title", text: $viewModel.title)
                    .autocapitalization(.words)
                
                ZStack(alignment: .topLeading) {
                    if viewModel.description.isEmpty {
                        Text("Description (optional)")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 100)
                        .padding(.leading, -5)
                }
            }
            
            // Appearance section
            Section(header: Text("Appearance")) {
                // Icon picker
                HStack {
                    Text("Icon")
                    Spacer()
                    
                    Button(action: {
                        showingIconPicker = true
                    }) {
                        HStack {
                            Image(systemName: viewModel.selectedIconName)
                                .foregroundColor(viewModel.buttonColor)
                                .frame(width: 30, height: 30)
                                .background(viewModel.buttonColor.opacity(0.1))
                                .clipShape(Circle())
                            
                            Text("Change Icon")
                                .foregroundColor(.blue)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                
                // Color picker
                HStack {
                    Text("Color")
                    Spacer()
                    
                    Button(action: {
                        showingColorPicker = true
                    }) {
                        HStack {
                            Circle()
                                .fill(viewModel.buttonColor)
                                .frame(width: 24, height: 24)
                            
                            Text("Change Color")
                                .foregroundColor(.blue)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper functions
    
    private func cellColor(isCompleted: Bool, isToday: Bool, isPast: Bool) -> Color {
        if isCompleted {
            return viewModel.buttonColor
        } else if isToday {
            return viewModel.buttonColor.opacity(0.3)
        } else if isPast {
            return Color.gray.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
}

// MARK: - Supporting Views

struct ColorPickerView: View {
    @Binding var selectedColorHex: String
    let colors: [(name: String, hex: String, color: Color)]
    @Environment(\.dismiss) private var dismiss
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(colors, id: \.hex) { option in
                        colorOption(option: option)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func colorOption(option: (name: String, hex: String, color: Color)) -> some View {
        Button(action: {
            selectedColorHex = option.hex
        }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(option.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(option.hex == selectedColorHex ? .white : .clear, lineWidth: 3)
                            .padding(4)
                    )
                    .overlay(
                        Circle()
                            .stroke(option.hex == selectedColorHex ? option.color : .clear, lineWidth: 2)
                            .padding(2)
                    )
                    .shadow(color: option.hex == selectedColorHex ? option.color.opacity(0.6) : .clear, radius: 5)
                
                Text(option.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
    }
}

struct IconPickerView: View {
    @Binding var selectedIconName: String
    let icons: [(name: String, systemName: String)]
    let colorHex: String
    @Environment(\.dismiss) private var dismiss
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    private var accentColor: Color {
        Color(hex: colorHex)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons, id: \.systemName) { icon in
                        iconOption(icon: icon)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func iconOption(icon: (name: String, systemName: String)) -> some View {
        Button(action: {
            selectedIconName = icon.systemName
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon.systemName)
                    .font(.system(size: 28))
                    .frame(width: 60, height: 60)
                    .foregroundColor(selectedIconName == icon.systemName ? .white : accentColor)
                    .background(selectedIconName == icon.systemName ? accentColor : accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedIconName == icon.systemName ? accentColor : Color.clear, lineWidth: 2)
                    )
                
                Text(icon.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
    }
}

struct HobbyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HobbyDetailView()
        }
    }
}
