// Copyright (c) 2025 Amir Kiani
// SPDX-License-Identifier: MIT

import SwiftUI
import HealthKit
import SafariServices

// MARK: - Shining Text Component

struct ShiningText: View {
    let text: String
    let font: Font
    let fontWeight: Font.Weight
    let color: Color
    
    @State private var highlightedCharacterIndex = -1
    private let characterTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(font)
                    .fontWeight(fontWeight)
                    .foregroundColor(characterColor(for: index))
                    .animation(.easeInOut(duration: 0.15), value: highlightedCharacterIndex)
            }
        }
        .onReceive(characterTimer) { _ in
            let totalLength = text.count + 3 // Add some padding
            highlightedCharacterIndex = (highlightedCharacterIndex + 1) % totalLength
        }
    }
    
    private func characterColor(for index: Int) -> Color {
        let distance = abs(index - highlightedCharacterIndex)
        
        switch distance {
        case 0:
            // Center of the wave - brightest
            return color.opacity(0.2)
        case 1:
            // Adjacent letters - bright
            return color.opacity(0.4)
        case 2:
            // Second ring - medium bright
            return color.opacity(0.6)
        case 3:
            // Third ring - slightly bright
            return color.opacity(0.8)
        default:
            // Normal color for distant letters
            return color
        }
    }
}

// MARK: - SplashScreen
struct SplashScreen: View {
    @State private var opacity = 0.0
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.timelineBackground
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                ShiningText(
                    text: "Yari Timeline",
                    font: .title,
                    fontWeight: .semibold,
                    color: .timelinePrimaryText
                )
                Spacer()
            }
            .opacity(opacity)
            .onAppear {
                // Animate the splash screen fading in
                withAnimation(.easeIn(duration: 0.8)) {
                    opacity = 1.0
                }
                
                // After a delay, call completion handler
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete()
                }
            }
        }
    }
}


struct OnboardingView: View {
    @State private var isShowingTimeline = false
    @State private var showingPermissionInfo = false
    @State private var showingSettings = false
    @EnvironmentObject private var timelineService: FHIRTimelineService
    @EnvironmentObject private var authorizationStateService: AuthorizationStateService
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // Logo
                Image("AppLogo")
                    .resizable()
                    .frame(width: 120, height: 120)
                
                // App description
                Text("Know your health story, advocate for best care")
                    .font(.title3)
                    .foregroundColor(.timelineSecondaryText)
                    .frame(maxWidth: 350)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                Spacer()
                
                // Combined features card
                ZStack(alignment: .top) {
                    // Card shape - only background, no content
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.timelineOutline, lineWidth: 0.5)
                        )
                    
                    // Content that determines exact card size
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // Second row
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.timelineSecondary)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Care Timeline")
                                    .font(.headline)
                                    .foregroundColor(.timelinePrimaryText)
                                
                                Text("See your medical history organized by date")
                                    .font(.subheadline)
                                    .foregroundColor(.timelineSecondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        
                        Divider()
                        
                        // Third row
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                                .foregroundColor(.timelineAccent1)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("AI-Powered")
                                    .font(.headline)
                                    .foregroundColor(.timelinePrimaryText)
                                
                                Text("Use AI to understand complex medical concepts and organize your records")
                                    .font(.subheadline)
                                    .foregroundColor(.timelineSecondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        
                        Divider()
                        
                        // Fourth row
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "lock.shield")
                                .font(.title2)
                                .foregroundColor(.timelineAccent2)
                                .frame(width: 32, height: 32)
                            
                            VStack(alignment: .leading) {
                                Text("Private & Secure")
                                    .font(.headline)
                                    .foregroundColor(.timelinePrimaryText)
                                
                                Text("Your data stays private - never stored on our servers")
                                    .font(.subheadline)
                                    .foregroundColor(.timelineSecondaryText)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Instructions text before button
                Text("Grant access to your HealthKit medical records to get started:")
                    .font(.subheadline)
                    .foregroundColor(.timelineSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // Primary action button
                Button(action: {
                    // Check if running in mock data mode
                    if ProcessInfo.processInfo.arguments.contains("--use-mock-data") {
                        authorizationStateService.markOnboardingSeen()
                        isShowingTimeline = true
                        return
                    }
                    
                    // For real users, check authorization status
                    if authorizationStateService.isHealthKitAuthorized {
                        authorizationStateService.markOnboardingSeen()
                        isShowingTimeline = true
                    } else {
                        showingPermissionInfo = true
                    }
                }) {
                    Text(buttonText)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .timelinePrimaryButtonStyle()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .navigationDestination(isPresented: $isShowingTimeline) {
                    TimelineView()
                }
                .fullScreenCover(isPresented: $showingPermissionInfo) {
                    PermissionInfoView(isShowingTimeline: $isShowingTimeline)
                }
                
                Spacer(minLength: 40)
            }
            .background(Color.timelineBackground)
            .navigationTitle("Yari Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.timelinePrimary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    
    // Computed property for button text
    private var buttonText: String {
        if authorizationStateService.isHealthKitAuthorized && 
           timelineService.hasAttemptedCareEventsLoad && 
           !timelineService.careEventClusters.isEmpty {
            return "View Health Timeline"
        } else {
            return "Share Medical Records"
        }
    }
    
    // Helper method to create consistent feature rows
    @ViewBuilder
    private func featureRow(icon: String, iconColor: Color, title: String, description: String, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.timelinePrimaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.timelineSecondaryText)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.top, isFirst ? 8 : 12)
        .padding(.bottom, isLast ? 8 : 12)
        .padding(.horizontal, 12)
    }
}

// Feature row component for the features list - more compact
struct FeatureRow: View {
    var iconName: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Add colored background for icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(colorForIcon(iconName))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.timelinePrimaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.timelineSecondaryText)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.timelineOutline, lineWidth: 0.5)
        )
    }
    
    // Helper to assign colors to icons
    private func colorForIcon(_ icon: String) -> Color {
        switch icon {
        case "list.bullet.rectangle.portrait":
            return .timelinePrimary // Teal
        case "calendar":
            return .timelineSecondary // Orange
        case "brain.head.profile":
            return .timelineAccent1 // Red
        case "lock.shield":
            return .timelineAccent2 // Yellow
        default:
            return .timelinePrimary
        }
    }
}

