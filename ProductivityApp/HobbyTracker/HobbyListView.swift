//
//  HobbyList.swift
//  ProductivityApp
//
//  Created by Zhanserik Amangeldi on 09.05.2025.
//

import SwiftUI

struct HobbyListView: View {
    @StateObject private var viewModel = HobbyListViewModel()
    @State private var showingNewHobbySheet = false
    @State private var editingHobby: Hobby? = nil
    @State private var confirmingDelete: Hobby? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.hobbies.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.hobbies) { hobby in
                                HobbyCardView(
                                    hobby: hobby,
                                    currentStreak: viewModel.getCurrentStreak(for: hobby),
                                    onToggleToday: {
                                        viewModel.toggleToday(for: hobby)
                                    },
                                    onEdit: {
                                        editingHobby = hobby
                                    },
                                    onDelete: {
                                        confirmingDelete = hobby
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Habit Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewHobbySheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search hobbies")
            .refreshable {
                viewModel.loadHobbies()
            }
            .sheet(isPresented: $showingNewHobbySheet) {
                NavigationStack {
                    HobbyDetailView(onSave: {
                        viewModel.loadHobbies()
                    })
                }
            }
            .sheet(item: $editingHobby) { hobby in
                NavigationStack {
                    HobbyDetailView(hobby: hobby, onSave: {
                        viewModel.loadHobbies()
                    })
                }
            }
            .alert("Delete Hobby", isPresented: Binding(
                get: { confirmingDelete != nil },
                set: { if !$0 { confirmingDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    confirmingDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let hobby = confirmingDelete {
                        viewModel.deleteHobby(hobby)
                    }
                    confirmingDelete = nil
                }
            } message: {
                if let hobby = confirmingDelete {
                    Text("Are you sure you want to delete '\(hobby.unwrappedTitle)'? This will remove all entries and cannot be undone.")
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Hobbies Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Track your hobbies and build consistent habits")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            Button(action: {
                showingNewHobbySheet = true
            }) {
                Text("Add Your First Hobby")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 16)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HobbyCardView: View {
    let hobby: Hobby
    let currentStreak: Int
    let onToggleToday: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDetail = false
    
    private var hobbyColor: Color {
        Color(hex: hobby.colorHex ?? "#4CAF50")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top section with title and actions
            HStack(alignment: .top) {
                // Icon and title
                HStack(spacing: 12) {
                    Image(systemName: hobby.unwrappedIconName)
                        .font(.title)
                        .foregroundColor(hobbyColor)
                        .frame(width: 40, height: 40)
                        .background(hobbyColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hobby.unwrappedTitle)
                            .font(.headline)
                        
                        Text(hobby.unwrappedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Today's completion button
                Button(action: onToggleToday) {
                    Image(systemName: hobby.hasEntry(for: Date()) ? "checkmark.square.fill" : "square")
                        .font(.title2)
                        .foregroundColor(hobby.hasEntry(for: Date()) ? hobbyColor : .gray)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                // Activity grid
                HobbyActivityGridView(
                    hobby: hobby,
                    isInteractive: false,
                    onToggle: nil
                    )
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, -8)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingDetail) {
            NavigationStack {
                HobbyDetailView(hobby: hobby, viewOnly: true)
            }
        }
        .contextMenu {
            Button {
                showingDetail = true
            } label: {
                Label("Details", systemImage: "info.circle")
            }
            
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct HobbyListView_Previews: PreviewProvider {
    static var previews: some View {
        HobbyListView()
    }
}
