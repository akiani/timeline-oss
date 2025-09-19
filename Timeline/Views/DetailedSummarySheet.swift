// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI

struct DetailedSummarySheet: View {
    @ObservedObject var cluster: CareEventCluster
    @Environment(\.dismiss) var dismiss
    @State private var selectedLiteracyLevel: LiteracyLevel = .everyday
    @State private var showingQuestionsSheet = false
    
    var onSelectRecord: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Controls Section
            controlsSection
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    summaryContent
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.timelineBackground)
        }
        .navigationTitle(formattedDate(from: cluster.date))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .medium))
                        Text("Back")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(.timelinePrimary)
                }
            }
        }
        .background(Color.timelineBackground)
        .onAppear {
            // Generate summary for the default literacy level if needed
            if cluster.literacySummaries[selectedLiteracyLevel] == nil &&
               cluster.isGeneratingSummary[selectedLiteracyLevel] != true {
                generateSummaryForLevel(selectedLiteracyLevel)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showingQuestionsSheet) {
            DoctorQuestionsSheet(cluster: cluster)
        }
    }
    
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Generate Questions Button (moved to top)
            Button(action: {
                showingQuestionsSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.subheadline)
                    Text("Generate Questions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.timelinePrimary)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Full-width Explanation Mode Selector
            Menu {
                ForEach(LiteracyLevel.allCases, id: \.self) { level in
                    Button(action: {
                        selectedLiteracyLevel = level
                        
                        // Generate summary for new level if needed
                        if cluster.literacySummaries[level] == nil &&
                           cluster.isGeneratingSummary[level] != true {
                            generateSummaryForLevel(level)
                        }
                    }) {
                        HStack {
                            Text(level.displayName)
                            if selectedLiteracyLevel == level {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.timelinePrimary)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedLiteracyLevel.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.timelinePrimaryText)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.timelineSecondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.timelineOutline, lineWidth: 0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Summary Content
    
    @ViewBuilder
    private var summaryContent: some View {
        if cluster.isGeneratingSummary[selectedLiteracyLevel] == true {
            loadingView
        } else if let error = cluster.summaryErrors[selectedLiteracyLevel] {
            errorView(error)
        } else if let summary = cluster.literacySummaries[selectedLiteracyLevel] {
            summaryEventsView(summary.events)
        } else {
            emptyView
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer(minLength: 100)
            DelightfulLoadingView.aiThinking()
            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minHeight: 400)
    }
    
    // MARK: - Error View
    
    @ViewBuilder
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.timelineWarning)
            
            Text("Failed to Generate Summary")
                .font(.headline)
                .foregroundColor(.timelinePrimaryText)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.timelineSecondaryText)
                .multilineTextAlignment(.center)
            
            Button(action: {
                generateSummaryForLevel(selectedLiteracyLevel)
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.timelinePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.largeTitle)
                .foregroundColor(.timelineSecondaryText)
            
            Text("No Summary Available")
                .font(.headline)
                .foregroundColor(.timelinePrimaryText)
            
            Button(action: {
                generateSummaryForLevel(selectedLiteracyLevel)
            }) {
                Text("Generate Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.timelinePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    // MARK: - Summary Events View
    
    @ViewBuilder
    private func summaryEventsView(_ events: [SummaryEvent]) -> some View {
        LazyVStack(spacing: 16) {
            ForEach(events) { event in
                eventCardView(event)
            }
            
            // Associated Records Section
            associatedRecordsView
            
            // Disclaimer
            disclaimerView
        }
    }
    
    // MARK: - Event Card View
    
    @ViewBuilder
    private func eventCardView(_ event: SummaryEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Headline
            Text(event.headline)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.timelinePrimaryText)
            
            // Subheadline
            Text(event.subheadline)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.timelineSecondaryText)
            
            // Body with native markdown support
            if let attributedBody = try? AttributedString(markdown: event.body) {
                Text(attributedBody)
                    .font(.body)
                    .foregroundColor(.timelinePrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Fallback to plain text if markdown parsing fails
                Text(event.body)
                    .font(.body)
                    .foregroundColor(.timelinePrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    // MARK: - Associated Records View
    
    private var associatedRecordsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Associated Records")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.timelinePrimaryText)
                .padding(.bottom, 4)
            
            // Individual records grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 8) {
                ForEach(cluster.events, id: \.id) { event in
                    pillRecordButton(for: event) {
                        dismiss()
                        onSelectRecord(event.fhirResourceId)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    // MARK: - Disclaimer View
    
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
        .background(Color.timelineBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.timelineOutline.opacity(0.5), lineWidth: 0.5)
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateSummaryForLevel(_ literacyLevel: LiteracyLevel) {
        cluster.isGeneratingSummary[literacyLevel] = true
        cluster.summaryErrors[literacyLevel] = nil
        
        Task {
            do {
                // Collect FHIR resources for this cluster
                var clusterResources: [String: Any] = [:]
                for event in cluster.events {
                    if let fhirResource = FHIRTimelineService.shared.fhirResources[event.fhirResourceId] {
                        clusterResources[event.fhirResourceId] = fhirResource
                    }
                }
                
                let summaryResponse = try await ClusterSummarizationService.shared.generateSummary(
                    for: cluster,
                    at: literacyLevel,
                    fhirResources: clusterResources
                )
                
                await MainActor.run {
                    cluster.literacySummaries[literacyLevel] = summaryResponse
                    cluster.isGeneratingSummary[literacyLevel] = false
                }
                
            } catch {
                await MainActor.run {
                    cluster.summaryErrors[literacyLevel] = error.localizedDescription
                    cluster.isGeneratingSummary[literacyLevel] = false
                }
            }
        }
    }
    
    // Helper to create record button (shared component)
    @ViewBuilder
    private func pillRecordButton(for event: CareEvent, action: @escaping () -> Void) -> some View {
        RecordPill(event: event, style: .secondary, action: action)
    }
    
    // Resource type icons now centralized via ResourceTypeIcon
    
    // Helper function to format date for navigation title
    private func formattedDate(from dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
}
