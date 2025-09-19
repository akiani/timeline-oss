// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI
import UIKit

// MARK: - Simple Annotated Text View

struct SimpleAnnotatedTextView: View {
    let processedArtifact: ProcessedArtifact
    @Binding var selectedAnnotation: MedicalTermAnnotation?
    
    var body: some View {
        // Single card containing all sections
        VStack(alignment: .leading, spacing: 20) {
            ForEach(processedArtifact.sections) { section in
                SectionView(
                    section: section,
                    medicalTerms: processedArtifact.medicalTerms,
                    selectedAnnotation: $selectedAnnotation
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Section View

struct SectionView: View {
    let section: DocumentSection
    let medicalTerms: [MedicalTermAnnotation]
    @Binding var selectedAnnotation: MedicalTermAnnotation?
    
    @State private var matchedAnnotations: [MatchedAnnotation] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section title with icon
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: section.isImportant ? "exclamationmark.triangle.fill" : "doc.text")
                    .font(.caption)
                    .foregroundColor(section.isImportant ? .orange : .timelineSecondary.opacity(0.7))
                
                Text(section.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.timelinePrimaryText)
            }
            
            // Section content with highlights
            HighlightedTextView(
                text: section.content,
                matchedAnnotations: matchedAnnotations,
                selectedAnnotation: $selectedAnnotation
            )
        }
        .onAppear {
            findMatchedAnnotations()
        }
    }
    
    private func findMatchedAnnotations() {
        let matcher = AnnotationMatcher()
        self.matchedAnnotations = matcher.matchAnnotations(
            text: section.content,
            medicalTerms: medicalTerms
        )
    }
}

// MARK: - Highlighted Text View

struct HighlightedTextView: View {
    let text: String
    let matchedAnnotations: [MatchedAnnotation]
    @Binding var selectedAnnotation: MedicalTermAnnotation?
    
    var body: some View {
        HighlightedTextRepresentable(
            text: text,
            matchedAnnotations: matchedAnnotations,
            selectedAnnotation: $selectedAnnotation
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - UIKit Text View with Highlights

class SelfSizingTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        let textSize = sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude))
        return CGSize(width: textSize.width, height: textSize.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
}

struct HighlightedTextRepresentable: UIViewRepresentable {
    let text: String
    let matchedAnnotations: [MatchedAnnotation]
    @Binding var selectedAnnotation: MedicalTermAnnotation?
    
    func makeUIView(context: Context) -> SelfSizingTextView {
        let textView = SelfSizingTextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        // Ensure text wrapping and width constraints
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.maximumNumberOfLines = 0
        
        // Set content compression and hugging priorities
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }
    
    func updateUIView(_ textView: SelfSizingTextView, context: Context) {
        // Create attributed string with highlights
        let attributedString = NSMutableAttributedString(string: text)
        
        // Base styling with paragraph style for proper wrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .natural
        
        // Use monospace font for document-like appearance
        let monospaceFont = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttributes([
            .font: monospaceFont,
            .foregroundColor: UIColor.label.withAlphaComponent(0.9),
            .paragraphStyle: paragraphStyle
        ], range: fullRange)
        
        // Apply highlights for matched annotations
        for matched in matchedAnnotations {
            let color = matched.annotation.categoryColor
            let isSelected = selectedAnnotation?.id == matched.annotation.id
            
            for range in matched.ranges {
                guard range.location >= 0 && NSMaxRange(range) <= attributedString.length else {
                    continue
                }
                
                // Create pill-style highlight
                let attributes: [NSAttributedString.Key: Any] = [
                    .backgroundColor: color.withAlphaComponent(isSelected ? 0.25 : 0.15),
                    .foregroundColor: UIColor.label,
                    .underlineStyle: isSelected ? NSUnderlineStyle.single.rawValue : 0,
                    .underlineColor: color
                ]
                
                attributedString.addAttributes(attributes, range: range)
            }
        }
        
        textView.attributedText = attributedString
        
        // Trigger intrinsic content size recalculation
        textView.invalidateIntrinsicContentSize()
        textView.setNeedsLayout()
        
        // Store data for tap handling
        context.coordinator.matchedAnnotations = matchedAnnotations
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: HighlightedTextRepresentable
        var matchedAnnotations: [MatchedAnnotation] = []
        
        init(_ parent: HighlightedTextRepresentable) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            let location = gesture.location(in: textView)
            
            // Convert tap location to character index
            let position = textView.closestPosition(to: location) ?? textView.beginningOfDocument
            let tapIndex = textView.offset(from: textView.beginningOfDocument, to: position)
            
            // Find if tap is on an annotation
            for matched in matchedAnnotations {
                for range in matched.ranges where NSLocationInRange(tapIndex, range) {
                    // Prevent rapid toggling by only setting if different
                    if parent.selectedAnnotation?.id != matched.annotation.id {
                        parent.selectedAnnotation = matched.annotation
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                    return
                }
            }
            
            // Tap outside annotation - dismiss popover
            withAnimation(.easeInOut(duration: 0.15)) {
                parent.selectedAnnotation = nil
            }
        }
    }
}

// MARK: - Clean Annotation Popover

struct CleanAnnotationPopover: View {
    let annotation: MedicalTermAnnotation
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(annotation.term)
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    HStack(spacing: 8) {
                        Image(systemName: iconForCategory(annotation.category))
                            .font(.caption)
                            .foregroundColor(Color(annotation.categoryColor))
                        
                        Text(annotation.categoryDisplayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(annotation.categoryColor))
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.timelineSecondaryText)
                }
            }
            
            // Explanation
            Text(annotation.explanation)
                .font(.subheadline)
                .foregroundColor(.timelinePrimaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "medical_term":
            return "stethoscope"
        case "procedure":
            return "bandage"
        case "anatomy":
            return "figure.stand"
        case "measurement":
            return "ruler"
        case "condition":
            return "heart.text.square"
        case "medication":
            return "pills"
        default:
            return "info.circle"
        }
    }
}
