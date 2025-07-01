//
//  SettingsView.swift
//  SnoreRecorder
//
//  Settings and preferences view
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoAnalyze") private var autoAnalyze = true
    @AppStorage("backgroundRecording") private var backgroundRecording = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("storageLimit") private var storageLimit = 30.0 // days
    @AppStorage("audioQuality") private var audioQuality = AudioQuality.medium.rawValue
    
    @State private var showingStorageInfo = false
    @State private var storageUsed: String = "Calculating..."
    
    var body: some View {
        NavigationView {
            List {
                // Recording Settings
                Section("Recording") {
                    Toggle("Auto-analyze recordings", isOn: $autoAnalyze)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Toggle("Background recording", isOn: $backgroundRecording)
                        .toggleStyle(SwitchToggleStyle())
                    
                    Picker("Audio Quality", selection: $audioQuality) {
                        ForEach(AudioQuality.allCases, id: \.rawValue) { quality in
                            Text(quality.displayName).tag(quality.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Notifications
                Section("Notifications") {
                    Toggle("Enable notifications", isOn: $notificationsEnabled)
                        .toggleStyle(SwitchToggleStyle())
                }
                
                // Storage Management
                Section("Storage") {
                    HStack {
                        Text("Storage used")
                        Spacer()
                        Text(storageUsed)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Show storage details") {
                        showingStorageInfo = true
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Auto-delete recordings after")
                        HStack {
                            Slider(value: $storageLimit, in: 7...365, step: 1) {
                                Text("Storage Limit")
                            }
                            Text("\(Int(storageLimit)) days")
                                .foregroundColor(.blue)
                                .frame(width: 60)
                        }
                    }
                    
                    Button("Clear all recordings") {
                        clearAllRecordings()
                    }
                    .foregroundColor(.red)
                }
                
                // Privacy & Data
                Section("Privacy & Data") {
                    NavigationLink("Data Export", destination: DataExportView())
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                    
                    Button("Reset all settings") {
                        resetAllSettings()
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink("Help & Support", destination: HelpSupportView())
                    NavigationLink("Acknowledgments", destination: AcknowledgmentsView())
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                calculateStorageUsed()
            }
            .sheet(isPresented: $showingStorageInfo) {
                StorageDetailView()
            }
        }
    }
    
    private func calculateStorageUsed() {
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            do {
                let contents = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.fileSizeKey])
                let audioFiles = contents.filter { $0.pathExtension == "m4a" }
                
                var totalSize: Int64 = 0
                for file in audioFiles {
                    let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey])
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                }
                
                let formatter = ByteCountFormatter()
                formatter.countStyle = .file
                
                DispatchQueue.main.async {
                    self.storageUsed = formatter.string(fromByteCount: totalSize)
                }
            } catch {
                DispatchQueue.main.async {
                    self.storageUsed = "Unknown"
                }
            }
        }
    }
    
    private func clearAllRecordings() {
        // Implementation would clear all recordings
        print("Clear all recordings requested")
    }
    
    private func resetAllSettings() {
        autoAnalyze = true
        backgroundRecording = true
        notificationsEnabled = true
        storageLimit = 30.0
        audioQuality = AudioQuality.medium.rawValue
    }
}

struct StorageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storageDetails: [StorageItem] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(storageDetails) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text(item.date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(item.size)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Storage Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadStorageDetails()
            }
        }
    }
    
    private func loadStorageDetails() {
        // Implementation would load detailed storage info
        storageDetails = [
            StorageItem(name: "Recording 1", date: "Yesterday", size: "12.3 MB"),
            StorageItem(name: "Recording 2", date: "2 days ago", size: "8.7 MB"),
            StorageItem(name: "Recording 3", date: "3 days ago", size: "15.2 MB")
        ]
    }
}

struct DataExportView: View {
    @State private var exportFormat: ExportFormat = .csv
    @State private var includeAudioFiles = false
    @State private var showingExportSheet = false
    
    var body: some View {
        List {
            Section("Export Options") {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Toggle("Include audio files", isOn: $includeAudioFiles)
            }
            
            Section("What's included") {
                Label("Recording metadata", systemImage: "doc.text")
                Label("Analysis results", systemImage: "chart.bar")
                Label("Sleep quality scores", systemImage: "moon")
                if includeAudioFiles {
                    Label("Audio recordings", systemImage: "waveform")
                }
            }
            
            Section {
                Button("Export Data") {
                    showingExportSheet = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingExportSheet) {
            ShareSheet(items: ["Exported data would go here"])
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Data Collection")
                    .font(.headline)
                
                Text("SnoreRecorder processes all audio recordings locally on your device. No audio data is transmitted to external servers or third parties.")
                    .font(.body)
                
                Text("Local Processing")
                    .font(.headline)
                
                Text("All AI analysis is performed using on-device machine learning models. Your personal data never leaves your device.")
                    .font(.body)
                
                Text("Data Storage")
                    .font(.headline)
                
                Text("Recordings and analysis results are stored locally in your device's secure storage. You can delete this data at any time through the app settings.")
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSupportView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("How to record", destination: Text("Recording help content"))
                NavigationLink("Understanding analysis", destination: Text("Analysis help content"))
                NavigationLink("Troubleshooting", destination: Text("Troubleshooting content"))
            }
            
            Section("Support") {
                Button("Contact Support") {
                    // Implementation would open email or support system
                }
                Button("Report a Bug") {
                    // Implementation would open bug report
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            Section("Open Source Libraries") {
                Text("This app uses various open source technologies and frameworks.")
            }
            
            Section("Third Party Services") {
                Text("Local machine learning models are used for audio analysis.")
            }
        }
        .navigationTitle("Acknowledgments")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Data Models

struct StorageItem: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let size: String
}

enum AudioQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "Low (16kHz)"
        case .medium: return "Medium (44kHz)"
        case .high: return "High (48kHz)"
        }
    }
}

enum ExportFormat: CaseIterable {
    case csv, json, pdf
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .pdf: return "PDF Report"
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
