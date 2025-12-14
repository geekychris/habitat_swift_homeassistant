//
//  ContentView.swift
//  SimpleHomeAssistant
//
//  Main navigation view with tab bar - mirrors Android bottom navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedTab = 0
    
    var currentPageName: String {
        switch selectedTab {
        case 0: return "Dashboard"
        case 1: return "History"
        case 2: return "Events"
        case 3: return "Configurations"
        case 4: return "Custom Tabs"
        default: return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header with app branding and page name
            HStack(alignment: .center, spacing: 12) {
                // App branding (left side)
                HStack(spacing: 8) {
                    Image(systemName: "house.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("HA-bitat")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Page name (right side)
                Text(currentPageName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.8))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Main content with tabs
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                    .tag(0)
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.2.circlepath")
                    }
                    .tag(1)
                
                ActivityView()
                    .tabItem {
                        Label("Events", systemImage: "bell.fill")
                    }
                    .tag(2)
                
                ConfigurationView()
                    .tabItem {
                        Label("Config", systemImage: "gearshape.fill")
                    }
                    .tag(3)
                
                TabManagementView()
                    .tabItem {
                        Label("Tabs", systemImage: "square.grid.2x2")
                    }
                    .tag(4)
            }
            .environmentObject(viewModel)
            .accentColor(.blue)
        }
    }
}

#Preview {
    ContentView()
}
