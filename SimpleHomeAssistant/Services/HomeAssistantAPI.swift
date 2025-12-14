//
//  HomeAssistantAPI.swift
//  SimpleHomeAssistant
//
//  Home Assistant REST API service
//

import Foundation

class HomeAssistantAPI {
    private var configuration: HAConfiguration?
    private var authToken: String?
    
    func setConfiguration(_ config: HAConfiguration) {
        self.configuration = config
        // Clear cached token when config changes
        self.authToken = nil
    }
    
    // MARK: - Authentication
    
    /// Get the appropriate token for the current URL
    private func getCurrentToken() throws -> String {
        guard let config = configuration else {
            throw APIError.noConfiguration
        }
        
        guard let token = config.currentToken, !token.isEmpty else {
            throw APIError.missingCredentials
        }
        
        return token
    }
    
    /// Get authorization header value
    private func getAuthorizationHeader() throws -> String {
        let token = try getCurrentToken()
        return "Bearer \(token)"
    }
    
    // MARK: - Fetch Entities
    
    func fetchAllEntities() async throws -> [HAEntity] {
        guard let config = configuration else {
            throw APIError.noConfiguration
        }
        
        let url = URL(string: "\(config.currentUrl)/api/states")!
        var request = URLRequest(url: url)
        
        // Get authorization header with correct token
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("🔗 Fetching entities from: \(config.currentUrl)")
        print("🔑 Auth type: \(config.authType)")
        print("🔑 Using \(config.useInternalUrl ? "internal" : "external") URL")
        print("📍 Internal URL: \(config.internalUrl)")
        print("📍 External URL: \(config.externalUrl)")
        print("🎯 Actually using: \(config.currentUrl)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                print("❌ 401 Unauthorized - Check your token for \(config.useInternalUrl ? "internal" : "external") URL")
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
        
        // Get authorization header with correct token
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("🎬 Calling service \(domain).\(service) via: \(config.currentUrl)")
        print("🔑 Using \(config.useInternalUrl ? "internal" : "external") URL")
        
        let jsonData = try JSONSerialization.data(withJSONObject: serviceData)
        request.httpBody = jsonData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                print("❌ 401 Unauthorized on service call")
            }
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
        
        // Get authorization header with correct token
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        print("🔗 Testing connection to: \(config.currentUrl)")
        print("🔑 Auth type: \(config.authType)")
        print("🔑 Using \(config.useInternalUrl ? "internal" : "external") URL")
        
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
    case missingCredentials
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noConfiguration:
            return "No configuration set. Please add a configuration first."
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "401 Unauthorized - Invalid token. Please re-authenticate or check your token."
        case .missingCredentials:
            return "Missing authentication token. Please configure authentication."
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}
