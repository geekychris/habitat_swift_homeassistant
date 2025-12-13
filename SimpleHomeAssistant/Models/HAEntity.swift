//
//  HAEntity.swift
//  SimpleHomeAssistant
//
//  Model for Home Assistant entities
//

import Foundation

struct HAEntity: Identifiable, Codable {
    let entityId: String
    var state: String
    var attributes: EntityAttributes
    var lastChanged: String?
    var lastUpdated: String?
    
    var id: String { entityId }
    
    var domain: String {
        entityId.components(separatedBy: ".").first ?? ""
    }
    
    var friendlyName: String {
        attributes.friendlyName ?? entityId
    }
    
    var isControllable: Bool {
        ["light", "switch", "climate", "cover", "fan", "lock"].contains(domain)
    }
    
    var isOn: Bool {
        if domain == "climate" {
            // Climate entities are "on" when not in "off" mode
            return state.lowercased() != "off" && state.lowercased() != "unavailable"
        }
        return state.lowercased() == "on"
    }
    
    var brightness: Int? {
        attributes.brightness
    }
    
    var temperature: Double? {
        attributes.temperature ?? attributes.currentTemperature
    }
    
    var hvacMode: String? {
        attributes.hvacMode
    }
    
    var unitOfMeasurement: String? {
        attributes.unitOfMeasurement
    }
    
    struct EntityAttributes: Codable {
        var friendlyName: String?
        var brightness: Int?
        var temperature: Double?
        var currentTemperature: Double?
        var hvacMode: String?
        var hvacModes: [String]?
        var unitOfMeasurement: String?
        
        enum CodingKeys: String, CodingKey {
            case friendlyName = "friendly_name"
            case brightness
            case temperature
            case currentTemperature = "current_temperature"
            case hvacMode = "hvac_mode"
            case hvacModes = "hvac_modes"
            case unitOfMeasurement = "unit_of_measurement"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case attributes
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
    }
}
