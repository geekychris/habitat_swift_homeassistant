//
//  CustomTab.swift
//  SimpleHomeAssistant
//
//  Model for custom tabs
//

import Foundation

struct CustomTab: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var entityIds: [String]
    var displayOrder: Int
    var configurationId: UUID
}
