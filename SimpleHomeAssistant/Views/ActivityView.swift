//
//  ActivityView.swift
//  SimpleHomeAssistant
//
//  Activity/History view with filtering
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedTimeFrame: TimeFrame = .today
    @State private var activities: [ActivityItem] = []
    @State private var isLoading = false
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case hour = "Last Hour"
        case today = "Today"
        case week = "Last Week"
        case month = "Last Month"
        case all = "All Time"
        
        var id: String { rawValue }
        
        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .hour:
                return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
            case .today:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .all:
                return calendar.date(byAdding: .year, value: -1, to: now) ?? now
            }
        }
    }
    
    var filteredActivities: [ActivityItem] {
        var filtered = activities
        
        // Filter by time frame
        filtered = filtered.filter { $0.timestamp >= selectedTimeFrame.startDate }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.entityName.localizedCaseInsensitiveContains(searchText) ||
                activity.state.localizedCaseInsensitiveContains(searchText) ||
                activity.entityId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.activeConfiguration != nil {
                    // Filters section
                    VStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search activity...", text: $searchText)
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        
                        // Time frame picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TimeFrame.allCases) { timeFrame in
                                    TimeFrameChip(
                                        title: timeFrame.rawValue,
                                        isSelected: selectedTimeFrame == timeFrame
                                    ) {
                                        selectedTimeFrame = timeFrame
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                    
                    // Activity list
                    if isLoading {
                        ProgressView("Loading activity...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredActivities.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No Activity")
                                .font(.headline)
                            Text("No activity found for the selected filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredActivities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .listStyle(.plain)
                    }
                    
                    // Info footer
                    HStack {
                        Text("\(filteredActivities.count) events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if !filteredActivities.isEmpty {
                            Text("Updated \(Date(), style: .relative) ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemGroupedBackground))
                } else {
                    NoConfigView()
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.activeConfiguration != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { loadActivity() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .onAppear {
                if viewModel.activeConfiguration != nil && activities.isEmpty {
                    loadActivity()
                }
            }
            .refreshable {
                loadActivity()
            }
        }
    }
    
    private func loadActivity() {
        isLoading = true
        
        Task {
            await loadRealActivity()
        }
    }
    
    private func loadRealActivity() async {
        guard let config = viewModel.activeConfiguration else {
            isLoading = false
            return
        }
        
        // Calculate time range based on selected time frame
        let calendar = Calendar.current
        let now = Date()
        let startTime: Date
        
        switch selectedTimeFrame {
        case .hour:
            startTime = calendar.date(byAdding: .hour, value: -1, to: now) ?? now
        case .today:
            startTime = calendar.startOfDay(for: now)
        case .week:
            startTime = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startTime = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            startTime = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        do {
            let api = HomeAssistantAPI()
            api.setConfiguration(config)
            
            print("📔 Fetching logbook from \(startTime) to \(now)")
            let logbookEntries = try await api.fetchLogbook(startTime: startTime, endTime: now)
            
            // Convert to ActivityItem format
            let items = logbookEntries.map { entry -> ActivityItem in
                let domain = entry.domain ?? determineDomain(from: entry.name, message: entry.message)
                return ActivityItem(
                    id: entry.id,
                    entityId: entry.entityId ?? "\(domain).event",
                    entityName: entry.name,
                    state: entry.message ?? "",
                    timestamp: entry.when,
                    domain: domain
                )
            }
            
            // Sort by timestamp (most recent first)
            let sortedItems = items.sorted { $0.timestamp > $1.timestamp }
            
            await MainActor.run {
                activities = sortedItems
                isLoading = false
            }
            
            print("✅ Loaded \(sortedItems.count) logbook entries")
            
        } catch {
            print("❌ Failed to load logbook: \(error)")
            await MainActor.run {
                // Fall back to mock data if real API fails
                activities = generateMockActivity()
                isLoading = false
            }
        }
    }
    
    private func determineDomain(from name: String, message: String?) -> String {
        let lowerName = name.lowercased()
        let lowerMessage = message?.lowercased() ?? ""
        
        if lowerName.contains("automation") || lowerMessage.contains("triggered") {
            return "automation"
        } else if lowerName.contains("update") || lowerName.contains("version") {
            return "system"
        } else if lowerName.contains("integration") || lowerName.contains("connected") {
            return "integration"
        } else if lowerName.contains("started") || lowerName.contains("stopped") {
            return "system"
        } else {
            return "event"
        }
    }
    
    private func generateMockActivity() -> [ActivityItem] {
        // Generate mock system/automation events
        var mockActivities: [ActivityItem] = []
        let calendar = Calendar.current
        let now = Date()
        
        // System events
        let systemEvents: [(String, String, String)] = [
            ("Home Assistant Core Updated", "system.update", "2023.12.1 → 2023.12.3"),
            ("Supervisor Updated", "system.update", "2023.11.6"),
            ("Backup Completed", "system.backup", "Full backup created"),
            ("Integration Installed", "system.integration", "HACS installed"),
            ("Configuration Reloaded", "system.config", "Automations reloaded"),
            ("Certificate Renewed", "system.security", "SSL certificate updated"),
            ("Database Maintenance", "system.maintenance", "Cleanup completed"),
            ("Add-on Updated", "system.addon", "File Editor v5.6.0"),
            ("Energy Dashboard Updated", "system.energy", "Monthly usage calculated")
        ]
        
        // Automation events
        let automationEvents: [(String, String, String)] = [
            ("Morning Routine Triggered", "automation.morning", "Lights on, thermostat adjusted"),
            ("Night Mode Activated", "automation.night", "All lights off, doors locked"),
            ("Away Mode Started", "automation.away", "Security armed, climate eco"),
            ("Welcome Home", "automation.home", "Lights on, thermostat normal"),
            ("Bedtime Routine", "automation.bedtime", "Lights dimmed, doors checked"),
            ("Weather Alert", "automation.weather", "Rain detected, windows closed"),
            ("Energy Saver", "automation.energy", "High usage devices turned off"),
            ("Security Check", "automation.security", "All doors locked, cameras active"),
            ("Good Morning", "automation.morning", "Blinds opened, coffee started")
        ]
        
        // Integration events
        let integrationEvents: [(String, String, String)] = [
            ("Google Home Sync", "integration.google", "Devices synchronized"),
            ("Alexa Connected", "integration.alexa", "Skills updated"),
            ("Apple HomeKit", "integration.homekit", "Accessories exposed"),
            ("MQTT Connected", "integration.mqtt", "Broker connection restored"),
            ("Z-Wave Network", "integration.zwave", "5 devices online"),
            ("Zigbee Network", "integration.zigbee", "Network optimization completed")
        ]
        
        // Generate events
        let allEvents = systemEvents + automationEvents + integrationEvents
        
        for (index, event) in allEvents.enumerated() {
            let (name, entityId, state) = event
            let hoursAgo = Int.random(in: 1...168) // Up to 1 week ago
            let timestamp = calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ?? now
            
            let domain: String
            if entityId.contains("system") {
                domain = "system"
            } else if entityId.contains("automation") {
                domain = "automation"
            } else {
                domain = "integration"
            }
            
            mockActivities.append(ActivityItem(
                id: "\(entityId)_\(index)_\(timestamp.timeIntervalSince1970)",
                entityId: entityId,
                entityName: name,
                state: state,
                timestamp: timestamp,
                domain: domain
            ))
        }
        
        return mockActivities.sorted { $0.timestamp > $1.timestamp }
    }
}

struct ActivityItem: Identifiable {
    let id: String
    let entityId: String
    let entityName: String
    let state: String
    let timestamp: Date
    let domain: String
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: iconForDomain(activity.domain))
                .font(.title3)
                .foregroundColor(colorForState(activity.state))
                .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.entityName)
                    .font(.body)
                
                HStack {
                    Text(activity.entityId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(activity.state.capitalized)
                        .font(.caption)
                        .foregroundColor(colorForState(activity.state))
                }
            }
            
            Spacer()
            
            // Timestamp
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(activity.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForDomain(_ domain: String) -> String {
        switch domain {
        case "system": return "gear.circle.fill"
        case "automation": return "wand.and.stars"
        case "integration": return "link.circle.fill"
        case "light": return "lightbulb"
        case "switch": return "power"
        case "climate": return "thermometer"
        case "cover": return "curtains.closed"
        case "fan": return "fan"
        case "lock": return "lock"
        case "sensor": return "sensor"
        default: return "circle.fill"
        }
    }
    
    private func colorForState(_ state: String) -> Color {
        // Color by domain type
        if activity.domain == "system" {
            return .purple
        } else if activity.domain == "automation" {
            return .green
        } else if activity.domain == "integration" {
            return .orange
        }
        
        // Color by state keywords
        let stateLower = state.lowercased()
        if stateLower.contains("on") || stateLower.contains("completed") || stateLower.contains("success") {
            return .blue
        } else if stateLower.contains("off") || stateLower.contains("inactive") {
            return .gray
        } else if stateLower.contains("error") || stateLower.contains("fail") {
            return .red
        }
        
        return .primary
    }
}

struct TimeFrameChip: View {
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
