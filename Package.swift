// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SnoreRecorder",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SnoreRecorder",
            targets: ["SnoreRecorder"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "SnoreRecorder",
            dependencies: [],
            path: "SnoreRecorder",
            sources: [
                "SnoreRecorderApp.swift",
                "Views/ContentView.swift",
                "Views/RecordingView.swift",
                "Views/HistoryView.swift",
                "Views/AnalysisView.swift",
                "Views/SettingsView.swift",
                "Models/Recording.swift",
                "Services/PersistenceController.swift",
                "Services/AudioPermissionManager.swift",
                "Services/AudioRecordingService.swift",
                "Services/MLAnalysisService.swift"
            ]
        ),
    ]
)
