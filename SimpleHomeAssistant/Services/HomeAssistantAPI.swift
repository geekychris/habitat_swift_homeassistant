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
        
        let url = URL(string: "\(config.currentConnectionUrl)/api/states")!
        var request = URLRequest(url: url)
        
        // Get authorization header with correct token
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("🔗 Fetching entities from: \(config.currentConnectionUrl)")
        print("🔑 Auth method: \(config.authentication.method)")
        if let currentUrl = config.currentURL {
            print("🔑 Using URL: \(currentUrl.name)")
        }
        for url in config.urls {
            print("📍 \(url.name): \(url.url)")
        }
        print("🎯 Currently active: \(config.currentConnectionUrl)")
        
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
        
        let url = URL(string: "\(config.currentConnectionUrl)/api/services/\(domain)/\(service)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Get authorization header with correct token
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("🎬 Calling service \(domain).\(service) via: \(config.currentConnectionUrl)")
        if let currentUrl = config.currentURL {
            print("🔑 Using URL: \(currentUrl.name)")
        }
        
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
        
        let url = URL(string: "\(config.currentConnectionUrl)/api/")!
        var request = URLRequest(url: url)
        
        // Get authorization header with correct token
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        print("🔗 Testing connection to: \(config.currentConnectionUrl)")
        print("🔑 Auth method: \(config.authentication.method)")
        if let currentUrl = config.currentURL {
            print("🔑 Using URL: \(currentUrl.name)")
        }
        
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
    
    // MARK: - History API
    
    /// Fetch history for all entities within a time period
    func fetchHistory(startTime: Date, endTime: Date? = nil) async throws -> [String: [HistoryState]] {
        guard let config = configuration else {
            throw APIError.noConfiguration
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startTimeString = dateFormatter.string(from: startTime)
        
        var urlString = "\(config.currentConnectionUrl)/api/history/period/\(startTimeString)"
        if let endTime = endTime {
            let endTimeString = dateFormatter.string(from: endTime)
            urlString += "?end_time=\(endTimeString)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("📜 Fetching history from: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // History API returns array of arrays, grouped by entity
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let historyGroups = try decoder.decode([[HistoryState]].self, from: data)
        
        // Convert to dictionary keyed by entity_id
        var result: [String: [HistoryState]] = [:]
        for group in historyGroups {
            if let firstState = group.first {
                result[firstState.entityId] = group
            }
        }
        
        return result
    }
    
    // MARK: - Logbook API
    
    /// Fetch logbook entries (system events, automations, etc.)
    func fetchLogbook(startTime: Date, endTime: Date? = nil) async throws -> [LogbookEntry] {
        guard let config = configuration else {
            throw APIError.noConfiguration
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startTimeString = dateFormatter.string(from: startTime)
        
        var urlString = "\(config.currentConnectionUrl)/api/logbook/\(startTimeString)"
        if let endTime = endTime {
            let endTimeString = dateFormatter.string(from: endTime)
            urlString += "?end_time=\(endTimeString)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        let authHeader = try getAuthorizationHeader()
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        print("📔 Fetching logbook from: \(urlString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds first
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }
        
        let logbookEntries = try decoder.decode([LogbookEntry].self, from: data)
        return logbookEntries
    }
}

// MARK: - History Models

struct HistoryState: Codable, Identifiable {
    var id: String { "\(entityId)_\(lastChanged.timeIntervalSince1970)" }
    let entityId: String
    let state: String
    let lastChanged: Date
    let lastUpdated: Date
    let attributes: [String: AnyCodable]?
    
    enum CodingKeys: String, CodingKey {
        case entityId = "entity_id"
        case state
        case lastChanged = "last_changed"
        case lastUpdated = "last_updated"
        case attributes
    }
}

// MARK: - Logbook Models

struct LogbookEntry: Codable, Identifiable {
    var id: String { "\(when.timeIntervalSince1970)_\(name)" }
    let name: String
    let message: String?
    let domain: String?
    let entityId: String?
    let when: Date
    
    enum CodingKeys: String, CodingKey {
        case name
        case message
        case domain
        case entityId = "entity_id"
        case when
    }
}

// Helper for decoding arbitrary JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case noConfiguration
    case invalidResponse
    case unauthorized
    case missingCredentials
    case invalidURL
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noConfiguration:
            return "No configuration set. Please add a configuration first."
        case .invalidURL:
            return "Invalid URL format."
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
