//
//  CreateListingViewModel.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//

import Foundation
import Observation
import CoreData

@MainActor
@Observable
class CreateListingViewModel {
    let repository: ListingRepositoryProtocol
    let existingListing: ListingModel?
    let imageStore: ImageStoreProtocol
    let fileManager: FileManager

    var title: String = ""
    var price: String = ""
    var imageData: Data? = nil
    var syncStatus: SyncStatus = .pending

    init(repository: ListingRepositoryProtocol,
         listing: ListingModel? = nil,
         imageStore: ImageStoreProtocol = DefaultImageStore(),
         fileManager: FileManager = .default) {
        self.repository = repository
        self.existingListing = listing
        self.imageStore = imageStore
        self.fileManager = fileManager

        if let listing = listing {
            self.title = listing.title
            self.price = String(format: "%.2f", listing.price)
            self.syncStatus = listing.syncStatusEnum
        }
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(price) != nil &&
        (imageData != nil || existingListing?.imagePath != nil)
    }

    func save() async {
        guard let priceValue = Double(price) else { return }
        await repository.createListing(
            title: title,
            price: priceValue,
            image: imageData ?? Data()
        )
    }

    func update() async {
        guard let listing = existingListing, let priceValue = Double(price) else { return }
        await repository.updateListing(
            listing: listing,
            title: title,
            price: priceValue,
            newImageData: imageData
        )
    }

    func loadImage() async {
        guard let filename = existingListing?.imagePath else { return }
        let fileURL = imageStore.url(for: filename)

        if fileManager.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL) {
                self.imageData = data
            }
        }
    }
}
