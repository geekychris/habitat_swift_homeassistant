//
//  DashboardView.swift
//  SimpleHomeAssistant
//
//  Main dashboard with entity controls
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let config = viewModel.activeConfiguration {
                    // URL Toggle & Refresh
                    HStack(spacing: 12) {
                        Button(action: { viewModel.toggleUrlType() }) {
                            HStack {
                                Image(systemName: config.useInternalUrl ? "house.fill" : "globe")
                                Text(config.useInternalUrl ? "Internal" : "External")
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(config.useInternalUrl ? Color.blue : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: { Task { await viewModel.loadEntities() } }) {
                            Image(systemName: "arrow.clockwise")
                                .padding(6)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Tab Filter
                    if !viewModel.customTabs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                TabChip(title: "All", isSelected: viewModel.selectedTab == nil) {
                                    viewModel.selectTabFilter(nil)
                                }
                                ForEach(viewModel.customTabs) { tab in
                                    TabChip(title: tab.name, isSelected: viewModel.selectedTab == tab.name) {
                                        viewModel.selectTabFilter(tab.name)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Entity List
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = viewModel.error {
                        ErrorView(message: error) {
                            Task { await viewModel.loadEntities() }
                        }
                    } else if viewModel.filteredEntities.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView {
                            // Single column layout - works reliably on all devices
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredEntities) { entity in
                                    EntityCardView(entity: entity)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    NoConfigView()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if viewModel.activeConfiguration != nil && viewModel.entities.isEmpty {
                    Task { await viewModel.loadEntities() }
                }
            }
            .refreshable {
                await viewModel.loadEntities()
            }
        }
    }
}

struct TabChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No entities to display")
                .font(.headline)
            Text("Go to 'Select' tab to choose entities")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoConfigView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Active Configuration")
                .font(.title2)
                .fontWeight(.bold)
            Text("Please add and activate a configuration in the Config tab")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
