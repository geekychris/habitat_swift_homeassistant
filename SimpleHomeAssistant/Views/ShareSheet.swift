//
//  ShareSheet.swift
//  SimpleHomeAssistant
//
//  iOS Share Sheet wrapper
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// Make URL Identifiable for sheet presentation
extension URL: Identifiable {
    public var id: String {
        absoluteString
    }
}
