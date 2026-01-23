//
//  WordTrainerApp.swift
//  WordTrainer
//
//  Created by Cyril Wendl on 23.01.2026.
//

import SwiftUI
import SwiftData

@main
struct WordTrainerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Word.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
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
