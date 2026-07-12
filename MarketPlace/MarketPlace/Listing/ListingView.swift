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
                }
            }
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
