# Repository Guidelines

## Project Structure & Module Organization
- `Timeline/` — app source. Key folders: `Services/` (data, APIs, caching), `Views/` (SwiftUI screens), `Models/` (domain types), `Assets.xcassets/` (images, colors), `Preview Content/` (SwiftUI previews).
- `Timeline/TimelineApp.swift` is the entry point; keep app wiring light and delegate logic to services.
- `Timeline.xcodeproj/` — Xcode project and shared scheme `Timeline`.

## Build, Test, and Development Commands
- Build (Simulator): `xcodebuild -project Timeline.xcodeproj -scheme Timeline -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Run locally: open in Xcode (`open Timeline.xcodeproj`), select the `Timeline` scheme, choose a simulator, and Run.


## Coding Style & Naming Conventions
- Swift + SwiftUI, 2‑space indent, max line length ~120.
- Types in `PascalCase`; variables, functions, cases in `camelCase`; files match primary type (e.g., `HealthKitService.swift`).
- Prefer protocol‑oriented design and dependency injection over singletons; avoid force‑unwrapping.
- Keep UI logic in `Views/` and business logic in `Services/`; models remain UI‑agnostic.

## Commit & Pull Request Guidelines
- Commits: concise, imperative voice (e.g., “Fix HealthKit auth flow”). History favors descriptive sentences over strict Conventional Commits; scoped prefixes are okay but not required.
- PRs: clear description, linked issues, screenshots for UI changes, and notes for permission/entitlement updates. Ensure builds pass and no secrets are committed.


## Agent‑Specific Instructions
- Keep diffs minimal; follow existing folder boundaries and naming.
- Avoid renaming public types/paths without strong justification and a repo‑wide sweep.
- Update prompts/configs alongside service changes and keep documentation in sync.
