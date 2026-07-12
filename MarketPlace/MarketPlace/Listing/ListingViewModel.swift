//
//  ListingModel.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//

import Foundation

@MainActor
@Observable
class ListingViewModel {
    var repository: ListingRepositoryProtocol

    var listings: [ListingModel] = [] 
    var isLoading = false
    var errorMessage: String?

    init(repository: ListingRepositoryProtocol) {
        self.repository = repository
    }

    func loadEvents() async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.seedIfNeeded()
            listings = repository.fetchAllListings()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
