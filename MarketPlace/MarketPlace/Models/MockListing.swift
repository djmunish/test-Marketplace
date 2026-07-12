//
//  MockListing.swift
//  Marketplace
//
//  Created by Munish Sehdev on 2026-07-12
//

import Foundation

struct MockListing: Decodable, Identifiable {
    let id: UUID
    let title: String
    let price: Double
    let updatedAt: Date
    let imagePath: String?
    let syncStatus: String?
}
