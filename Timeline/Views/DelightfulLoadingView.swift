// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI

// MARK: - Delightful Loading View

struct DelightfulLoadingView: View {
    let loadingMessages: [String]
    
    @State private var currentMessageIndex = 0
    @State private var highlightedCharacterIndex = -1
    @State private var currentPhraseCompletionCount = 0
    
    private let characterTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    // Default loading messages - medical timeline focused with a touch of whimsy!
    private static let defaultMessages = [
        "Simplifying",
        "Understanding", 
        "Clarifying",
        "Navigating",
        "Organizing",
        "Translating",
        "Connecting",
        "Discovering",
        "Untangling",
        "Demystifying",
        "Piecing together",
        "Making sense",
        "Breaking down",
        "Weaving stories",
        "Finding patterns",
        "Creating clarity",
        "Building bridges",
        "Solving puzzles",
        "Illuminating",
        "Harmonizing",
        "Contextualizing",
        "Humanizing",
        "Personalizing"
    ]
    
    init(customMessages: [String]? = nil) {
        self.loadingMessages = customMessages ?? Self.defaultMessages
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Loading indicator
            ProgressView()
                .scaleEffect(1.2)
                .tint(.timelinePrimary)
            
            // Animated text with character-by-character highlighting
            HStack(spacing: 0) {
                ForEach(Array(currentMessage.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(characterColor(for: index))
                        .animation(.easeInOut(duration: 0.15), value: highlightedCharacterIndex)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.timelineBackground)
        .onReceive(characterTimer) { _ in
            let messageLength = currentMessage.count
            let totalCycleLength = messageLength + 3 // Add some padding
            
            highlightedCharacterIndex = (highlightedCharacterIndex + 1) % totalCycleLength
            
            // Check if we've completed a full cycle through the message
            if highlightedCharacterIndex == 0 && currentPhraseCompletionCount < 3 {
                currentPhraseCompletionCount += 1
            }
            
            // After 3 complete cycles, move to the next message
            if currentPhraseCompletionCount >= 3 && highlightedCharacterIndex == 0 {
                currentMessageIndex = (currentMessageIndex + 1) % loadingMessages.count
                currentPhraseCompletionCount = 0
            }
        }
    }
    
    private var currentMessage: String {
        guard !loadingMessages.isEmpty else { return "Loading..." }
        return loadingMessages[currentMessageIndex] + "..."
    }
    
    private func characterColor(for index: Int) -> Color {
        let distance = abs(index - highlightedCharacterIndex)
        
        switch distance {
        case 0:
            // Center of the wave - brightest
            return .timelinePrimaryText.opacity(0.2)
        case 1:
            // Adjacent letters - bright
            return .timelinePrimaryText.opacity(0.4)
        case 2:
            // Second ring - medium bright
            return .timelinePrimaryText.opacity(0.6)
        case 3:
            // Third ring - slightly bright
            return .timelinePrimaryText.opacity(0.8)
        default:
            // Normal color for distant letters
            return .timelinePrimaryText
        }
    }
}


// MARK: - Convenience Initializers

extension DelightfulLoadingView {

    // For document processing
    static func documentProcessing() -> DelightfulLoadingView {
        let medicalMessages = [
            "Reading carefully",
            "Parsing content", 
            "Extracting insights",
            "Decoding jargon",
            "Translating terms",
            "Organizing sections",
            "Highlighting key info",
            "Processing details",
            "Connecting concepts",
            "Structuring data",
            "Synthesizing findings",
            "Brewing understanding",
            "Weaving knowledge",
            "Distilling wisdom",
            "Simplifying complexity"
        ]
        
        return DelightfulLoadingView(customMessages: medicalMessages)
    }
    
    // For general AI processing
    static func aiThinking() -> DelightfulLoadingView {
        let thinkingMessages = [
            "Thinking deeply",
            "Contemplating",
            "Understanding context",
            "Pondering meaning",
            "Processing patterns",
            "Brewing insights",
            "Connecting dots",
            "Analyzing nuances",
            "Weighing options",
            "Crafting responses",
            "Distilling knowledge",
            "Finding clarity",
            "Making connections",
            "Solving mysteries",
            "Creating understanding"
        ]
        
        return DelightfulLoadingView(customMessages: thinkingMessages)
    }
    
    // For data loading
    static func dataLoading() -> DelightfulLoadingView {
        let dataMessages = [
            "Loading records",
            "Gathering data",
            "Organizing timeline",
            "Sorting events",
            "Preparing stories",
            "Assembling history",
            "Compiling insights",
            "Structuring journey",
            "Building narrative",
            "Creating connections"
        ]
        
        return DelightfulLoadingView(customMessages: dataMessages)
    }
}

