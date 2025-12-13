//
//  SimpleHomeAssistantApp.swift
//  SimpleHomeAssistant
//
//  iOS version of Simple Home Assistant
//  Mirrors Android app functionality
//

import SwiftUI
import CoreData

@main
struct SimpleHomeAssistantApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
