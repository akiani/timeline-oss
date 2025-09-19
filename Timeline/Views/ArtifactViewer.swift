// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI
import MarkdownUI

// MARK: - Main Artifact Viewer Sheet

struct ArtifactViewerSheet: View {
    let artifact: FHIRArtifact
    @StateObject private var viewModel = ArtifactViewerViewModel()
    @State private var selectedAnnotation: MedicalTermAnnotation?
    @State private var showingFHIRRecord = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area
            if viewModel.isLoading {
                DelightfulLoadingView.documentProcessing()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { Log.ui.debug("📄 Showing loading state") }
            } else if let processedArtifact = viewModel.processedArtifact {
                SimplifiedContentView(
                    processedArtifact: processedArtifact,
                    artifact: artifact,
                    selectedAnnotation: $selectedAnnotation,
                    showingFHIRRecord: $showingFHIRRecord
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    Log.ui.debug("📄 Artifact viewer appeared with \(processedArtifact.sections.count) sections")
                    Log.ui.debug("📄 Medical terms: \(processedArtifact.medicalTerms.count)")
                }
            } else if let error = viewModel.error {
                ErrorStateView(error: error) {
                    Task {
                        await viewModel.retryProcessing(artifact)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { Log.ui.debug("📄 Showing error state: \(error.localizedDescription)") }
            } else {
                Text("No content available")
                    .foregroundColor(.timelineSecondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { Log.ui.debug("📄 Showing no content state") }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timelineBackground)
        .navigationTitle(artifact.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.processArtifact(artifact)
        }
        .sheet(isPresented: Binding<Bool>(
            get: { selectedAnnotation != nil },
            set: { if !$0 { selectedAnnotation = nil } }
        )) {
            if let annotation = selectedAnnotation {
                MedicalTermExplanationSheet(annotation: annotation)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color.timelineBackground)
            }
        }
        .onChange(of: selectedAnnotation) { _, annotation in
            // Haptic feedback when annotation is selected
            if annotation != nil {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .sheet(isPresented: $showingFHIRRecord) {
            FHIRRecordView(recordId: artifact.id)
        }
    }
}
// MARK: - Header View

struct ArtifactHeaderView: View {
    let title: String
    let resourceType: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.timelinePrimaryText)
                    .lineLimit(2)
                
                Text(resourceType)
                    .font(.caption)
                    .foregroundColor(.timelineSecondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.timelineSecondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.timelineSecondaryText)
            }
        }
        .padding()
        .background(Color.timelineBackground)
    }
}


// MARK: - Error State

struct ErrorStateView: View {
    let error: ArtifactProcessingError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.timelineWarning)
                
                Text("Processing Failed")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.timelinePrimaryText)
                
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.timelineSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.timelinePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.timelineBackground)
    }
}

// MARK: - Simplified Content View

struct SimplifiedContentView: View {
    let processedArtifact: ProcessedArtifact
    let artifact: FHIRArtifact
    @Binding var selectedAnnotation: MedicalTermAnnotation?
    @Binding var showingFHIRRecord: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Explanatory text for sections
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Extracted Sections")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.timelinePrimaryText)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clinically related sections have been extracted from the record below:")
                                .font(.subheadline)
                                .foregroundColor(.timelineSecondaryText)
                            
                            Text("Tap highlighted medical terms for explanations.")
                                .font(.caption)
                                .foregroundColor(.timelineSecondaryText.opacity(0.8))
                                .italic()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    SimpleAnnotatedTextView(
                        processedArtifact: processedArtifact,
                        selectedAnnotation: $selectedAnnotation
                    )
                    
                    // Disclaimer outside the cards
                    disclaimerView
                    
                    // View Source Record button
                    viewSourceRecordButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.timelineBackground)
            .clipped()
            
        }
    }
    
    // Disclaimer view component
    private var disclaimerView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.footnote)
                .foregroundColor(.timelineSecondaryText)
                .padding(.top, 2)
            
            Text("AI-generated content for informational purposes only. Not medical advice. May be incomplete or inaccurate. Consult healthcare providers for medical decisions.")
                .font(.footnote)
                .foregroundColor(.timelineSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.timelineOutline.opacity(0.5), lineWidth: 0.5)
        )
    }
    
    // View Source Record button
    private var viewSourceRecordButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                showingFHIRRecord = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.headline)
                        .foregroundColor(.timelinePrimary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("View Source Record")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.timelinePrimary)
                        
                        Text("View the original medical record data")
                            .font(.caption)
                            .foregroundColor(.timelineSecondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.timelineSecondaryText)
                }
                .padding(16)
                .background(Color.timelinePrimary.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.timelinePrimary.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}



// MARK: - Annotation Popover

struct AnnotationPopover: View {
    let annotation: MedicalTermAnnotation
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with term and category
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(annotation.term)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.timelinePrimaryText)
                    
                    Text(annotation.categoryDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(annotation.categoryColor))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(annotation.categoryColor).opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
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
        .padding(.horizontal, 16)
        .padding(.top, 60) // Position below header
    }
}

// MARK: - Medical Term Explanation Sheet

struct MedicalTermExplanationSheet: View {
    let annotation: MedicalTermAnnotation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom header
            HStack {
                Text(annotation.term)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.timelinePrimaryText)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.timelinePrimary)
                .fontWeight(.medium)
            }
            .padding()
            .background(Color.timelineBackground)
            
            Divider()
            
            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Category badge
                    HStack(spacing: 8) {
                        Image(systemName: iconForCategory(annotation.category))
                            .font(.caption)
                            .foregroundColor(Color(annotation.categoryColor))
                        
                        Text(annotation.categoryDisplayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(annotation.categoryColor))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(annotation.categoryColor).opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // Explanation
                    Text(annotation.explanation)
                        .font(.body)
                        .foregroundColor(.timelinePrimaryText)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
            }
            .background(Color.timelineBackground)
        }
        .background(Color.timelineBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
