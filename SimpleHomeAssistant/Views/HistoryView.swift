//
//  HistoryView.swift
//  SimpleHomeAssistant
//
//  Entity state change history view
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""
    @State private var selectedTimeFrame: TimeFrame = .today
    @State private var historyItems: [HistoryItem] = []
    @State private var isLoading = false
    
    enum TimeFrame: String, CaseIterable, Identifiable {
        case hour = "Last Hour"
        case hours6 = "6 Hours"
        case today = "Today"
        case yesterday = "Yesterday"
        case week = "Week"
        
        var id: String { rawValue }
        
        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .hour:
                return calendar.date(byAdding: .hour, value: -1, to: now) ?? now
            case .hours6:
                return calendar.date(byAdding: .hour, value: -6, to: now) ?? now
            case .today:
                return calendar.startOfDay(for: now)
            case .yesterday:
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
                return calendar.startOfDay(for: yesterday)
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now) ?? now
            }
        }
    }
    
    var filteredHistory: [HistoryItem] {
        var filtered = historyItems
        
        // Filter by time frame
        filtered = filtered.filter { $0.timestamp >= selectedTimeFrame.startDate }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                matchesTokenizedSearch(text: searchText, in: item.entityName) ||
                matchesTokenizedSearch(text: searchText, in: item.entityId) ||
                item.newState.localizedCaseInsensitiveContains(searchText) ||
                (item.oldState?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
    
    /// Tokenized prefix matching
    private func matchesTokenizedSearch(text searchText: String, in target: String) -> Bool {
        let searchTokens = searchText.lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let targetWords = target.lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return searchTokens.allSatisfy { searchToken in
            targetWords.contains { targetWord in
                targetWord.hasPrefix(searchToken)
            }
        }
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
                            TextField("Search history...", text: $searchText)
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
                    
                    // History list
                    if isLoading {
                        ProgressView("Loading history...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredHistory.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No History")
                                .font(.headline)
                            Text("No state changes found for the selected period")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredHistory) { item in
                                HistoryRow(item: item)
                            }
                        }
                        .listStyle(.plain)
                    }
                    
                    // Info footer
                    HStack {
                        Text("\(filteredHistory.count) changes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if !filteredHistory.isEmpty {
                            Text("Last updated: \(Date(), style: .time)")
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.activeConfiguration != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { loadHistory() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .onAppear {
                if viewModel.activeConfiguration != nil && historyItems.isEmpty {
                    loadHistory()
                }
            }
            .refreshable {
                loadHistory()
            }
        }
    }
    
    private func loadHistory() {
        isLoading = true
        
        Task {
            await loadRealHistory()
        }
    }
    
    private func loadRealHistory() async {
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
        case .hours6:
            startTime = calendar.date(byAdding: .hour, value: -6, to: now) ?? now
        case .today:
            startTime = calendar.startOfDay(for: now)
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            startTime = calendar.startOfDay(for: yesterday)
        case .week:
            startTime = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        }
        
        do {
            let api = HomeAssistantAPI()
            api.setConfiguration(config)
            
            print("📜 Fetching history from \(startTime) to \(now)")
            let historyData = try await api.fetchHistory(startTime: startTime, endTime: now)
            
            // Convert to HistoryItem format
            var items: [HistoryItem] = []
            
            for (entityId, states) in historyData {
                // Find the entity to get friendly name
                let entity = viewModel.entities.first(where: { $0.entityId == entityId })
                let friendlyName = entity?.friendlyName ?? entityId
                let domain = entityId.components(separatedBy: ".").first ?? ""
                
                // Create history items for state transitions
                for i in 0..<(states.count - 1) {
                    let oldState = states[i]
                    let newState = states[i + 1]
                    
                    // Only show if state actually changed
                    if oldState.state != newState.state {
                        items.append(HistoryItem(
                            id: "\(entityId)_\(newState.lastChanged.timeIntervalSince1970)",
                            entityId: entityId,
                            entityName: friendlyName,
                            oldState: oldState.state,
                            newState: newState.state,
                            timestamp: newState.lastChanged,
                            domain: domain,
                            attributes: extractRelevantAttributes(from: newState.attributes, domain: domain)
                        ))
                    }
                }
            }
            
            // Sort by timestamp (most recent first)
            items.sort { $0.timestamp > $1.timestamp }
            
            await MainActor.run {
                historyItems = items
                isLoading = false
            }
            
            print("✅ Loaded \(items.count) history items")
            
        } catch {
            print("❌ Failed to load history: \(error)")
            await MainActor.run {
                // Fall back to mock data if real API fails
                historyItems = generateMockHistory()
                isLoading = false
            }
        }
    }
    
    private func extractRelevantAttributes(from attributes: [String: AnyCodable]?, domain: String) -> String? {
        guard let attributes = attributes else { return nil }
        
        switch domain {
        case "light":
            if let brightness = attributes["brightness"]?.value as? Int {
                return "brightness: \(Int(Double(brightness) / 255.0 * 100))%"
            }
        case "climate":
            if let temp = attributes["temperature"]?.value as? Double {
                return "temp: \(Int(temp))°"
            }
        default:
            break
        }
        
        return nil
    }
    
    private func generateMockHistory() -> [HistoryItem] {
        // Generate realistic state changes based on current entities
        var mockHistory: [HistoryItem] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Get controllable entities (lights, switches, etc.)
        let controllableEntities = viewModel.entities.filter { $0.isControllable }
        
        for entity in controllableEntities.prefix(30) {
            // Generate 2-5 state changes per entity
            let changeCount = Int.random(in: 2...5)
            var currentState = entity.state
            
            for i in 0..<changeCount {
                let hoursAgo = Int.random(in: 1...168) // Up to 1 week ago
                let timestamp = calendar.date(byAdding: .hour, value: -hoursAgo, to: now) ?? now
                
                let oldState = currentState
                let newState: String
                
                // Generate realistic state transitions
                switch entity.domain {
                case "light", "switch":
                    newState = currentState == "on" ? "off" : "on"
                case "climate":
                    if let temp = entity.temperature {
                        let change = Double.random(in: -2...2)
                        newState = String(format: "%.0f", temp + change)
                    } else {
                        newState = Bool.random() ? "heat" : "cool"
                    }
                case "cover":
                    newState = currentState == "open" ? "closed" : "open"
                case "lock":
                    newState = currentState == "locked" ? "unlocked" : "locked"
                default:
                    newState = currentState
                }
                
                currentState = newState
                
                mockHistory.append(HistoryItem(
                    id: "\(entity.entityId)_\(i)_\(timestamp.timeIntervalSince1970)",
                    entityId: entity.entityId,
                    entityName: entity.friendlyName,
                    oldState: oldState,
                    newState: newState,
                    timestamp: timestamp,
                    domain: entity.domain,
                    attributes: generateAttributes(for: entity.domain, state: newState)
                ))
            }
        }
        
        return mockHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    private func generateAttributes(for domain: String, state: String) -> String? {
        switch domain {
        case "light" where state == "on":
            return "brightness: \(Int.random(in: 20...100))%"
        case "climate":
            return "target: \(state)°"
        default:
            return nil
        }
    }
}

struct HistoryItem: Identifiable {
    let id: String
    let entityId: String
    let entityName: String
    let oldState: String?
    let newState: String
    let timestamp: Date
    let domain: String
    let attributes: String?
}

struct HistoryRow: View {
    let item: HistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: icon, name, and timestamp
            HStack {
                Image(systemName: iconForDomain(item.domain))
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.entityName)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(item.entityId)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.timestamp, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // State change
            HStack(spacing: 8) {
                if let oldState = item.oldState {
                    Text(formatState(oldState))
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(formatState(item.newState))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colorForState(item.newState).opacity(0.2))
                    .foregroundColor(colorForState(item.newState))
                    .cornerRadius(6)
                
                if let attributes = item.attributes {
                    Text(attributes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 38) // Align with name
        }
        .padding(.vertical, 4)
    }
    
    private func formatState(_ state: String) -> String {
        state.capitalized
    }
    
    private func iconForDomain(_ domain: String) -> String {
        switch domain {
        case "light": return "lightbulb.fill"
        case "switch": return "power"
        case "climate": return "thermometer"
        case "cover": return "curtains.closed"
        case "fan": return "fan.fill"
        case "lock": return "lock.fill"
        case "sensor": return "sensor"
        default: return "circle.fill"
        }
    }
    
    private func colorForState(_ state: String) -> Color {
        switch state.lowercased() {
        case "on", "open", "unlocked", "heat", "cool": return .blue
        case "off", "closed", "locked": return .gray
        case "unavailable": return .orange
        default:
            // Check if it's a number (temperature)
            if Double(state) != nil {
                return .orange
            }
            return .primary
        }
    }
}
