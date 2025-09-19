// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI
@preconcurrency import WebKit
import MarkdownUI

struct FHIRRecordView: View {
    let recordId: String
    @EnvironmentObject private var timelineService: FHIRTimelineService
    @Environment(\.presentationMode) var presentationMode
    @State private var displayMode: DisplayMode = .aiSummary
    @State private var isLoading = true
    @State private var resourceData: [String: Any]?
    @State private var attachmentData: Data?
    @State private var attachmentContentType: String = ""
    @State private var isLoadingAttachment: Bool = false
    @State private var hasAttachment: Bool = false
    @State private var aiSummary: String = ""
    @State private var isLoadingAISummary: Bool = false
    @State private var aiSummaryError: String?

    init(recordId: String) {
        self.recordId = recordId
    }

    // Custom initializer for previews
    fileprivate init(recordId: String, resourceData: [String: Any]?, aiSummary: String?, hasAttachment: Bool = false) {
        self.recordId = recordId
        self._resourceData = State(initialValue: resourceData)
        self._aiSummary = State(initialValue: aiSummary ?? "")
        self._isLoading = State(initialValue: false)
        self._hasAttachment = State(initialValue: hasAttachment)
    }
    
    enum DisplayMode {
        case aiSummary
        case raw
        case attachment
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Top selector for display mode with conditional attachment tab
                if hasAttachment {
                    Picker("Display Mode", selection: $displayMode) {
                        Text("AI Summary").tag(DisplayMode.aiSummary)
                        Text("Source Data").tag(DisplayMode.raw)
                        Text("Attachment").tag(DisplayMode.attachment)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .accentColor(.timelinePrimary)
                } else {
                    Picker("Display Mode", selection: $displayMode) {
                        Text("AI Summary").tag(DisplayMode.aiSummary)
                        Text("Source Data").tag(DisplayMode.raw)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .accentColor(.timelinePrimary)
                }
                
                Divider()
                
                // Content based on display mode
                if isLoading {
                    loadingView
                } else if displayMode == .attachment {
                    attachmentView
                } else if displayMode == .aiSummary {
                    aiSummaryView
                } else {
                    ScrollView {
                        // Hierarchical JSON tree explorer
                        if let resourceData = resourceData {
                            JSONTreeView(data: resourceData)
                                .padding()
                        } else {
                            Text("No JSON data available")
                                .foregroundColor(.timelineSecondaryText)
                                .padding()
                        }
                    }
                    .background(Color.timelineBackground)
                }
            }
            .navigationTitle("Medical Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Print button when viewing PDF attachments
                        if displayMode == .attachment && attachmentContentType.contains("pdf") && attachmentData != nil {
                    Button(action: {
                                printPDF()
                    }) {
                                Image(systemName: "printer")
                            .foregroundColor(.timelinePrimary)
                    }
                }
                
                        // Done button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Done")
                                .foregroundColor(.timelinePrimary)
                        }
                    }
                }
            }
            .background(Color.timelineBackground)
            .onAppear {
                loadRecordData()
                // Generate AI summary immediately since it's the default view
                if aiSummary.isEmpty && !isLoadingAISummary {
                    generateAISummary()
                }
                // checkForAttachments is now called after successful data load
            }
            .onChange(of: hasAttachment) { _, newHasAttachment in
                // Switch to attachment tab if attachments become available and we're still on default view
                if newHasAttachment && displayMode == .aiSummary {
                    displayMode = .attachment
                }
            }
            .preferredColorScheme(.light)
            .onChange(of: displayMode) { _, newMode in
                if newMode == .aiSummary && aiSummary.isEmpty && !isLoadingAISummary {
                    generateAISummary()
                }
            }

        }
    }
    
    private var loadingView: some View {
        DelightfulLoadingView.dataLoading()
    }
    
    private var attachmentView: some View {
        Group {
            if isLoadingAttachment {
                DelightfulLoadingView.documentProcessing()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let data = attachmentData {
                if attachmentContentType.contains("html") || attachmentContentType.contains("text/html") || detectHTMLContent(in: data) {
                    // HTML content viewer
                    HTMLViewer(data: data)
                        .edgesIgnoringSafeArea(.bottom)
                } else if attachmentContentType.contains("pdf") {
                    // PDF content
                    PDFViewer(data: data)
                        .edgesIgnoringSafeArea(.bottom)
                } else if attachmentContentType.contains("rtf") {
                    // RTF content viewer
                    RTFTextViewer(data: data)
                        .edgesIgnoringSafeArea(.bottom)
                } else if attachmentContentType.contains("text") {
                    // Plain text content
                    TextContentViewer(data: data)
                        .padding()
                } else if attachmentContentType.contains("image") {
                    // Image content
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    } else {
                        Text("Unable to display image data")
                            .foregroundColor(.timelineSecondaryText)
                            .padding()
                    }
                } else {
                    // Generic content - just show info
                    VStack(spacing: 16) {
                        Image(systemName: "doc")
                            .font(.system(.largeTitle, design: .default))
                            .foregroundColor(.timelineSecondary)
                            .padding(.bottom, 8)
                        
                        Text("Document Attachment")
                            .font(.headline)
                            .foregroundColor(.timelinePrimaryText)
                        
                        Text("Type: \(attachmentContentType)")
                            .font(.subheadline)
                            .foregroundColor(.timelineSecondaryText)
                        
                        Text("Size: \(data.count.formattedFileSize)")
                            .font(.subheadline)
                            .foregroundColor(.timelineSecondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(.largeTitle, design: .default))
                        .foregroundColor(.timelineWarning)
                        .padding(.bottom, 8)
                    
                    Text("No attachment data available")
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    Text("The record indicates an attachment exists, but the data could not be loaded.")
                        .font(.subheadline)
                        .foregroundColor(.timelineSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        loadAttachmentData()
                    }) {
                        Text("Try Again")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.timelinePrimary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
    

    
    // Load record data and process it
    private func loadRecordData() {
        isLoading = true
        resourceData = nil
        
        // Try multiple times with increasing delays
        loadRecordDataWithRetry(attempts: 3)
    }
    
    // Helper method to retry loading with delays
    private func loadRecordDataWithRetry(attempts: Int) {
        guard attempts > 0 else {
            self.isLoading = false
            return
        }
        
        // Check if the resource exists
        if let resource = timelineService.getFHIRResource(id: recordId) as? [String: Any] {
            self.resourceData = resource
            self.isLoading = false
            
            // Also check for attachments after successful load
            DispatchQueue.main.async {
                self.checkForAttachments()
            }
        } else {
            // Retry with delay
            let delay = Double(4 - attempts) * 0.3 // 0.3s, 0.6s, 0.9s
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.loadRecordDataWithRetry(attempts: attempts - 1)
            }
        }
    }
    
    // Check if this record has an attachment
    private func checkForAttachments() {
        guard let resource = resourceData else { 
            hasAttachment = false
            return 
        }
        
        // Check if this is a DocumentReference type
        if let resourceType = resource["resourceType"] as? String, 
           resourceType == "DocumentReference" {
            
            // Check for content with attachments
            if let content = resource["content"] as? [[String: Any]] {
                for contentItem in content {
                    if let attachment = contentItem["attachment"] as? [String: Any],
                       (attachment["data"] != nil || attachment["url"] != nil) {
                        hasAttachment = true
                        
                        // If contentType is available, store it
                        if let contentType = attachment["contentType"] as? String {
                            attachmentContentType = contentType
                        }
                        
                        // Load the attachment data
                        loadAttachmentData()
                        break
                    }
                }
            }
        }
        
        // For iOS 17+, check for HealthKit attachments using our new bridge methods
        if !hasAttachment, #available(iOS 17.0, *) {
            if let clinicalRecord = timelineService.getHealthKitRecord(for: recordId) {
                if #available(iOS 15.0, *) {
                    // Use the HealthKitService to check for attachments
                    if HealthKitService.shared.hasAttachment(clinicalRecord: clinicalRecord) {
                        hasAttachment = true
                        loadAttachmentData()
                    }
                }
            }
        }
    }
    
    // Load attachment data
    private func loadAttachmentData() {
        isLoadingAttachment = true
        
        // Try to load from FHIR resource first (if data is embedded)
        if let resource = resourceData,
           let resourceType = resource["resourceType"] as? String,
           resourceType == "DocumentReference",
           let content = resource["content"] as? [[String: Any]] {
            
            for contentItem in content {
                if let attachment = contentItem["attachment"] as? [String: Any] {
                    // Get content type
                    if let contentType = attachment["contentType"] as? String {
                        attachmentContentType = contentType
                    }
                    
                    // Try to get embedded data (base64)
                    if let base64Data = attachment["data"] as? String {
                        if let data = Data(base64Encoded: base64Data) {
                            attachmentData = data
                            
                            // Check if this is actually HTML content regardless of content type
                            if detectHTMLContent(in: data) {
                                attachmentContentType = "text/html"
                            }
                            
                            isLoadingAttachment = false
                            return
                        }
                    }
                }
            }
        }
        
        // If no embedded data was found, try fetching from HealthKit if available
        if #available(iOS 17.0, *) {
            if let clinicalRecord = timelineService.getHealthKitRecord(for: recordId) {
                HealthKitService.shared.fetchAttachmentData(for: clinicalRecord) { data, _ in
                    DispatchQueue.main.async {
                        if let data = data {
                            self.attachmentData = data
                            
                            // Check if this is actually HTML content regardless of content type
                            if self.detectHTMLContent(in: data) {
                                self.attachmentContentType = "text/html"
                            } else if self.attachmentContentType.isEmpty {
                                // If content type wasn't set, determine it
                                let detectedType = HealthKitService.shared.determineContentType(for: data)
                                self.attachmentContentType = detectedType
                            }
                            
                            // Set loading to false after successful data loading
                            self.isLoadingAttachment = false
                        } else {
                            // Error loading attachment
                            self.isLoadingAttachment = false
                        }
                    }
                }
                return
            }
        }
        
        // If we got here, we couldn't load attachment data
        isLoadingAttachment = false
    }
    
    // Helper to detect HTML content regardless of content type
    private func detectHTMLContent(in data: Data) -> Bool {
        // Try to convert to string
        guard let string = String(data: data, encoding: .utf8) else {
            return false
        }
        
        // Check for common HTML tags
        let containsHTMLTags = string.contains("<html") || 
                              string.contains("<div") || 
                              string.contains("<span") || 
                              string.contains("<p>") ||
                              string.contains("<body")
        
        return containsHTMLTags
    }
    

    
    // Print PDF function
    private func printPDF() {
        guard let data = attachmentData else { return }
        
        let printController = UIPrintInteractionController.shared
        
        if PDFDocument(data: data) != nil {
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = "FHIR Document"
            printInfo.outputType = .general
            
            printController.printInfo = printInfo
            printController.printingItem = data
            
            printController.present(animated: true, completionHandler: nil)
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
        .background(Color.timelineBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.timelineOutline.opacity(0.5), lineWidth: 0.5)
        )
    }
    
    // AI Summary view
    private var aiSummaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingAISummary {
                    // Centered loading state with delightful loading
                    DelightfulLoadingView.aiThinking()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .frame(minHeight: 300)
                } else if let error = aiSummaryError {
                    // Error state in card
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.timelineWarning)
                        
                        Text("Failed to Generate Summary")
                            .font(.headline)
                            .foregroundColor(.timelinePrimaryText)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.timelineSecondaryText)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            generateAISummary()
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
                } else if !aiSummary.isEmpty {
                    // AI Summary content in card
                    VStack(alignment: .leading, spacing: 16) {
                        // Summary content
                        Markdown(aiSummary)
                            .markdownTextStyle {
                                FontSize(.em(0.75))
                                ForegroundColor(.timelinePrimaryText)
                            }
                            .textSelection(.enabled)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.timelineOutline, lineWidth: 0.5)
                    )
                    
                    // Disclaimer outside the card
                    disclaimerView
                } else {
                    // Empty state in card
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.title)
                            .foregroundColor(.timelineSecondaryText)
                        
                        Text("No AI Summary Available")
                            .font(.headline)
                            .foregroundColor(.timelinePrimaryText)
                        
                        Button(action: {
                            generateAISummary()
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
            }
            .padding(16)
        }
        .background(Color.timelineBackground)
    }
    
    // Generate AI summary
    private func generateAISummary() {
        guard let resourceData = resourceData else { return }
        
        isLoadingAISummary = true
        aiSummaryError = nil
        aiSummary = "" // Clear previous summary
        
        Task {
            do {
                // Use sortedKeys only (no prettyPrinted) for consistent caching
                // This matches the serialization used in other services for deterministic hashing
                let jsonData = try JSONSerialization.data(withJSONObject: resourceData, options: [.sortedKeys])
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                
                let prompt = PromptsConfiguration.fhirRecordSummaryPrompt(fhirJson: jsonString)
                
                // Switch to non-streaming API to match other services that use caching successfully
                let response = try await GeminiService.shared.generateContent(
                    prompt: prompt,
                    modelName: PromptsConfiguration.ModelNames.recordSummary,
                    usageDescription: PromptsConfiguration.UsageDescriptions.recordSummary(recordId: recordId)
                )
                
                await MainActor.run {
                    self.isLoadingAISummary = false
                    self.aiSummary = response
                }
            } catch {
                await MainActor.run {
                    self.aiSummaryError = error.localizedDescription
                    self.isLoadingAISummary = false
                }
            }
        }
    }
}

