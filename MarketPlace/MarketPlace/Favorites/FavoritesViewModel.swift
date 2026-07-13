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

    private let repository: ListingRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: ListingRepositoryProtocol) {
        self.repository = repository
        setupFavoritesSubscription()
    }

    func fetchFavorites() {
        favoriteListings = repository.fetchFavoriteListings()
    }

    /// Listens to the repository's real-time stream and updates the filtered favorites array
    private func setupFavoritesSubscription() {
        repository.listingsPublisher
            // Receive the update on the Main thread since it drives the UI
            .receive(on: DispatchQueue.main)
            // Filter the full array down to only items where isFavorite is true
            .map { listings in
                listings.filter { $0.isFavorite }
            }
            // Assign the filtered results directly to our @Published property
            .assign(to: \.favoriteListings, on: self)
            .store(in: &cancellables)
    }

    /// Allow users to unfavorite directly from the favorites screen
    func toggleFavorite(for item: ListingModel) {
        repository.toggleFavorite(item: item)
    }
}
