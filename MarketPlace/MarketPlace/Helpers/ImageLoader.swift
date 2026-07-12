//
//  ImageLoader.swift
//  Marketplace-Test
//
//  Created by Munish Sehdev on 2026-07-12.
//

import SwiftUI
import Combine

@MainActor
@Observable
class ImageLoader {
    var image: UIImage?
    var isLoading = false

    private let url: URL
    private static let cache = NSCache<NSURL, UIImage>()

    init(url: URL) {
        self.url = url
    }

    func load() async {
        if let cached = Self.cache.object(forKey: url as NSURL) {
            self.image = cached
            return
        }

        isLoading = true

        if url.isFileURL {
            await loadLocalImage()
        } else {
            await downloadRemoteImage()
        }
    }

    @MainActor // Ensures the function itself is bound to the MainActor
    private func loadLocalImage() async {
        self.isLoading = true

        // 1. Run the heavy disk I/O off the MainActor
        let result = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let data = try? Data(contentsOf: self.url) else { return nil }
            return UIImage(data: data)
        }.value

        // 2. Automatically back on the MainActor here
        self.isLoading = false

        guard let loadedImage = result else { return }

        // Completely safe to access 'Self.cache' here now
        Self.cache.setObject(loadedImage, forKey: self.url as NSURL)
        self.image = loadedImage
    }

//    private func loadLocalImage() {
//        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
//            guard let self = self else { return }
//            
//            if let data = try? Data(contentsOf: self.url),
//               let loadedImage = UIImage(data: data) {
//
//                Self.cache.setObject(loadedImage, forKey: self.url as NSURL)
//
//                DispatchQueue.main.async {
//                    self.image = loadedImage
//                    self.isLoading = false
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.isLoading = false
//                }
//            }
//        }
//    }

    private func downloadRemoteImage() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                Self.cache.setObject(downloadedImage, forKey: url as NSURL)
                self.image = downloadedImage
                self.isLoading = false
            }
        } catch {
            self.isLoading = false
        }
    }
}