// HTML Viewer component
struct HTMLViewer: UIViewRepresentable {
    let data: Data

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Block all navigations to external content for safety
            decisionHandler(.cancel)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        } else {
            // Fallback for iOS < 14.0
            let preferences = WKPreferences()
            preferences.javaScriptEnabled = false
            configuration.preferences = preferences
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = UIColor.white
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // First try to get the html string
        if let htmlString = String(data: data, encoding: .utf8) {
            // Add basic styling if needed
            let styledHTML = ensureProperHTMLStyling(htmlString)
            webView.loadHTMLString(styledHTML, baseURL: URL(string: "about:blank")!)
        } else {
            // If not valid UTF8, try a different approach with raw data and content type
            webView.load(data, mimeType: "text/html", characterEncodingName: "UTF-8", baseURL: URL(string: "about:blank")!)
        }
    }
    
    // Helper to ensure HTML has proper styling
    private func ensureProperHTMLStyling(_ html: String) -> String {
        // If it's not a complete HTML document, wrap it
        if !html.contains("<html") {
            return """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                        font-size: 16px;
                        line-height: 1.5;
                        color: #333;
                        margin: 10px;
                    }
                    h1, h2, h3, h4, h5, h6 {
                        color: #000;
                        font-family: Georgia, serif;
                    }
                    div, p {
                        margin-bottom: 10px;
                    }
                </style>
            </head>
            <body>
            \(html)
            </body>
            </html>
            """
        } else if !html.contains("<style") {
            // If it's already complete HTML but missing styles, add them in the head
            return html.replacingOccurrences(
                of: "<head>",
                with: """
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                    <style>
                        body {
                            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                            font-size: 16px;
                            line-height: 1.5;
                            color: #333;
                            margin: 10px;
                        }
                        h1, h2, h3, h4, h5, h6 {
                            color: #000;
                            font-family: Georgia, serif;
                        }
                        div, p {
                            margin-bottom: 10px;
                        }
                    </style>
                """
            )
        }
        
        return html
    }
}

