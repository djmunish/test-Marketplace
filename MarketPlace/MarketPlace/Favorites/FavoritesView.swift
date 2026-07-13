//
//  FavoritesDemoView.swift
//  Marketplace-Test
//
//  Created by Munish Sehdev on 2026-07-12.
//

import SwiftUI

struct FavoritesView: View {
    @State var viewModel: FavoritesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.favoriteListings.isEmpty {
                    ProgressView("Loading Marketplace...")
                } else if viewModel.favoriteListings.isEmpty {
                    ContentUnavailableView(
                        "No Listings",
                        systemImage: "heart",
                        description: Text("Try adding something new to favorites.")
                    )
                } else {
                    List(viewModel.favoriteListings, id: \.id) { item in
                        ListingRow(listing: item, onFavoriteTapped: {
                            viewModel.toggleFavorite(for: item)
                        }, hideSyncIndicator: true)
                        .contentShape(Rectangle())
                    }
                }
            }
            .navigationTitle("Favourites")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.fetchFavorites()
            }
        }
    }
}
