// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI

extension Color {
    // Some unique colors to make the app more warm and delightful :)
    static let timelinePrimary = Color(red: 0.0, green: 0.6, blue: 0.5) // Teal green
    static let timelineSecondary = Color(red: 0.9, green: 0.4, blue: 0.0) // Orange
    static let timelineAccent1 = Color(red: 0.8, green: 0.2, blue: 0.1) // Red/rust
    static let timelineAccent2 = Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
    static let timelineOutline = Color.black
    
    // Background colors
    static let timelineBackground = Color(red: 0.98, green: 0.96, blue: 0.9) // Cream background
    static let timelineGroupedBackground = Color(red: 0.98, green: 0.96, blue: 0.9).opacity(0.8)
    static let timelineSecondaryBackground = Color.white
    
    // Card colors
    static let timelineCardBackground = Color.white
    static let timelineCardShadow = Color.black.opacity(0.1)
    
    // Text colors
    static let timelinePrimaryText = Color.black
    static let timelineSecondaryText = Color.black.opacity(0.6)
    static let timelineTertiaryText = Color.black.opacity(0.4)
    
    // Status colors
    static let timelineSuccess = Color(red: 0.0, green: 0.6, blue: 0.5) // Teal green
    static let timelineWarning = Color(red: 0.9, green: 0.4, blue: 0.0) // Orange
    static let timelineError = Color(red: 0.8, green: 0.2, blue: 0.1) // Red/rust
    static let timelineInfo = Color(red: 1.0, green: 0.8, blue: 0.0) // Yellow
}

// Common view styling
extension View {
    // Apply standard card styling - with thin black border
    func timelineCardStyle() -> some View {
        self.padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.timelineCardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.timelineOutline, lineWidth: 1)
            )
    }
    
    // Apply standard button style - with black outline
    func timelinePrimaryButtonStyle() -> some View {
        self.padding(.vertical, 14)
            .background(Color.timelinePrimary)
            .foregroundColor(.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.timelineOutline, lineWidth: 1)
            )
    }
    
    // Apply secondary button style
    func timelineSecondaryButtonStyle() -> some View {
        self.padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.timelineSecondaryBackground)
            .foregroundColor(Color.timelinePrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.timelineOutline, lineWidth: 1)
            )
    }
    
    // Apply standard badge style - with minimal outline
    func timelineBadgeStyle() -> some View {
        self.padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.white)
            .foregroundColor(Color.timelinePrimaryText)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.timelineOutline, lineWidth: 1)
            )
    }
} 
