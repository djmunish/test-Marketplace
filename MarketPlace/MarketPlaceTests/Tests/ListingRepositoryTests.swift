//
//  MarketplaceTests.swift
//  MarketplaceTests
//
//  Created by Munish Sehdev on 2026-04-26.
//

import XCTest
@testable import MarketPlace
internal import CoreData

final class ListingRepositoryTests: XCTestCase {
    var sut: ListingRepository!
    var container: NSPersistentContainer!

    override func setUp() {
        super.setUp()
        container = TestCoreDataStack.container()
        sut = ListingRepository(container: container)
    }

    override func tearDown() {
        sut = nil
        container = nil
    }

    func test_updateListing_updatesFieldsCorrectly() async throws {
        let context = container.viewContext

        // Arrange: create Core Data entity
        let entity = Listing(context: context)
        let id = UUID()
        entity.id = id
        entity.title = "Old"
        entity.price = 10
        entity.syncStatusEnum = .synced

        try context.save()

        // Convert to model
        let model = ListingModel(
            id: id,
            title: "Old",
            price: 10,
            imagePath: nil,
            updatedAt: nil,
            syncStatusEnum: .synced,
            isFavorite: false
        )

        // Act
        await sut.updateListing(
            listing: model,   // ✅ pass model, not entity
            title: "New Title",
            price: 99,
            newImageData: nil
        )

        // Assert
        let fetch: NSFetchRequest<Listing> = Listing.fetchRequest()
        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetch.fetchLimit = 1

        let fetched = try context.fetch(fetch).first!

        XCTAssertEqual(fetched.title, "New Title")
        XCTAssertEqual(fetched.price, 99)
        XCTAssertEqual(fetched.syncStatusEnum, .pending) // important
    }

    func test_updateListing_setsPendingWhenDataChanges() async throws {

        let context = container.viewContext

        let listing = Listing(context: context)
        let id = UUID()
        listing.id = id
        listing.syncStatusEnum = .synced
        listing.imagePath = "old.jpg"

        try context.save()

        // Convert to model
        let model = ListingModel(
            id: id,
            title: "Old",
            price: 10,
            imagePath: nil,
            updatedAt: nil,
            syncStatusEnum: .synced,
            isFavorite: false
        )


        await sut.updateListing(
            listing: model,
            title: "New",
            price: 50,
            newImageData: Data()
        )

        let updated = try context.existingObject(with: listing.objectID) as! Listing

        XCTAssertEqual(updated.title, "New")
        XCTAssertEqual(updated.price, 50)
        XCTAssertEqual(updated.syncStatusEnum, .pending)
    }


    func test_sync_onlyProcessesPendingItems() async throws {

        let context = container.viewContext

        let synced = Listing(context: context)
        synced.syncStatusEnum = .synced

        let pending = Listing(context: context)
        pending.syncStatusEnum = .pending

        try context.save()

        await sut.uploadPendingListings()

        let syncedAfter = try context.existingObject(with: synced.objectID) as! Listing
        let pendingAfter = try context.existingObject(with: pending.objectID) as! Listing

        XCTAssertEqual(syncedAfter.syncStatusEnum, .synced)
        XCTAssertEqual(pendingAfter.syncStatusEnum, .synced) // got uploaded
    }
}