// Permission explanation view
struct PermissionInfoView: View {
    @Binding var isShowingTimeline: Bool
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authorizationStateService: AuthorizationStateService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon and title - simplified and centered
                    VStack(spacing: 16) {
                        // Properly centered icon
                        Image("AppleHealthBadge")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .frame(maxWidth: .infinity)
                        
                        // Consistent title styling
                        Text("Connect Your Medical Records")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.timelinePrimaryText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Step 1 Card
                    cardView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Step header with time estimate
                            HStack {
                                Text("STEP 1")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.timelineSecondaryText)
                                Spacer()
                                Text("~5 min")
                                    .font(.caption)
                                    .foregroundColor(.timelineSecondaryText)
                            }
                            
                            // Step title with icon
                            HStack(spacing: 12) {
                                Image(systemName: "building.2")
                                    .font(.title2)
                                    .foregroundColor(.timelineSecondary)
                                
                                Text("Add Care Providers")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.timelinePrimaryText)
                            }
                            
                            // Step description
                            Text("First, add your healthcare providers to Apple Health to pull your medical records.")
                                .font(.subheadline)
                                .foregroundColor(.timelineSecondaryText)
                                .multilineTextAlignment(.leading)
                            
                            Text("You can skip this if you have already added your providers.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .italic()
                                .padding(.top, 4)
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 20)
                    
                    
                    // Step 2 Card
                    cardView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Step header with time estimate
                            HStack {
                                Text("STEP 2")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.timelineSecondaryText)
                                Spacer()
                                Text("~1 min")
                                    .font(.caption)
                                    .foregroundColor(.timelineSecondaryText)
                            }
                            
                            // Step title with icon
                            HStack(spacing: 12) {
                                Image(systemName: "hand.raised")
                                    .font(.title2)
                                    .foregroundColor(.timelineAccent1)
                                
                                Text("Grant Access to Yari")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.timelinePrimaryText)
                            }
                            
                            // Step description
                            Text("Allow Yari Timeline to access and analyze your medical records to create your health timeline.")
                                .font(.subheadline)
                                .foregroundColor(.timelineSecondaryText)
                                .multilineTextAlignment(.leading)
                            
                            // Permissions preview image
                            HStack {
                                Spacer()
                                Image("Permissions")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 20)
                    
                    // Privacy statement
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lock.shield")
                            .font(.subheadline)
                            .foregroundColor(.timelinePrimary)
                            .padding(.top, 1)
                        
                        Text("You're always in control of your data — it's never stored on our servers and only processed for a few seconds on a HIPAA-grade backend before being deleted. ")
                            .font(.subheadline)
                            .foregroundColor(.timelineSecondaryText)
                        + Text("See privacy policy")
                            .font(.subheadline)
                            .foregroundColor(.timelinePrimary)
                            .underline()
                    }
                    .padding(.horizontal, 20)
                    .onTapGesture {
                        if let url = URL(string: "https://timeline.yari.care/legal/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    // Action buttons with consistent spacing
                    VStack(spacing: 16) {
                        Button(action: {
                            HealthKitService.shared.requestHealthKitAuthorization { success, error in
                                if success {
                                    // Update authorization state and then load care events
                                    HealthKitService.shared.canAccessHealthRecords { hasAccess in
                                        DispatchQueue.main.async {
                                            if hasAccess {
                                                // Update the authorization service state
                                                authorizationStateService.isHealthKitAuthorized = true
                                                
                                                // Mark that user has seen onboarding
                                                authorizationStateService.markOnboardingSeen()
                                                dismiss()
                                                isShowingTimeline = true
                                                
                                                // Load care events now that we know we have access
                                                Task {
                                                    do {
                                                        try await FHIRTimelineService.shared.loadCareEvents()
                                                    } catch {
                                                        Log.ui.error("Failed to load care events after authorization: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            Text("Continue")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .timelinePrimaryButtonStyle()
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Not Now")
                                .font(.subheadline)
                                .foregroundColor(.timelinePrimary)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: 600) // Limit width on iPad
                .frame(maxWidth: .infinity) // Center on larger screens
                .padding(.top, 20)
            }
            .background(Color.timelineBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .font(.subheadline)
                            .foregroundColor(.timelinePrimary)
                    }
                }
            }
            .preferredColorScheme(.light)
        }
    }
    
    // Helper function to create consistent card views - moved outside body
    @ViewBuilder
    private func cardView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.timelineOutline, lineWidth: 0.5)
                )
            
            content()
        }
        .frame(maxWidth: .infinity)
    }
    
}

// MARK: - View Modifiers
extension View {
    // Custom navigation title modifier
    func customNavigationTitle(_ title: String) -> some View {
        self.toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.timelinePrimaryText)
            }
        }
    }
}

