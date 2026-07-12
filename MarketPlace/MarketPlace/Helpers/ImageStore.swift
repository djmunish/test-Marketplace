//
//  ImageStore.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//


import Foundation
import UIKit


protocol ImageStoreProtocol {
    func url(for filename: String) -> URL
}

final class DefaultImageStore: ImageStoreProtocol {
    func url(for filename: String) -> URL {
        ImageStore.getURLForFilename(filename)
    }
}


struct ImageStore {
    /// Saves image data to the Documents directory and returns the absolute string of the file URL.
    /// - Parameters:
    ///   - data: The image data to save.
    ///   - name: A unique identifier for the file (e.g., the Listing ID).
    /// - Returns: The absolute string of the file URL if successful, otherwise nil.
    static func saveImageToDisk(data: Data, fileName: String) throws {
        let fileManager = FileManager.default

        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesFolder = documentsURL.appendingPathComponent("ListingImages", isDirectory: true)

        // Create folder if needed
        if !fileManager.fileExists(atPath: imagesFolder.path) {
            try fileManager.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        }

        let fileURL = imagesFolder.appendingPathComponent(fileName)
        try data.write(to: fileURL)
    }

    static func processImagesInBackground(_ items: [MockListing]) async -> [UUID: String] {
        var results: [UUID: String] = [:]

        await withTaskGroup(of: (UUID, String?).self) { group in
            for item in items {
                guard let path = item.imagePath else { continue }

                group.addTask {
                    let filename = await handleImage(for: item.id, path: path)
                    return (item.id, filename)
                }
            }

            for await (id, filename) in group {
                if let filename {
                    results[id] = filename
                }
            }
        }

        return results
    }

    
    static func handleImage(for id: UUID, path: String) async -> String? {
        do {
            let fileName = "\(id).jpg"

            // Skip if already cached
            let localURL = ImageStore.getURLForFilename(fileName)
            if FileManager.default.fileExists(atPath: localURL.path) {
                return fileName
            }

            var imageData: Data?

            // Remote image
            if let url = URL(string: path),
               let scheme = url.scheme, scheme.starts(with: "http") {
                let (data, _) = try await URLSession.shared.data(from: url)
                imageData = data
            }
            // Local bundled image
            else if let image = UIImage(named: path) {
                imageData = image.jpegData(compressionQuality: 0.8)
            }

            guard let data = imageData else { return nil }

            try saveImageToDisk(data: data, fileName: fileName)
            return fileName
        } catch {
            print("Image processing failed for \(id): \(error)")
            return nil
        }
    }

    static func getURLForFilename(_ filename: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let imagesFolder = documentsDirectory.appendingPathComponent("ListingImages", isDirectory: true)

        return imagesFolder.appendingPathComponent(filename)
    }
}
