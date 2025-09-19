// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI

enum RecordPillStyle { case primary, secondary }

struct RecordPill: View {
    let event: CareEvent
    let style: RecordPillStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: ResourceTypeIcon.symbol(for: event.resourceType))
                    .font(.caption)
                    .foregroundColor(tintColor)
                Text(event.title)
                    .font(.caption)
                    .fontWeight(style == .secondary ? .medium : .regular)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, verticalPadding)
            .background(tintColor.opacity(0.1))
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var tintColor: Color {
        switch style { case .primary: return .timelinePrimary; case .secondary: return .timelineSecondary }
    }

    private var textColor: Color {
        switch style { case .primary: return .timelinePrimary; case .secondary: return .timelineSecondaryText }
    }

    private var verticalPadding: CGFloat { style == .primary ? 6 : 4 }
    private var cornerRadius: CGFloat { style == .primary ? 14 : 8 }
}

