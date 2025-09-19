// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI
import UIKit
import PDFKit
import MarkdownUI

// Wrapper struct for record ID to make it Identifiable
struct RecordIdentifier: Identifiable {
    let id: String
}

struct TimelineView: View {
    @EnvironmentObject private var timelineService: FHIRTimelineService
    @EnvironmentObject private var authorizationStateService: AuthorizationStateService

    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showPDFPreview = false
    @State private var pdfData: Data? = nil
    @State private var pdfDocument: PDFDocument? = nil
    @State private var showShareSheet = false
    @State private var isPDFLoading = true // Always start in loading state
    @State private var hasSetupAppearance = false // Track one-time appearance setup
    @State private var showingSettings = false
    @State private var isRefreshing = false
    
    // Search functionality
    @State private var searchText = ""
    @State private var isSearchFocused = false
    
    // Computed property to check if all displayed clusters are processed
    private var allClustersProcessed: Bool {
        guard !timelineService.displayedClusters.isEmpty else { return false }
        // Check if all displayed clusters are processed AND there are no more to load
        let allDisplayedProcessed = timelineService.displayedClusters.allSatisfy { cluster in
            cluster.timelineEvent != nil && !cluster.isGeneratingTimeline
        }
        return allDisplayedProcessed && !timelineService.hasMoreClustersToProcess
    }
    
    // Computed property to determine if we're in search mode
    private var isSearchMode: Bool {
        return !searchText.isEmpty
    }
    
