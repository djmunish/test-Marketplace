//
//  CachedImageView.swift
//  Marketplace-Test
//
//  Created by Munish Sehdev on 2026-07-12.
//

import SwiftUI

struct CachedImageView: View {
    @State private var loader: ImageLoader

    init(url: URL) {
        _loader = State(wrappedValue: ImageLoader(url: url))
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else if loader.isLoading {
                ProgressView()
            } else {
                placeholder
            }
        }
        .task {
            await loader.load()
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: "photo")
                .foregroundColor(.gray)
        }
    }
}
