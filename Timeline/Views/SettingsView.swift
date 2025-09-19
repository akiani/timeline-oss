// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI
import SafariServices

struct SettingsView: View {
    @StateObject private var geminiService = GeminiService.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingClearAlert = false
    @State private var showingClearCacheAlert = false
    @State private var showingExportSheet = false
    @State private var selectedTab = 0
    
    // Model preferences
    @AppStorage("useProMode.clusterTimeline") private var useProModeTimeline = false
    @AppStorage("useProMode.clusterSummary") private var useProModeSummary = false
    @AppStorage("useProMode.recordSummary") private var useProModeRecord = false
    @AppStorage("useProMode.doctorQuestions") private var useProModeQuestions = false
    @AppStorage("useProMode.artifactProcessing") private var useProModeArtifact = false
    
    // Thinking scale preference  
    @AppStorage("thinkingBudget.scale") private var thinkingScaleRaw = PromptsConfiguration.ThinkingBudgetConfig.defaultScale.rawValue
    
    private var thinkingScale: PromptsConfiguration.ThinkingBudgetConfig.ThinkingScale {
        get { PromptsConfiguration.ThinkingBudgetConfig.ThinkingScale(rawValue: thinkingScaleRaw) ?? PromptsConfiguration.ThinkingBudgetConfig.defaultScale }
        set { thinkingScaleRaw = newValue.rawValue }
    }

    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Settings Tab", selection: $selectedTab) {
                    Text("About").tag(0)
                    Text("AI Model").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    aboutTabContent
                } else {
                    modelTabContent
                }
            }
            .background(Color.timelineBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.timelinePrimary)
                }
            }
        }
        .alert("Clear Usage History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                geminiService.clearUsageHistory()
            }
        } message: {
            Text("This will permanently delete all AI usage history. This action cannot be undone.")
        }
        .alert("Clear AI Cache", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                GeminiCacheStore.shared.clearAllCache()
            }
        } message: {
            Text("This will clear all cached AI generations that are stored on your device. Future requests may be slower until the cache rebuilds.")
        }
        .sheet(isPresented: $showingExportSheet) {
            if let data = geminiService.exportUsageData() {
                ShareSheet(activityItems: [data])
            }
        }

    }
    
    // MARK: - About Tab Content
    
    private var aboutTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // App Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About Yari Timeline")
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    Text("Yari Timeline transforms complex medical records into a beautifully organized health journey. Using the clinical records already stored in your Apple Health, the app creates an intuitive timeline of your important medical events.")
                        .font(.subheadline)
                        .foregroundColor(.timelineSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.timelineCardBackground)
                .cornerRadius(12)
                
                // Links
                VStack(alignment: .leading, spacing: 12) {
                    Text("Resources")
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            openPrivacyPolicy()
                        }) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.timelinePrimary)
                                Text("Privacy Policy")
                                    .foregroundColor(.timelinePrimaryText)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.timelineSecondaryText)
                            }
                            .padding()
                            .background(Color.timelineBackground)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            openContactPage()
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.timelinePrimary)
                                Text("Contact Us")
                                    .foregroundColor(.timelinePrimaryText)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.timelineSecondaryText)
                            }
                            .padding()
                            .background(Color.timelineBackground)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.timelineCardBackground)
                .cornerRadius(12)
                
                // App Version
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Information")
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Version")
                                .foregroundColor(.timelineSecondaryText)
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.timelinePrimaryText)
                        }
                        
                        HStack {
                            Text("Build")
                                .foregroundColor(.timelineSecondaryText)
                            Spacer()
                            Text(buildNumber)
                                .foregroundColor(.timelinePrimaryText)
                        }
                    }
                }
                .padding()
                .background(Color.timelineCardBackground)
                .cornerRadius(12)
                
                // "Made with love" footer
                Text("Made with ❤️ in San Francisco")
                    .font(.caption)
                    .foregroundColor(.timelineSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding()
        }
    }
    
    // MARK: - Model Tab Content
    
    private var modelTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // AI Model Configuration
                VStack(alignment: .leading, spacing: 16) {
                    Text("Model Configuration")
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    Text("Fast Mode optimizes for speed and Pro Mode optimizes for quality (slower)")
                        .font(.footnote)
                        .foregroundColor(.timelineSecondaryText)
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 12) {
                        // Timeline
                        HStack {
                            Text("Timeline Events")
                                .foregroundColor(.timelinePrimaryText)
                            Spacer()
                            Picker("", selection: $useProModeTimeline) {
                                Text("Fast").tag(false)
                                Text("Pro").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                        }
                        
                        // Summary
                        HStack {
                            Text("Encounter Summaries")
                                .foregroundColor(.timelinePrimaryText)
                            Spacer()
                            Picker("", selection: $useProModeSummary) {
                                Text("Fast").tag(false)
                                Text("Pro").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                        }
                        
                        // References
                        HStack {
                            Text("Reference Summaries")
                                .foregroundColor(.timelinePrimaryText)
                            Spacer()
                            Picker("", selection: $useProModeRecord) {
                                Text("Fast").tag(false)
                                Text("Pro").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                        }
                        
                        // Questions
                        HStack {
                            Text("Questions Generation")
                                .foregroundColor(.timelinePrimaryText)
                            Spacer()
                            Picker("", selection: $useProModeQuestions) {
                                Text("Fast").tag(false)
                                Text("Pro").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                        }
                        
                        // Hightlights
                        HStack {
                            Text("Document Highlights")
                                .foregroundColor(.timelinePrimaryText)
                            Spacer()
                            Picker("", selection: $useProModeArtifact) {
                                Text("Fast").tag(false)
                                Text("Pro").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                        }
                    }
                }
                .padding()
                .background(Color.timelineCardBackground)
                .cornerRadius(12)
                
                // Thinking Budget Configuration
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI Thinking Level")
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    Text("Controls how much the AI 'thinks' before responding. Higher levels may improve quality but increase response time.")
                        .font(.footnote)
                        .foregroundColor(.timelineSecondaryText)
                        .padding(.bottom, 4)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Thinking Level")
                                .foregroundColor(.timelinePrimaryText)
                            Spacer()
                            Picker("", selection: $thinkingScaleRaw) {
                                ForEach(PromptsConfiguration.ThinkingBudgetConfig.ThinkingScale.allCases, id: \.rawValue) { scale in
                                    Text(scale.displayName).tag(scale.rawValue)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 120)
                        }
                        
                        Text(thinkingScale.description)
                            .font(.caption)
                            .foregroundColor(.timelineSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color.timelineCardBackground)
                .cornerRadius(12)
                
                // AI Usage Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Usage")
                        .font(.headline)
                        .foregroundColor(.timelinePrimaryText)
                    
                    // Simple token summary
                    let summary = geminiService.usageSummary
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text(formatNumber(summary.totalInputTokens))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.timelinePrimary)
                            Text("Input Tokens")
                                .font(.caption)
                                .foregroundColor(.timelineSecondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack {
                            Text(formatNumber(summary.totalOutputTokens))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.timelinePrimary)
                            Text("Output Tokens")
                                .font(.caption)
                                .foregroundColor(.timelineSecondaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.timelineCardBackground)
                .cornerRadius(12)
                
                // Clear Cache Button
                Button(action: {
                    showingClearCacheAlert = true
                }) {
                    Text("Clear Cache")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.timelineCardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    // MARK: - Link Handling
    
    private func openPrivacyPolicy() {
        guard let url = URL(string: "https://timeline.yari.care/legal/privacy") else { return }
        
        // Open directly in Safari browser
        UIApplication.shared.open(url)
    }
    
    private func openContactPage() {
        guard let url = URL(string: "mailto:timeline@yari.care?subject=Timeline%20App%20Support") else { return }
        
        // Open Mail app with pre-filled email
        UIApplication.shared.open(url)
    }
}
// MARK: - Compact Usage Row

struct CompactUsageRow: View {
    let entry: GeminiUsageEntry
    
    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy h:mma"
        return formatter
    }
    
    var body: some View {
        HStack {
            Text(dateTimeFormatter.string(from: entry.date))
                .font(.caption)
                .foregroundColor(.timelineSecondaryText)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text("\(entry.inputTokens)")
                .font(.caption)
                .foregroundColor(.timelineSecondaryText)
                .frame(width: 70, alignment: .trailing)
            
            Text("\(entry.outputTokens)")
                .font(.caption)
                .foregroundColor(.timelineSecondaryText)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.timelineBackground)
        .cornerRadius(6)
    }
}
