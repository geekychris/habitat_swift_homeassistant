//
//  HomeAssistantAPI.swift
//  SimpleHomeAssistant
//
//  Home Assistant REST API service
//

import Foundation

class HomeAssistantAPI {
    private var configuration: HAConfiguration?
    
    func setConfiguration(_ config: HAConfiguration) {
        self.configuration = config
    }
    
    // MARK: - Fetch Entities
    
    func fetchAllEntities() async throws -> [HAEntity] {
        guard let config = configuration else {
            throw APIError.noConfiguration
        }
        
        let url = URL(string: "\(config.currentUrl)/api/states")!
        var request = URLRequest(url: url)
        
        // Trim token and ensure proper format
        let cleanToken = config.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("🔗 Fetching entities from: \(config.currentUrl)")
        print("🔑 Using token: Bearer \(String(cleanToken.prefix(20)))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                print("❌ 401 Unauthorized - Check your API token")
                throw APIError.unauthorized
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let entities = try decoder.decode([HAEntity].self, from: data)
        return entities
    }
    
    // MARK: - Control Entities
    
    func toggleEntity(_ entityId: String) async throws {
        let domain = entityId.components(separatedBy: ".").first ?? ""
        try await callService(domain: domain, service: "toggle", entityId: entityId)
    }
    
    func turnOn(_ entityId: String, brightness: Int? = nil) async throws {
        var serviceData: [String: Any] = ["entity_id": entityId]
        if let brightness = brightness {
            serviceData["brightness"] = brightness
        }
        
        let domain = entityId.components(separatedBy: ".").first ?? ""
        try await callService(domain: domain, service: "turn_on", serviceData: serviceData)
    }
    
    func turnOff(_ entityId: String) async throws {
        let domain = entityId.components(separatedBy: ".").first ?? ""
        try await callService(domain: domain, service: "turn_off", entityId: entityId)
    }
    
    func setTemperature(_ entityId: String, temperature: Double) async throws {
        try await callService(
            domain: "climate",
            service: "set_temperature",
            serviceData: [
                "entity_id": entityId,
                "temperature": temperature
            ]
        )
    }
    
    func setHvacMode(_ entityId: String, mode: String) async throws {
        try await callService(
            domain: "climate",
            service: "set_hvac_mode",
            serviceData: [
                "entity_id": entityId,
                "hvac_mode": mode
            ]
        )
    }
    
    // MARK: - Private Methods
    
    private func callService(domain: String, service: String, entityId: String) async throws {
        try await callService(domain: domain, service: service, serviceData: ["entity_id": entityId])
    }
    
    private func callService(domain: String, service: String, serviceData: [String: Any]) async throws {
        guard let config = configuration else {
            throw APIError.noConfiguration
        }
        
        let url = URL(string: "\(config.currentUrl)/api/services/\(domain)/\(service)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let jsonData = try JSONSerialization.data(withJSONObject: serviceData)
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Connection Test
    
    func testConnection() async throws -> Bool {
        guard let config = configuration else {
            throw APIError.noConfiguration
        }
        
        let url = URL(string: "\(config.currentUrl)/api/")!
        var request = URLRequest(url: url)
        
        // Trim token and ensure proper format
        let cleanToken = config.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        print("🔗 Testing connection to: \(config.currentUrl)")
        print("🔑 Token: Bearer \(String(cleanToken.prefix(20)))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 Test response: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            print("❌ 401 Unauthorized")
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ Connected! Message: \(json["message"] ?? "OK")")
            }
        }
        
        return httpResponse.statusCode == 200
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case noConfiguration
    case invalidResponse
    case unauthorized
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noConfiguration:
            return "No configuration set. Please add a configuration first."
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "401 Unauthorized - Invalid API token. Check your token in Home Assistant."
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
