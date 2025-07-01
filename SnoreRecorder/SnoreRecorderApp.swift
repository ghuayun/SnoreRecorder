//
//  SnoreRecorderApp.swift
//  SnoreRecorder
//
//  Created on 2025-06-30.
//  iOS Snore Recording App with Local LLM Analysis
//

import SwiftUI
import CoreData

@main
struct SnoreRecorderApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Request microphone permission on app launch
                    AudioPermissionManager.shared.requestMicrophonePermission()
                }
        }
    }
}
