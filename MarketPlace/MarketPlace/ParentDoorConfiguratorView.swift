//
//  ParentDoorConfiguratorView.swift
//  MarketPlace
//
//  Created by Munish Sehdev on 2026-07-13.
//


import SwiftUI

// 1. The Source of Truth (Parent View)
struct ParentDoorConfiguratorView: View {
    // This is the single source of truth for the door's width
    @State private var doorWidth: Double = 36.0

    var body: some View {
        VStack(spacing: 30) {
            Text("Parent View - Live Width: \(Int(doorWidth)) inches")
                .font(.headline)
            
            Divider()
            
            // Passing the binding down to Child 1 using '$'
            WidthSliderChildView(width: $doorWidth)
            
            Divider()
            
            // Passing the exact same binding down to Child 2
            WidthPresetChildView(width: $doorWidth)
        }
        .padding()
    }
}

// 2. Child View 1: Modifies the value via a Slider
struct WidthSliderChildView: View {
    @Binding var width: Double // Receives the binding

    var body: some View {
        VStack(alignment: .leading) {
            Text("Child 1: Fine Tuning")
                .foregroundColor(.secondary)
            Slider(value: $width, in: 30...42, step: 2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// 3. Child View 2: Modifies the value via Quick Buttons
struct WidthPresetChildView: View {
    @Binding var width: Double // Receives the same binding

    var body: some View {
        VStack(alignment: .leading) {
            Text("Child 2: Quick Presets")
                .foregroundColor(.secondary)
            
            HStack {
                Button("Narrow (32\")") { width = 32 }
                Spacer()
                Button("Standard (36\")") { width = 36 }
                Spacer()
                Button("Wide (42\")") { width = 42 }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}



protocol APIProtocol {
    func getOrderHistory() -> [Order]
    func getOrderDetails(orderID: String) -> OrderDetail
}

struct Order {
    let id: String
}

struct OrderDetail {
    let amount: Double
}

