//
//  ListingModel.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//

import Foundation

@MainActor
@Observable
class ListingViewModel {

    var listings: [ListingModel] = [] 
    var isLoading = false

}
