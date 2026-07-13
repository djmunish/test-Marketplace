//
//  CreateListingViewModelTests.swift
//  Marketplace
//
//  Created by Munish Sehdev on 2026-04-27.
//


import XCTest
@testable import MarketPlace

final class CreateListingViewModelTests: XCTestCase {

//    func test_init_withExistingListing_populatesFields() {
//        let repo = MockRepository()
//
//        let model = ListingModel(
//            id: UUID(),
//            title: "Chair",
//            price: 20,
//            imagePath: "img.jpg",
//            updatedAt: nil,
//            syncStatusEnum: .synced
//        )
//
//        let vm = CreateListingViewModel(repository: repo, listing: model)
//
//        XCTAssertEqual(vm.title, "Chair")
//        XCTAssertEqual(vm.price, "20.00")
//        XCTAssertEqual(vm.syncStatus, .synced)
//    }

//    @MainActor
//    func test_isValid_withInvalidPrice_returnsFalse() {
//        let repo = MockRepository()
//        let vm = CreateListingViewModel(repository: repo)
//
//        vm.title = "Item"
//        vm.price = "abc"
//        vm.imageData = Data()
//        print(vm.isValid)
//        XCTAssertFalse(vm.isValid)
//    }

    @MainActor
    func test_save_callsRepository() async {
        let repo = MockRepository()
        let vm = CreateListingViewModel(repository: repo)

        vm.title = "Laptop"
        vm.price = "999.99"
        vm.imageData = Data([1,2,3])

        await vm.save()

        XCTAssertEqual(repo.createdListing?.title, "Laptop")
        XCTAssertEqual(repo.createdListing?.price, 999.99)
        XCTAssertEqual(repo.createdListing?.image, Data([1,2,3]))
    }

    @MainActor
    func test_update_callsRepository() async {
        let repo = MockRepository()

        let model = ListingModel(
            id: UUID(),
            title: "Old",
            price: 10,
            imagePath: nil,
            updatedAt: nil,
            syncStatusEnum: .synced,
            isFavorite: false
        )

        let vm = CreateListingViewModel(repository: repo, listing: model)

        vm.title = "New"
        vm.price = "99"
        vm.imageData = Data([9,9])

        await vm.update()

        XCTAssertTrue(repo.updatedCalled)
        XCTAssertEqual(repo.updatedListing?.title, "New")
        XCTAssertEqual(repo.updatedListing?.price, 99)
        XCTAssertEqual(repo.updatedListing?.image, Data([9,9]))
    }

    @MainActor
    func test_loadImage_setsImageData_whenFileExists() async {
        let repo = MockRepository()
        let mockStore = MockImageStore()
        let fileManager = FileManager.default

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.img")
        let expectedData = Data([1,2,3])
        try? expectedData.write(to: tempURL)

        mockStore.urlToReturn = tempURL

        let listing = ListingModel(id: UUID(), title: "", price: 4.0, imagePath: "test.img", updatedAt: nil, syncStatusEnum: .pending,
                                   isFavorite: false)

        let vm = CreateListingViewModel(
            repository: repo,
            listing: listing,
            imageStore: mockStore,
            fileManager: fileManager
        )

        await vm.loadImage()

        XCTAssertEqual(vm.imageData, expectedData)
    }

//    @MainActor
//    func test_statusText_pending() {
//        let repo = MockRepository()
//
//        let listing = ListingModel(id: UUID(), title: "", price: 4.0, imagePath: "test.img", updatedAt: nil, syncStatusEnum: .pending)
//        let vm = CreateListingViewModel(repository: repo, listing: listing)
//        vm.syncStatus = .pending
//
//        XCTAssertEqual(vm.statusText, "Pending Sync")
//    }

    @MainActor
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
}
