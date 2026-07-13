//
//  CreateListingView.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-12.
//

import Foundation
import SwiftUI

struct CreateListingView: View {

    @State private var viewModel: CreateListingViewModel

    @Environment(\.dismiss) var dismiss

    // Image Picker States
    @State private var showImageSourceOptions = false
    @State private var showPicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    init(repository: ListingRepositoryProtocol, listing: ListingModel? = nil) {
        _viewModel = State(
            wrappedValue: CreateListingViewModel(
                repository: repository,
                listing: listing
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECTION 1: Item Details
                Section("Details") {
                    TextField("What are you selling?", text: $viewModel.title)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Price", text: $viewModel.price)
                            .keyboardType(.decimalPad) // Essential for numeric entry
                    }
                }

                // SECTION 2: Image Selection
                Section("Photo") {
                    VStack {
                        if let data = viewModel.imageData, let uiImage = UIImage(data: data) {

                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .clipped()
                                .onTapGesture {
                                    showImageSourceOptions = true
                                }
                        } else {
                            Button {
                                showImageSourceOptions = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.largeTitle)
                                    Text("Add Image")
                                        .font(.headline)
                                }
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .confirmationDialog("Add Photo", isPresented: $showImageSourceOptions) {
                        Button("Camera") { sourceType = .camera; showPicker = true }
                        Button("Photo Library") { sourceType = .photoLibrary; showPicker = true }
                    }
                }
                if viewModel.existingListing != nil {
                    Section("Status") {
                        HStack {
                            Image(systemName: statusIcon)
                                .foregroundColor(statusColor)
                            
                            Text(statusText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()


                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    viewModel.onFavoriteTapped()
                                }
                            } label: {
                                Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(viewModel.isFavorite ? .red : .gray)
                                    .font(.title3)
                                    .contentTransition(.symbolEffect(.replace)) // iOS 17+ morph animation
                            }
                            .buttonStyle(.plain)

//                            if viewModel.isFavorite == true {
//                                Image(systemName: "heart.fill")
//                                    .foregroundColor(.red)
//                            }
                        }
                    }
                }

            }
            .navigationTitle(viewModel.existingListing == nil ? "New Listing" : "Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        Task {
                            if viewModel.existingListing == nil {
                                await viewModel.save()
                            } else {
                                await viewModel.update()
                            }
                            dismiss()
                        }
                    }
                    .bold()
                    .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $showPicker) {
                ImagePicker(sourceType: sourceType, selectedData: $viewModel.imageData)
            }
        }
        .task {   // reruns if path changes
            await viewModel.loadImage()
        }
    }

    private var statusIcon: String {
        switch viewModel.syncStatus {
        case .pending:
            return "icloud.and.arrow.up"
        case .synced:
            return "checkmark.circle"
        case .failed, .syncing:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.syncStatus {
        case .pending:
            return .orange
        case .synced:
            return .green
        case .failed, .syncing:
            return .red
        }
    }

    private var statusText: String {
        switch viewModel.syncStatus {
        case .pending:
            return "Pending Sync"
        case .synced:
            return "Synced"
        case .failed, .syncing:
            return "Sync Failed"
        }
    }
}
