# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Development Commands

This is a native iOS SwiftUI app built with Xcode.

### Building the App
- Open `Timeline.xcodeproj` in Xcode
- Build with Cmd+B or Product > Build
- Run with Cmd+R or Product > Run
- The app targets iOS devices and requires HealthKit, which is not available in simulator for clinical records

### Testing with Mock Data
- Add `--use-mock-data` as launch argument in Xcode scheme to load mock colon cancer patient data
- This bypasses HealthKit requirements for development/screenshots
- **IMPORTANT for Claude Code**: Always use `--use-mock-data` argument when launching app during development:
  - `mcp__xcodebuild__launch_app_sim` with `args: ["--use-mock-data"]`
  - `mcp__xcodebuild__launch_app_logs_sim` with `args: ["--use-mock-data"]`
  - This automatically loads mock timeline data and bypasses HealthKit authorization flow
  - Without this flag, app will show onboarding screen and require HealthKit permissions

### Key Dependencies
- Firebase Core & Vertex AI (Google's Gemini API)
- Firebase App Check for security
- HealthKit for clinical record access  
- MarkdownUI for rendering AI-generated content

## Architecture Overview

### Core Services (Singleton Pattern)
- **HealthKitService**: Manages HealthKit authorization and clinical record access
- **FHIRTimelineService**: Main business logic for processing FHIR data and generating timelines
- **GeminiService**: Handles all AI interactions with Google's Gemini model
- **CareClusterSummarizationService**: Generates AI summaries for care event clusters at different literacy levels
- **GeminiCacheManager**: Core Data-based caching system for Gemini API responses with automatic expiration
- **AuthorizationStateService**: Manages HealthKit authorization state and flow control
- **DoctorQuestionsService**: Generates personalized doctor questions based on care event clusters
- **RemindersService**: Manages EventKit integration for adding questions to iOS Reminders
- **TimelinePDFService**: Exports timeline data to PDF format

### Data Flow Architecture
1. **HealthKit Integration**: App requests authorization for clinical record types (allergies, conditions, immunizations, lab results, medications, procedures, vital signs)
2. **FHIR Processing**: Clinical records are converted from HealthKit's FHIR format to structured data
3. **Care Event Clustering**: Records are grouped by date into `CareEventCluster` objects
4. **AI Timeline Generation**: Each cluster is processed by Gemini to create human-readable timeline events
5. **Progressive Loading**: Timeline events are generated automatically in batches with concurrency control

### Key Data Models
- `CareEvent`: Individual health record with FHIR resource reference
- `CareEventCluster`: Groups events by date, contains generated timeline information
- `IndividualTimelineEvent`: AI-generated summary with title, description, and SF Symbol icon
- `DoctorQuestion`: AI-generated question with category, priority, and reminders integration

### UI Navigation Structure
```
TimelineApp (root)
└── MainAppView
    ├── SplashScreen (first launch)
    ├── OnboardingView (landing/onboarding)
    ├── TimelineView (main timeline display)
    │   ├── FHIRRecordView (detailed record viewer)
    │   └── DoctorQuestionsSheet (AI-generated questions for care events)
    └── SettingsView (preferences and export options)
```

### Security & Privacy
- Firebase App Check provides app attestation
- All health data processing is temporary - no server-side storage
- Clinical record attachments (PDFs, HTML) are processed locally when available (iOS 17+)
- No biometric authentication - app relies on device-level security

### Mock Data System
- `MockFHIRData.swift` contains realistic colon cancer patient timeline
- Enables development and screenshots without real health data
- Activated via `--use-mock-data` launch argument
- **How it works**: 
  - `TimelineApp.swift` checks for `--use-mock-data` in `ProcessInfo.processInfo.arguments` on launch
  - When found, calls `timelineService.loadColonCancerMockData()` 
  - This sets `isHealthKitAuthorized = true` and loads pre-built timeline clusters
  - App automatically navigates to TimelineView instead of showing onboarding
  - **Critical**: Must pass `--use-mock-data` as launch argument, not build argument

### AI Prompt Management
- `PromptsConfiguration.swift` centralizes all AI prompts and model selection
- Supports different Gemini models for different tasks (Flash vs Pro)
- Timeline generation uses thinking-disabled models for speed
- Doctor questions use Gemini 2.5 Pro for higher quality outputs

### Integration Features
- EventKit integration for adding doctor questions to iOS Reminders
- PDF export functionality for timeline data
- SF Symbol icon selection for timeline events based on medical context

### Accessibility
- Full support for Dynamic Type with semantic font styles
- Accessibility labels and hints throughout the UI
- Large Text compatibility with flexible layouts
- always run the simulator after changes and always use the debug flag to show mock data unless asked for otherwise
- remember to always pass --use-mock-data to launch_app_logs_sim calls to make sure we have mock data during developemnt (unless specificallly asked otherwise!)
