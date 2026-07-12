//
//  MarketPlaceApp.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//

import SwiftUI
import CoreData

@main
struct MarketPlaceApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
