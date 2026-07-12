//
//  SyncStatus.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//


import Foundation

enum SyncStatus: String {
    case synced
    case syncing
    case pending
    case failed
}

extension Listing {
    var syncStatusEnum: SyncStatus {
        get {
            SyncStatus(rawValue: syncStatus ?? "") ?? .pending
        }
        set {
            syncStatus = newValue.rawValue
        }
    }
}