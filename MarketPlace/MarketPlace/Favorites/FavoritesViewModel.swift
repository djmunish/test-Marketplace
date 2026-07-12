//
//  FavoritesViewModel.swift
//  Marketplace-Test
//
//  Created by Munish Sehdev on 2026-07-12.
//


import Foundation
import Combine

@Observable
class FavoritesViewModel: ObservableObject {
    var favoriteListings: [ListingModel] = []
    var isLoading = false
}
