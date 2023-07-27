//
//  MIlageTrackerApp.swift
//  MIlageTracker
//
//  Created by Nikhil Krishnaswamy on 6/29/23.
//

import SwiftUI

@main
struct MIlageTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
