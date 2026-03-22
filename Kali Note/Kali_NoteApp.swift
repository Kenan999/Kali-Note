//
//  Kali_NoteApp.swift
//  Kali Note
//
//  Created by Kenan Ali on 20.03.26.
//

import SwiftUI
import SwiftData

@main
struct Kali_NoteApp: App {
    init() {
        // Silence internal UIKit Autolayout warnings caused by system bugs in iOS 17/18 keyboard layout
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        // NUCLEAR OPTION: Silence ALL OS activity logs (Client not entitled, XPC Invalidation, etc.)
        setenv("OS_ACTIVITY_MODE", "disable", 1)

        print("📍 SwiftData Database Path: \(URL.applicationSupportDirectory.path(percentEncoded: false))")
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            User.self,
            AuthMethod.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
