//
//  EntityCardView.swift
//  SimpleHomeAssistant
//
//  Entity control card
//

import SwiftUI

struct EntityCardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    let entity: HAEntity
    @State private var brightness: Double = 0
    @State private var isProcessing: Bool = false
    @State private var debounceTask: Task<Void, Never>?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForEntity)
                    .font(.title2)
                    .foregroundColor(entity.isOn ? .blue : .gray)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entity.friendlyName)
                        .font(.headline)
                    Text(entity.entityId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Loading indicator
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                // Main control
                if entity.domain == "light" || entity.domain == "switch" {
                    Toggle("", isOn: Binding(
                        get: { entity.isOn },
                        set: { _ in handleToggle() }
                    ))
                    .labelsHidden()
                    .disabled(isProcessing)
                } else if entity.domain == "climate" {
                    // Climate on/off toggle
                    Toggle("", isOn: Binding(
                        get: { entity.isOn },
                        set: { _ in handleClimateToggle() }
                    ))
                    .labelsHidden()
                    .disabled(isProcessing)
                } else if entity.domain == "sensor" || entity.domain == "binary_sensor" {
                    HStack(spacing: 4) {
                        Text(entity.state)
                            .font(.title3)
                            .fontWeight(.semibold)
                        if let unit = entity.unitOfMeasurement {
                            Text(unit)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Additional controls
            if entity.domain == "light" && entity.isOn, let entityBrightness = entity.brightness {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Brightness: \(Int(brightness))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $brightness, in: 0...100, step: 1)
                        .onChange(of: brightness) { _ in
                            handleBrightnessChange()
                        }
                        .onAppear {
                            brightness = Double(entityBrightness) * 100 / 255
                        }
                        .disabled(isProcessing)
                }
            } else if entity.domain == "climate", let temp = entity.temperature {
                VStack(spacing: 8) {
                    HStack {
                        Text("Temperature:")
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: { handleTemperatureChange(temp - 1) }) {
                                Image(systemName: "minus.circle")
                                    .font(.title2)
                            }
                            .disabled(isProcessing)
                            
                            Text("\(Int(temp))°")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(minWidth: 50)
                            
                            Button(action: { handleTemperatureChange(temp + 1) }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                            }
                            .disabled(isProcessing)
                        }
                    }
                    
                    if let hvacMode = entity.hvacMode, let modes = entity.attributes.hvacModes {
                        HStack {
                            Text("Mode:")
                                .font(.subheadline)
                            Spacer()
                            Menu {
                                ForEach(modes, id: \.self) { mode in
                                    Button(mode.capitalized) {
                                        handleModeChange(mode)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(hvacMode.capitalized)
                                        .font(.subheadline)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .disabled(isProcessing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var iconForEntity: String {
        switch entity.domain {
        case "light": return entity.isOn ? "lightbulb.fill" : "lightbulb"
        case "switch": return entity.isOn ? "power" : "poweroff"
        case "climate": return "thermometer"
        case "sensor": return "gauge"
        case "binary_sensor": return entity.isOn ? "checkmark.circle.fill" : "circle"
        default: return "square.grid.2x2"
        }
    }
    
    // MARK: - Action Handlers with Debouncing
    
    private func handleToggle() {
        guard !isProcessing else { return }
        isProcessing = true
        Task {
            await viewModel.toggleEntity(entity)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            isProcessing = false
        }
    }
    
    private func handleClimateToggle() {
        guard !isProcessing else { return }
        isProcessing = true
        Task {
            // Toggle climate by turning it on or off
            if entity.isOn {
                await viewModel.setHvacMode(entity, mode: "off")
            } else {
                // Turn on to last mode or heat
                if let modes = entity.attributes.hvacModes, !modes.isEmpty {
                    let onMode = modes.first(where: { $0 != "off" }) ?? "heat"
                    await viewModel.setHvacMode(entity, mode: onMode)
                }
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            isProcessing = false
        }
    }
    
    private func handleBrightnessChange() {
        // Cancel previous debounce task
        debounceTask?.cancel()
        
        // Create new debounced task
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s debounce
            guard !Task.isCancelled else { return }
            
            isProcessing = true
            await viewModel.setBrightness(entity, brightness: brightness)
            try? await Task.sleep(nanoseconds: 200_000_000)
            isProcessing = false
        }
    }
    
    private func handleTemperatureChange(_ newTemp: Double) {
        guard !isProcessing else { return }
        isProcessing = true
        Task {
            await viewModel.setTemperature(entity, temperature: newTemp)
            try? await Task.sleep(nanoseconds: 500_000_000)
            isProcessing = false
        }
    }
    
    private func handleModeChange(_ mode: String) {
        guard !isProcessing else { return }
        isProcessing = true
        Task {
            await viewModel.setHvacMode(entity, mode: mode)
            try? await Task.sleep(nanoseconds: 500_000_000)
            isProcessing = false
        }
    }
}
