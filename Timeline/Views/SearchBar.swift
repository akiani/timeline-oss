// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    @FocusState private var isFocused: Bool
    var onFocusChange: ((Bool) -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.timelineSecondaryText)
            
            // Text field
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(.body)
                .foregroundColor(.timelinePrimaryText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            // Clear button (only visible when text exists or focused)
            if !text.isEmpty || isFocused {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                        isFocused = false // Dismiss focus when clearing
                    }
                }) {
                    Image(systemName: !text.isEmpty ? "xmark.circle.fill" : "xmark")
                        .font(.body)
                        .foregroundColor(.timelineSecondaryText)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? Color.timelinePrimary : Color.timelineOutline, lineWidth: isFocused ? 2 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onTapGesture {
            isFocused = true
        }
        .onChange(of: isFocused) { _, newValue in
            onFocusChange?(newValue)
        }
    }
}