// PDF Viewer component
struct PDFViewer: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> UIView {
        // Create a simple container view
        let containerView = UIView()
        containerView.backgroundColor = .white
        
        if #available(iOS 11.0, *) {
            // Use PDFKit when available
            let pdfView = PDFKit.PDFView()
            pdfView.autoScales = true
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            
            if let document = PDFKit.PDFDocument(data: data) {
                pdfView.document = document
            }
            
            pdfView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(pdfView)
            
            NSLayoutConstraint.activate([
                pdfView.topAnchor.constraint(equalTo: containerView.topAnchor),
                pdfView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                pdfView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                pdfView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // PDF view is statically configured, no updates needed
    }
}

// RTF Text Viewer component
struct RTFTextViewer: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = UIColor.white
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if let attributedString = try? NSAttributedString(data: data, 
                                                     options: [.documentType: NSAttributedString.DocumentType.rtf], 
                                                     documentAttributes: nil) {
            textView.attributedText = attributedString
        } else if let string = String(data: data, encoding: .utf8) {
            // Fallback to plain text if RTF parsing fails
            textView.text = string
        } else {
            textView.text = "Unable to display RTF content"
        }
    }
}

// Plain Text Viewer component
struct TextContentViewer: View {
    let data: Data
    @State private var text: String = ""
    
