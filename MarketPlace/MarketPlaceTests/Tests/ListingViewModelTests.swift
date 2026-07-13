//
//  ListingViewModelTests.swift
//  MarketplaceTests
//
//  Created by Munish Sehdev on 2026-04-27.
//

import XCTest
@testable import MarketPlace
internal import CoreData

@MainActor
final class ListingViewModelTests: XCTestCase {

    func test_loadEvents_success_updatesListings() async {

        let mock = MockRepository()

        let model = ListingModel(
            id: UUID(),
            title: "Chair",
            price: 10.0,
            imagePath: nil,
            updatedAt: Date(),
            syncStatusEnum: .synced,
            isFavorite: false
        )

        mock.listings = [model]

        let vm = ListingViewModel(repository: mock)

        await vm.loadEvents()

        XCTAssertEqual(vm.listings.count, 1)
        XCTAssertEqual(vm.listings.first?.title, "Chair")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertTrue(mock.seedCalled)
    }

    func test_sync_callsRepository() async {

        let mock = MockRepository()
        let vm = ListingViewModel(repository: mock)

        await vm.sync()

        XCTAssertTrue(mock.uploadCalled)
    }

    func test_loadEvents_emptyListings() async {

        let mock = MockRepository()
        mock.listings = []

        let vm = ListingViewModel(repository: mock)

        await vm.loadEvents()

        XCTAssertEqual(vm.listings.count, 0)
    }

    func test_load_overwritesOldData() async {
        let mock = MockRepository()
        mock.listings = [ListingModel(
            id: UUID(),
            title: "Chair",
            price: 10.0,
            imagePath: nil,
            updatedAt: Date(),
            syncStatusEnum: .synced,
            isFavorite: false
        ), ListingModel(
            id: UUID(),
            title: "Chair2",
            price: 10.0,
            imagePath: nil,
            updatedAt: Date(),
            syncStatusEnum: .synced,
            isFavorite: false
        )]

        let vm = ListingViewModel(repository: mock)

        await vm.loadEvents()

        XCTAssertEqual(vm.listings.count, 2)
    }

    func test_multipleLoads_doNotCrash() async {
        let mock = MockRepository()

        let vm = ListingViewModel(repository: mock)

        async let load1 = vm.loadEvents()
        async let load2 = vm.loadEvents()

        _ = await (load1, load2)

        XCTAssertTrue(true) // no crash = pass
    }
    
}
