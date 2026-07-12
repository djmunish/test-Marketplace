//
//  ListingModel.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//

import Foundation
import Combine

@MainActor
@Observable
class ListingViewModel {
    var repository: ListingRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    var listings: [ListingModel] = [] 
    var isLoading = false
    var errorMessage: String?

    init(repository: ListingRepositoryProtocol) {
        self.repository = repository
        bind()
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
    
    func sync() async {
        await repository.uploadPendingListings()
        listings = repository.fetchAllListings()
    }

    private func bind() {
        repository.listingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.listings = items
            }
            .store(in: &cancellables)
    }
}