    // Computed property for filtered clusters based on search text
    private var filteredCareEventClusters: [CareEventCluster] {
        // Use displayedClusters instead of all clusters for progressive loading
        guard !searchText.isEmpty else { return timelineService.displayedClusters }
        
        return timelineService.displayedClusters.filter { cluster in
            guard let timelineEvent = cluster.timelineEvent else { return false }
            
            return timelineEvent.title.localizedCaseInsensitiveContains(searchText) ||
                   timelineEvent.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !authorizationStateService.isHealthKitAuthorized {
                    // No HealthKit authorization - show permission request
                    healthKitPermissionView
                } else if timelineService.isLoadingCareEvents {
                    // Loading care events
                    loadingCareEventsView
                } else if !timelineService.careEventClusters.isEmpty {
                    // Show care events view
                    careEventsContentView
                } else {
                    // Empty state view
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.timelineBackground)
            .navigationTitle("Care Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.light)
            .toolbar {
                // Refresh button on the left
                ToolbarItem(placement: .navigationBarLeading) {
                    // Show refresh button when authorized and has attempted to load data
                    if authorizationStateService.isHealthKitAuthorized && 
                       timelineService.hasAttemptedCareEventsLoad {
                        Button(action: refreshTimeline) {
                            if isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.timelinePrimary)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.timelinePrimary)
                            }
                        }
                        .disabled(isRefreshing)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Print button (conditional) - appears to the left
                        if allClustersProcessed {
                            Button(action: {
                                saveTimelineAsPDF()
                            }) {
                                Image(systemName: "printer")
                                    .foregroundColor(.timelinePrimary)
                            }
                        }
                        
                        // Settings button (always visible) - stays in consistent position
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.timelinePrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showPDFPreview) {
                if let pdfData = pdfData {
                    PDFPreviewSheet(
                        pdfData: pdfData,
                        onShare: {
                            showPDFPreview = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showShareSheet = true
                            }
                        },
                        isPDFLoading: $isPDFLoading,
                        pdfDocument: $pdfDocument
                    )
                }
            }
                    .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("Retry", role: .none) {
                    requestHealthKitPermission()
                }
                Button("OK", role: .cancel) { }
            }
            .onAppear {
                // Only check authorization if we haven't attempted to load care events yet
                // This prevents unnecessary repeated calls
                if !timelineService.hasAttemptedCareEventsLoad {
                    authorizationStateService.updateHealthKitAuthorization()
                }
                
                // Load care events immediately if authorized and no data exists (only once)
                if authorizationStateService.isHealthKitAuthorized && 
                   timelineService.careEventClusters.isEmpty && 
                   !timelineService.isLoadingCareEvents &&
                   !timelineService.hasAttemptedCareEventsLoad {
                    loadCareEvents()
                }
                
                // One-time appearance setup
                if !hasSetupAppearance {
                    setupAppearance()
                    hasSetupAppearance = true
                }
            }
            
        }
        .tint(.timelinePrimary)
    }
    
    // MARK: - Content Views
    
    // HealthKit permission view
    private var healthKitPermissionView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .font(.largeTitle)
                .foregroundColor(.timelinePrimary)
                .padding(.bottom, 8)
            
            Text("HealthKit Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.timelinePrimaryText)
            
            Text("Timeline needs access to your health records to generate your health journey timeline.")
                .font(.subheadline)
                .foregroundColor(.timelineSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
            
            Button(action: requestHealthKitPermission) {
                Text("Enable HealthKit Access")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .timelinePrimaryButtonStyle()
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timelineBackground)
    }
    

    
    // Empty state view when no timeline data is available
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.largeTitle)
                .foregroundColor(.timelineSecondary)
                .padding()
            
            Text("No Health Records Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.timelinePrimaryText)
            
            Text("We couldn't find any clinical records. Make sure Yari has access to your HealthKit data in your device settings and try again.")
                .font(.subheadline)
                .foregroundColor(.timelineSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timelineBackground)
    }
    
    // Loading care events view
    private var loadingCareEventsView: some View {
        DelightfulLoadingView.dataLoading()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.timelineBackground)
    }
    
    // No search results view
    private var noSearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.timelineSecondary)
                .padding()
            
            Text("No Matching Results")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.timelinePrimaryText)
            
            Text("No timeline events match '\(searchText)'. Try different search terms or clear the filter to see all events.")
                .font(.subheadline)
                .foregroundColor(.timelineSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    searchText = ""
                }
            }) {
                Text("Clear Search")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.timelinePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.timelineBackground)
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
        .background(Color.timelineBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.timelineOutline.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal)
    }
    
    // Care events content view
    private var careEventsContentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search your timeline...") { focused in
                    isSearchFocused = focused
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Disclaimer (only show at top when not in search mode)
                if !isSearchMode {
                    disclaimerView
                }
                
                // Care event clusters
                if filteredCareEventClusters.isEmpty && !searchText.isEmpty {
                    // No search results state
                    noSearchResultsView
                } else {
                    ForEach(filteredCareEventClusters) { cluster in
                        careEventClusterView(cluster: cluster)
                    }
                    
                    // Load More button (only show when not in search mode)
                    if !isSearchMode && timelineService.hasMoreClustersToProcess {
                        loadMoreButton
                    }
                    
                    // Show disclaimer at the end when in search mode
                    if isSearchMode {
                        disclaimerView
                    }
                }
            }
        }
        .background(Color.timelineBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            // Dismiss search focus when tapping outside
            if isSearchFocused {
                isSearchFocused = false
            }
        }
    }
    
    // Care event cluster view with proper observation
    @ViewBuilder
    private func careEventClusterView(cluster: CareEventCluster) -> some View {
        CareEventClusterCard(cluster: cluster)
    }
    
    // Load More button
    private var loadMoreButton: some View {
        VStack(spacing: 12) {
            if timelineService.isLoadingMoreTimelines {
                // Loading state
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.timelinePrimary)
                    Text("Loading more events...")
                        .font(.subheadline)
                        .foregroundColor(.timelineSecondaryText)
                }
                .padding(.vertical, 16)
            } else {
                Button(action: {
                    Task {
                        await timelineService.loadNextBatchOfTimelines()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                            .font(.body)
                        
                        Text("Load More")
                            .fontWeight(.medium)
                        
                        Text("(\(timelineService.remainingClustersCount) remaining)")
                            .foregroundColor(.timelineSecondaryText)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.timelinePrimary.opacity(0.1))
                    .foregroundColor(.timelinePrimary)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.timelinePrimary.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(timelineService.isLoadingMoreTimelines)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    
        
    

    

    
    // MARK: - Helper Methods
    

    
    // Load care events
    private func loadCareEvents() {
        Task {
            do {
                try await timelineService.loadCareEvents()
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to load care events: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // Request HealthKit permission
    private func requestHealthKitPermission() {
        Task {
            await authorizationStateService.requestHealthKitAuthorization()
            
            // Update UI on main thread
            await MainActor.run {
                authorizationStateService.updateHealthKitAuthorization()
                
                if !authorizationStateService.isHealthKitAuthorized {
                    alertMessage = "Timeline requires access to your health data to function.\n\nPlease allow access to HealthKit in your device settings to view your health timeline. The app cannot function without this access."
                    showingAlert = true
                } else {
                    // Automatically trigger loading of care events after successful authorization
                    Task {
                        do {
                            try await timelineService.loadCareEvents()
                        } catch {
                            alertMessage = "Failed to load care events: \(error.localizedDescription)"
                            showingAlert = true
                        }
                    }
                }
            }
        }
    }
    
    // Refresh timeline data
    private func refreshTimeline() {
        guard !isRefreshing else { return } // Prevent multiple concurrent refreshes
        
        isRefreshing = true
        
        Task {
            do {
                // Use the new refresh method that doesn't clear existing data
                try await timelineService.refreshCareEvents()
                
                await MainActor.run {
                    self.isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    self.isRefreshing = false
                    self.alertMessage = "Failed to refresh timeline: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    
    // Helper function to convert date string to Date
    private func dateFromString(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString)
    }
    
    // Format date helper function
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
    
    // Generate TimelineData from care event clusters for PDF export
    private func generateTimelineDataFromClusters() -> TimelineData {
        var keyEvents: [TimelineData.KeyEvent] = []
        
        // Convert each cluster with timeline event to a KeyEvent
        for cluster in timelineService.careEventClusters {
            if let timelineEvent = cluster.timelineEvent {
                // Get record IDs and titles from the cluster's care events
                let recordRefs = cluster.events.map { event in
                    TimelineData.KeyEvent.RecordReference(
                        id: event.fhirResourceId,
                        title: event.title
                    )
                }
                
                let keyEvent = TimelineData.KeyEvent(
                    date: cluster.date,
                    title: timelineEvent.title,
                    description: timelineEvent.description,
                    icon: timelineEvent.icon,
                    recordIds: recordRefs,
                    resourceTypeCounts: cluster.resourceTypeCounts
                )
                keyEvents.append(keyEvent)
            }
        }
        
        // Sort events by date (newest first)
        keyEvents.sort { event1, event2 in
            let date1 = dateFromString(event1.date) ?? Date.distantPast
            let date2 = dateFromString(event2.date) ?? Date.distantPast
            return date1 > date2
        }
        
        // Generate summary based on the events
        let eventCount = keyEvents.count
        let dateRange = getDateRangeDescription(from: keyEvents)
        let summary = "This health timeline contains \(eventCount) care events\(dateRange). The records have been organized chronologically to provide an overview of the patient's healthcare journey."
        
        return TimelineData(summary: summary, keyEvents: keyEvents)
    }
    
    // Helper to get date range description
    private func getDateRangeDescription(from events: [TimelineData.KeyEvent]) -> String {
        guard !events.isEmpty else { return "" }
        
        let dates = events.compactMap { dateFromString($0.date) }
        guard let earliest = dates.min(),
              let latest = dates.max() else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if Calendar.current.isDate(earliest, inSameDayAs: latest) {
            return " from \(formatter.string(from: earliest))"
        } else {
            return " spanning from \(formatter.string(from: earliest)) to \(formatter.string(from: latest))"
        }
    }
    
    // One-time appearance setup
    private func setupAppearance() {
        // Apply the cream color to the navigation bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.timelineBackground)
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set the navigation bar tint color to our primary green color
        UINavigationBar.appearance().tintColor = UIColor(Color.timelinePrimary)
        
        // Apply cream color to tab bar as well
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.timelineBackground)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    // PDF export logic
    private func saveTimelineAsPDF() {
        // Generate TimelineData from care event clusters
        guard !timelineService.careEventClusters.isEmpty else {
            alertMessage = "No care events to export."
            showingAlert = true
            return
        }
        
        let timelineData = generateTimelineDataFromClusters()
        
        // Reset state before doing anything else
        self.isPDFLoading = true
        self.pdfDocument = nil
        self.pdfData = nil

        // First show the loading state
        DispatchQueue.main.async {
            self.showPDFPreview = true
            
            // Generate PDF after a short delay to ensure the loading UI is fully displayed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
                // Generate PDF in background thread with high priority
                DispatchQueue.global(qos: .userInitiated).async {
                    // Generate the PDF
                    let data = TimelinePDFService.shared.generatePDF(for: timelineData)
                    
                    // Return to main thread to update UI
                    DispatchQueue.main.async {
                        // Store the data
                        self.pdfData = data
                        
                        // Create document from data - add error handling
                        guard let document = PDFDocument(data: data) else {
                            self.isPDFLoading = false
                            return
                        }
                        
                        // Use a short delay before updating UI to avoid race conditions
                        // with the sheet presentation animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            self.pdfDocument = document
                            
                            // Finally set loading to false
                            DispatchQueue.main.async {
                                self.isPDFLoading = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// Separate view that properly observes cluster changes
struct CareEventClusterCard: View {
    @ObservedObject var cluster: CareEventCluster
    @State private var selectedRecordId: RecordIdentifier? = nil
    @State private var showAllRecords = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Single merged card without NavigationLink wrapper
            VStack(alignment: .leading, spacing: 12) {
                // Top section: Date, Icon, and Status
                HStack(alignment: .top) {
                    // Date
                    Text(formattedDate(from: cluster.date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.timelineSecondaryText)
                    
                    Spacer()
                    
                    // Icon (if timeline event exists)
                    if let timelineEvent = cluster.timelineEvent {
                        Image(systemName: timelineEvent.icon)
                            .font(.title2)
                            .foregroundColor(iconColorFor(icon: timelineEvent.icon))
                    }
                    
                    // Processing status indicator
                    if cluster.isGeneratingTimeline {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.timelinePrimary)
                    }
                }
                
                // Title and description (show loading state if generating)
                if cluster.isGeneratingTimeline {
                    VStack(alignment: .leading, spacing: 8) {
                        ShiningText(
                            text: "Processing \(cluster.events.count) records for this date...",
                            font: .subheadline,
                            fontWeight: .regular,
                            color: .timelineSecondaryText
                        )
                    }
                } else if let timelineEvent = cluster.timelineEvent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(timelineEvent.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.timelinePrimaryText)
                        
                        Text(timelineEvent.description)
                            .font(.subheadline)
                            .foregroundColor(.timelinePrimaryText)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Display artifacts if any exist
                        DocumentArtifactsColumnView(artifacts: timelineEvent.artifacts)
                    }
                } else {
                    // Fallback if no timeline event yet
                    Text("Waiting to process...")
                        .font(.subheadline)
                        .foregroundColor(.timelineSecondaryText)
                }
                
                // Resource type counts and Summary button
                if !cluster.events.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .padding(.top, 4)
                        
                        HStack {
                            // Resource type counts as indicators
                            HStack(spacing: 8) {
                                ForEach(cluster.resourceTypeCounts.keys.sorted(), id: \.self) { resourceType in
                                    if let count = cluster.resourceTypeCounts[resourceType] {
                                        resourceTypeIcon(resourceType: resourceType, count: count)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Summary and Questions buttons in bottom right
                            if !cluster.isGeneratingTimeline {
                                HStack(spacing: 8) {
                                    // Summary button
                                    NavigationLink(destination: DetailedSummarySheet(cluster: cluster) { recordId in
                                        selectedRecordId = RecordIdentifier(id: recordId)
                                    }) {
                                        Text("Summary")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.timelinePrimary)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    
                                    // Questions button
                                    NavigationLink(destination: DoctorQuestionsSheet(cluster: cluster)) {
                                        Text("Questions")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.timelineSecondary)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.timelineOutline, lineWidth: 0.5)
            )
            .padding(.horizontal)
        }
        .sheet(item: $selectedRecordId) { recordIdentifier in
            // In previews, showing the full record view can cause linker issues
            // if it has dependencies like WebKit. We show a placeholder instead.
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                VStack {
                    Text("FHIR Record View Preview")
                        .font(.title)
                    Text("ID: \(recordIdentifier.id)")
                        .font(.body)
                        .padding()
                }
            } else {
                FHIRRecordView(recordId: recordIdentifier.id)
            }
            #else
            FHIRRecordView(recordId: recordIdentifier.id)
            #endif
        }
    }
    
    
    
    // Helper to create resource type icon with count (no text)
    @ViewBuilder
    private func resourceTypeIcon(resourceType: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconForResourceType(resourceType))
                .font(.caption)
                .foregroundColor(.timelineSecondary)
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.timelineSecondaryText)
        }
    }

    // Helper to get appropriate icon for resource type
    private func iconForResourceType(_ resourceType: String) -> String {
        ResourceTypeIcon.symbol(for: resourceType)
    }
    
    // Helper function to determine icon color based on icon name
    private func iconColorFor(icon: String) -> Color {
        // Use specific colors for common medical icons
        switch icon {
        case let x where x.contains("heart"):
            return .red
        case let x where x.contains("lungs"):
            return .blue
        case let x where x.contains("brain"):
            return .purple
        case let x where x.contains("pills"):
            return .orange
        case let x where x.contains("syringe"):
            return .green
        case let x where x.contains("cross"):
            return .red
        case let x where x.contains("bandage"):
            return .pink
        case let x where x.contains("allergens"):
            return .yellow
        case let x where x.contains("stethoscope"):
            return .indigo
        case let x where x.contains("testtube"):
            return .teal
        default:
            return .timelinePrimary
        }
    }
    
    // Format date helper function
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

// The FHIRRecordView has been moved to its own file


// Extension to allow rounding specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Custom shape for rounding specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                                byRoundingCorners: corners, 
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Custom shape for rounded corners on specific sides
struct RoundedCorners: Shape {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topTrailing = CGPoint(x: rect.maxX - topRight, y: rect.minY)
        let bottomLeading = CGPoint(x: rect.minX + bottomLeft, y: rect.maxY)
        
        // Start at top left with rounded corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                    radius: topLeft,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 270),
                    clockwise: false)
        
        // Line to top right and add rounded corner
        path.addLine(to: topTrailing)
        path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                    radius: topRight,
                    startAngle: Angle(degrees: 270),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        
        // Line to bottom right and add rounded corner
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                    radius: bottomRight,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)
        
        // Line to bottom left and add rounded corner
        path.addLine(to: bottomLeading)
        path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                    radius: bottomLeft,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180),
                    clockwise: false)
        
        // Line back to start
        path.closeSubpath()
        
        return path
    }
}



struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct TimelineViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct PDFPreviewSheet: View {
    let pdfData: Data
    var onShare: () -> Void
    @Binding var isPDFLoading: Bool
    @Binding var pdfDocument: PDFDocument?
    @State private var loadAttempt = 0
    @State private var loadTimeout = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .padding()
            }
            
            if isPDFLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(2.5)
                        .tint(.timelinePrimary)
                        .padding(.bottom, 24)
                    Text("Preparing PDF...")
                        .font(.title3)
                        .padding()
                    Text("Please wait")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemBackground))
                .onAppear {
                    // Set a timeout to handle cases where loading gets stuck
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if isPDFLoading && pdfDocument == nil {
                            loadTimeout = true
                            
                            // Try to create the document one more time
                            if pdfDocument == nil && !pdfData.isEmpty {
                                let document = PDFDocument(data: pdfData)
                                if let document = document {
                                    self.pdfDocument = document
                                    self.isPDFLoading = false
                                }
                            }
                        }
                    }
                }
            } else if let document = pdfDocument {
                EnhancedPDFView(document: document)
                    .edgesIgnoringSafeArea(.bottom)
            } else if loadTimeout {
                VStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding(.bottom, 16)
                    Text("PDF Generation Timeout")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)
                    Text("The PDF is taking longer than expected. You can try again or share the data directly.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Try Again") {
                        loadAttempt += 1
                        loadTimeout = false
                        isPDFLoading = true
                        
                        // Attempt to create the document again
                        DispatchQueue.global(qos: .userInitiated).async {
                            if !pdfData.isEmpty {
                                let document = PDFDocument(data: pdfData)
                                DispatchQueue.main.async {
                                    if let document = document {
                                        self.pdfDocument = document
                                        self.isPDFLoading = false
                                    } else {
                                        // Still failed
                                        self.isPDFLoading = false
                                        self.loadTimeout = true
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.isPDFLoading = false
                                    self.loadTimeout = true
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.timelinePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 8)
                    Spacer()
                }
                .padding()
            } else {
                Text("Error loading PDF")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

struct EnhancedPDFView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Configure the view for performance
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        
        // Set the document after configuring the view
        DispatchQueue.main.async {
            pdfView.document = document
            
            // Ensure we're on the first page
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let firstPage = document.page(at: 0) {
                    pdfView.go(to: firstPage)
                    pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
                    pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
                }
            }
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Ensure the document is still set and visible
        if uiView.document == nil || uiView.document != document {
            uiView.document = document
            
            // Re-navigate to first page
            if let firstPage = document.page(at: 0) {
                uiView.go(to: firstPage)
                uiView.minScaleFactor = uiView.scaleFactorForSizeToFit
                uiView.scaleFactor = uiView.scaleFactorForSizeToFit
            }
        }
    }
}

// MARK: - File-private helpers

// Helper to create individual record button in pill style
@ViewBuilder
fileprivate func pillRecordButton(for event: CareEvent, action: @escaping () -> Void) -> some View {
    RecordPill(event: event, style: .primary, action: action)
}

// Helper to get appropriate icon for resource type
fileprivate func iconForResourceType(_ resourceType: String) -> String {
    ResourceTypeIcon.symbol(for: resourceType)
}

// Helper function to determine icon color based on icon name
fileprivate func iconColorFor(icon: String) -> Color {
    // Use specific colors for common medical icons
    switch icon {
    case let x where x.contains("heart"):
        return .red
    case let x where x.contains("lungs"):
        return .blue
    case let x where x.contains("brain"):
        return .purple
    case let x where x.contains("pills"):
        return .orange
    case let x where x.contains("syringe"):
        return .green
    case let x where x.contains("cross"):
        return .red
    case let x where x.contains("bandage"):
        return .pink
    case let x where x.contains("allergens"):
        return .yellow
    case let x where x.contains("stethoscope"):
        return .indigo
    case let x where x.contains("testtube"):
        return .teal
    default:
        return .timelinePrimary
    }
}

// Format date helper function
fileprivate func formattedDate(from dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: dateString) {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    
    return dateString
}

// MARK: - Document Artifact Component

struct DocumentArtifactView: View {
    let artifact: FHIRArtifact
    
    var body: some View {
        NavigationLink(destination: ArtifactViewerSheet(artifact: artifact)) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.caption)
                    .foregroundColor(.timelinePrimary)
                
                Text(artifact.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.timelinePrimaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.timelineSecondary.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.timelineSecondary.opacity(0.3), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Document Artifacts Row Component

struct DocumentArtifactsRowView: View {
    let artifacts: [FHIRArtifact]
    
    var body: some View {
        if !artifacts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Documents")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.timelineSecondaryText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(artifacts) { artifact in
                            DocumentArtifactView(artifact: artifact)
                        }
                    }
                    .padding(.horizontal, 1) // Small padding for shadow
                }
            }
        }
    }
}

// MARK: - Document Artifacts Column Component (Vertical Layout)

struct DocumentArtifactsColumnView: View {
    let artifacts: [FHIRArtifact]
    
    var body: some View {
        if !artifacts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Important Records")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.timelineSecondaryText)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(artifacts) { artifact in
                        DocumentArtifactView(artifact: artifact)
                    }
                }
            }
        }
    }
}
