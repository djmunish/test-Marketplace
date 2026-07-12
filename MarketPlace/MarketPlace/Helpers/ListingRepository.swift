//
//  ListingRepositoryProtocol.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//


import Foundation
import CoreData
import Combine


protocol ListingRepositoryProtocol {
    var listingsPublisher: AnyPublisher<[ListingModel], Never> { get }
    func fetchAllListings() -> [ListingModel]
    func isDatabaseEmpty() throws -> Bool
    func seedIfNeeded() async throws
    func seedDatabaseFromJson() async throws
    func createListing(title: String, price: Double, image: Data) async
    func updateListing(listing: ListingModel, title: String, price: Double, newImageData: Data?) async
    func uploadPendingListings() async
}

class ListingRepository: ObservableObject, ListingRepositoryProtocol {
    // 🔥 Combine stream of listings
    private let listingsSubject = CurrentValueSubject<[ListingModel], Never>([])
    var listingsPublisher: AnyPublisher<[ListingModel], Never> {
        listingsSubject.eraseToAnyPublisher()
    }

    let container: NSPersistentContainer
    let context: NSManagedObjectContext // Changed to internal so VM can access or use for fetches

    init(container: NSPersistentContainer)  {
        self.container = container
        context = container.viewContext
    }

    // MARK: - Fetching
    func fetchAllListings() -> [ListingModel] {
        let request: NSFetchRequest<Listing> = Listing.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Listing.updatedAt, ascending: true)
        ]

        do {
            let results = try context.fetch(request)

            return results.map { entity in
                ListingModel(
                    id: entity.id ?? UUID(),
                    title: entity.title ?? "",
                    price: entity.price,
                    imagePath: entity.imagePath,
                    updatedAt: entity.updatedAt,
                    syncStatusEnum: entity.syncStatusEnum,
                    isFavorite: entity.isFavorite
                )
            }

        } catch {
            print("❌ Fetch failed: \(error)")
            return []
        }
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ Failed to save image:", error)
        }
    }

    func isDatabaseEmpty() throws -> Bool {
        let request: NSFetchRequest<Listing> = Listing.fetchRequest()
        request.fetchLimit = 1
        let count = try context.count(for: request)
        return count == 0
    }

    // Changed to async to allow awaiting seeding completion
    func seedIfNeeded() async throws {
        do {
            if try isDatabaseEmpty() {
                print("🌱 Seeding database...")
                try await seedDatabaseFromJson()
            } else {
                print("✅ Database already seeded. Skipping.")
            }
        } catch {
            print("❌ Failed to check DB: \(error)")
        }
    }

    func seedDatabaseFromJson() async throws {
        guard let url = Bundle.main.url(forResource: "listings", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { 
            print("⚠️ listings.json not found in bundle")
            return 
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        do {
            let mockItems = try decoder.decode([MockListing].self, from: data)
            for item in mockItems {
                let newListing = Listing(context: context)
                newListing.id = item.id
                newListing.title = item.title
                newListing.imagePath = item.imagePath
                newListing.price = item.price
                newListing.updatedAt = item.updatedAt
                newListing.syncStatusEnum = .synced
            }

            saveContext()
            print("Successfully seeded \(mockItems.count) items.")

            // Image processing stays backgrounded
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                let results = await ImageStore.processImagesInBackground(mockItems)
                await MainActor.run {
                    for (id, filename) in results {
                        let fetch: NSFetchRequest<Listing> = Listing.fetchRequest()
                        fetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                        if let listing = try? self.context.fetch(fetch).first {
                            listing.imagePath = filename
                        }
                    }
                    self.saveContext()
                    self.refreshListings()
                }
            }
        } catch {
            print("Seeding failed: \(error)")
        }
    }

    // MARK: - Create Listing (Offline First)
    func createListing(title: String, price: Double, image: Data) async {
        await context.perform {
            let newListing = Listing(context: self.context)

            let id = UUID()
            newListing.id = id
            newListing.title = title
            newListing.price = price
            newListing.updatedAt = Date()
            newListing.syncStatusEnum = .pending

            let filename = id.uuidString + ".jpg"
            newListing.imagePath = filename

            do {
                try ImageStore.saveImageToDisk(data: image, fileName: filename)
            } catch {
                print("❌ Failed to save image:", error)
            }

            self.saveContext()
            self.refreshListings()
        }
    }

    func updateListing(listing: ListingModel, title: String, price: Double, newImageData: Data?) async {

        await context.perform {

            let request: NSFetchRequest<Listing> = Listing.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", listing.id as CVarArg)
            request.fetchLimit = 1

            guard let listingToUpdate = try? self.context.fetch(request).first
            else {
                print("❌ Failed to find listing for update")
                return
            }

            listingToUpdate.title = title
            listingToUpdate.price = price
            listingToUpdate.updatedAt = Date()
            listingToUpdate.syncStatusEnum = .pending

            if let newData = newImageData {
                if let filename = listingToUpdate.imagePath {
                    let oldPath = ImageStore.getURLForFilename(filename)
                    try? FileManager.default.removeItem(at: oldPath)
                }

                let filename = UUID().uuidString + ".jpg"
                do {
                    try ImageStore.saveImageToDisk(data: newData, fileName: filename)
                    listingToUpdate.imagePath = filename
                } catch {
                    print("❌ Failed to save image:", error)
                }
            }

            self.saveContext()
            self.refreshListings()
        }
    }

    func uploadPendingListings() async {
        let context = self.context

        await context.perform {
            let request: NSFetchRequest<Listing> = Listing.fetchRequest()
            request.predicate = NSPredicate(format: "syncStatus == %@", SyncStatus.pending.rawValue)
            guard let results = try? context.fetch(request) else { return }

            for listing in results {
                // Simulate API upload
                print("Uploading:", listing.title ?? "")

                listing.syncStatusEnum = .synced
            }

            self.saveContext()
            self.refreshListings()
        }
    }


    private func refreshListings() {
        let request: NSFetchRequest<Listing> = Listing.fetchRequest()

        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Listing.updatedAt, ascending: true)
        ]

        do {
            let results = try context.fetch(request)

            let mapped = results.map {
                ListingModel(
                    id: $0.id ?? UUID(),
                    title: $0.title ?? "",
                    price: $0.price,
                    imagePath: $0.imagePath,
                    updatedAt: $0.updatedAt,
                    syncStatusEnum: $0.syncStatusEnum,
                    isFavorite: $0.isFavorite
                )
            }

            listingsSubject.send(mapped)

        } catch {
            print("❌ Fetch failed:", error)
        }
    }
}
