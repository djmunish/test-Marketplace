//
//  ListingModel.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12
//

import Foundation

struct ListingModel {
    let id: UUID
    let title: String
    let price: Double
    let imagePath: String?
    let updatedAt: Date?
    let syncStatusEnum: SyncStatus
    var isFavorite: Bool
}