// Add this new view for drawing the timeline icon
struct TimelineIconView: View {
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.black)
                .frame(width: 80, height: 4)
            
            // Vertical line
            Rectangle()
                .fill(Color.black)
                .frame(width: 4, height: 80)
            
            // Colored dots at the ends of the lines
            // Teal dot (left)
            Circle()
                .fill(Color(red: 0.35, green: 0.62, blue: 0.53))
                .frame(width: 20, height: 20)
                .offset(x: -40, y: 0)
            
            // Orange dot (top)
            Circle()
                .fill(Color(red: 0.94, green: 0.53, blue: 0.30))
                .frame(width: 20, height: 20)
                .offset(x: 0, y: -40)
            
            // Red dot (right)
            Circle()
                .fill(Color(red: 0.85, green: 0.33, blue: 0.24))
                .frame(width: 20, height: 20)
                .offset(x: 40, y: 0)
            
            // Yellow dot (bottom)
            Circle()
                .fill(Color(red: 0.95, green: 0.82, blue: 0.27))
                .frame(width: 20, height: 20)
                .offset(x: 0, y: 40)
            
            // Center dot
            Circle()
                .fill(Color.black)
                .frame(width: 8, height: 8)
        }
    }
}

struct PrivacySummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Headline
            HStack(spacing: 10) {
                Text("Privacy Summary")
                    .font(.headline)
                    .foregroundColor(.timelinePrimaryText)
            }
            // Bullets
            ForEach([
                "Your health data is never collected.",
                "Data is transmitted only over encrypted connections and is processed temporarily by our AI model.",
                "Your privacy is our top priority."
            ], id: \.self) { text in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.timelinePrimary)
                        .font(.subheadline)
                        .frame(width: 20) // Ensures all bullet text lines up with the heading
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.timelineSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // Privacy policy link
            Button(action: { 
                if let url = URL(string: "https://timeline.yari.care/legal/privacy") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 4) {
                    Text("Read our privacy policy")
                        .font(.subheadline)
                        .foregroundColor(.timelinePrimary)
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.timelinePrimary)
                }
            }
            .padding(.top, 8)
        }
        .padding(16)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var onFailure: ((URL) -> Void)? = nil
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true
        
        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        safariViewController.preferredBarTintColor = UIColor(Color.timelineBackground)
        safariViewController.preferredControlTintColor = UIColor(Color.timelinePrimary)
        
        // Set delegate to handle failures
        safariViewController.delegate = context.coordinator
        
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariView
        
        init(_ parent: SafariView) {
            self.parent = parent
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if !didLoadSuccessfully {
                parent.onFailure?(parent.url)
            }
        }
    }
}

// MARK: - Previews
#if DEBUG
#Preview("OnboardingView") {
    OnboardingView()
        .environmentObject(FHIRTimelineService.shared)
        .environmentObject(AuthorizationStateService.shared)
}

#Preview("Permission Info View") {
    PermissionInfoView(isShowingTimeline: .constant(false))
        .environmentObject(FHIRTimelineService.shared)
        .environmentObject(AuthorizationStateService.shared)
}
#endif