    var body: some View {
        ScrollView {
            Text(text)
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .onAppear {
            if let string = String(data: data, encoding: .utf8) {
                text = string
            } else {
                text = "Unable to display text content"
            }
        }
    }
}

// Extension to format file sizes
extension Int {
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(self))
    }
}

// Add these imports if needed
import PDFKit


// MARK: - JSON Tree Explorer

struct JSONTreeView: View {
    let data: [String: Any]
    @State private var expandAll: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Control buttons
            HStack {
                Button(action: {
                    expandAll = true
                }) {
                    Text("Expand All")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.timelinePrimary.opacity(0.1))
                        .foregroundColor(.timelinePrimary)
                        .cornerRadius(6)
                }
                
                Button(action: {
                    expandAll = false
                }) {
                    Text("Collapse All")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.timelineSecondaryText.opacity(0.1))
                        .foregroundColor(.timelineSecondaryText)
                        .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // JSON tree
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(data.keys.sorted(), id: \.self) { key in
                    JSONTreeNode(key: key, value: data[key] ?? "null", level: 0, expandAll: $expandAll)
                }
            }
        }
    }
}

struct JSONTreeNode: View {
    let key: String
    let value: Any
    let level: Int
    @Binding var expandAll: Bool
    @State private var isExpanded: Bool = false
    @State private var showingFullText: Bool = false
    
