//
//  ListingView.swift
//  Marketplace-Test
//
//  Created by Munish Sehdev on 2026-07-12.
//

import SwiftUI

enum ListingSheet: Identifiable {
    case create
    case edit(ListingModel)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let listing):
            return listing.id.uuidString
        }
    }
}

struct ListingView: View {
     @State var viewModel: ListingViewModel

    // We only need one piece of state to manage the sheet
    // If selectedListing is nil, we are "Creating". 
    // If it has a value, we are "Editing".
    @State private var activeSheet: ListingSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.listings.isEmpty {
                    ProgressView("Loading Marketplace...")
                } else if viewModel.listings.isEmpty {
                    ContentUnavailableView(
                        "No Listings",
                        systemImage: "bag",
                        description: Text("Try adding something new or check your listings.json file.")
                    )
                } else {
                    List(viewModel.listings, id: \.id) { item in
                        ListingRow(listing: item, onFavoriteTapped: {
                            viewModel.toggleFavorite(item: item)
                        }, hideSyncIndicator: false)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                activeSheet = .edit(item)
                            }
                    }
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel.listings.isEmpty {
                    Task{
                        await viewModel.loadEvents()
                    }
                }
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        activeSheet = .create
                    }) {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task{
                            await viewModel.sync()
                        }
                    }) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90.circle")
                            .font(.headline)
                    }
                }
            }.sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .create:
                    CreateListingView(
                        repository: viewModel.repository,
                        listing: nil
                    )
                case .edit(let listing):
                    CreateListingView(
                        repository: viewModel.repository,
                        listing: listing
                    )
                }
            }
        }
    }
}
