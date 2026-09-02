//
//  MainTabView.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//

import SwiftUI

struct MainTabView: View {
    let persistenceController = PersistenceController.shared

    var body: some View {
        TabView {
            let repository = ListingRepository(
                container: persistenceController.container
            )
            let viewModel = ListingViewModel(repository: repository)


            ListingView(viewModel: viewModel)
                .tabItem {
                    Label("Listings", systemImage: "house")
                }

            let favViewModel = FavoritesViewModel(repository: repository)
            FavoritesView(viewModel: favViewModel)
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }

            ParentDoorConfiguratorView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