    private var indentationWidth: CGFloat {
        CGFloat(level * 20)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Node header
            HStack(spacing: 8) {
                // Indentation
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: indentationWidth, height: 1)
                
                // Expand/collapse button for complex types
                if isComplexType(value) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.timelinePrimary)
                            .frame(width: 16, height: 16)
                    }
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 16, height: 16)
                }
                
                // Key
                Text(key)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.timelinePrimaryText)
                
                Text(":")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.timelineSecondaryText)
                
                // Value (for simple types only)
                if !isComplexType(value) {
                    let formattedValue = formatSimpleValue(value)
                    let isTruncated = formattedValue.count > 50 // Threshold for truncation
                    
                    HStack(spacing: 4) {
                        Text(formattedValue)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(colorForValueType(value))
                            .textSelection(.enabled)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        if isTruncated {
                            Button(action: {
                                showingFullText = true
                            }) {
                                Image(systemName: "text.magnifyingglass")
                                    .font(.caption)
                                    .foregroundColor(.timelinePrimary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    // Type indicator for complex types
                    Text(getTypeIndicator(value))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.timelineSecondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.timelineSecondaryText.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            // Expanded content for complex types
            if isComplexType(value) && isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    if let dict = value as? [String: Any] {
                        ForEach(dict.keys.sorted(), id: \.self) { childKey in
                            JSONTreeNode(key: childKey, value: dict[childKey] ?? "null", level: level + 1, expandAll: $expandAll)
                        }
                    } else if let array = value as? [Any] {
                        ForEach(Array(array.enumerated()), id: \.offset) { index, item in
                            JSONTreeNode(key: "[\(index)]", value: item, level: level + 1, expandAll: $expandAll)
                        }
                    }
                }
                .padding(.leading, 4)
                .overlay(
                    Rectangle()
                        .fill(Color.timelineOutline.opacity(0.3))
                        .frame(width: 1)
                        .padding(.leading, indentationWidth + 8),
                    alignment: .leading
                )
            }
        }
        .padding(.vertical, 1)
        .onChange(of: expandAll) { _, newValue in
            if isComplexType(value) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded = newValue
                }
            }
        }
        .sheet(isPresented: $showingFullText) {
            FullTextView(title: key, content: formatSimpleValue(value))
        }
    }
    
    private func isComplexType(_ value: Any) -> Bool {
        return value is [String: Any] || value is [Any]
    }
    
    private func getTypeIndicator(_ value: Any) -> String {
        if let dict = value as? [String: Any] {
            return "{\(dict.count)}"
        } else if let array = value as? [Any] {
            return "[\(array.count)]"
        }
        return ""
    }
    
    private func formatSimpleValue(_ value: Any) -> String {
        if value is NSNull {
            return "null"
        } else if let string = value as? String {
            return "\"\(string)\""
        } else if let number = value as? NSNumber {
            // Check if it's a boolean
            if CFBooleanGetTypeID() == CFGetTypeID(number) {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        } else {
            return String(describing: value)
        }
    }
    
    private func colorForValueType(_ value: Any) -> Color {
        if value is NSNull {
            return .gray
        } else if value is String {
            return .green
        } else if let number = value as? NSNumber {
            // Check if it's a boolean
            if CFBooleanGetTypeID() == CFGetTypeID(number) {
                return .purple
            }
            return .blue
        } else {
            return .timelinePrimaryText
        }
    }
}

// MARK: - Full Text View

struct FullTextView: View {
    let title: String
    let content: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.timelinePrimaryText)
                        .textSelection(.enabled)
                        .padding()
                        .background(Color.timelineSecondaryText.opacity(0.05))
                        .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.timelinePrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    FHIRRecordView(recordId: "preview-record")
        .environmentObject(FHIRTimelineService.shared)
}
