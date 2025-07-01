//
//  ContentView.swift
//  SnoreRecorder
//
//  Main app interface with tab navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioService = AudioRecordingService.shared
    @StateObject private var permissionManager = AudioPermissionManager.shared
    
    var body: some View {
        TabView {
            RecordingView()
                .tabItem {
                    Image(systemName: "mic.circle")
                    Text("Record")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("History")
                }
            
            AnalysisView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analysis")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .onAppear {
            if !permissionManager.hasPermission {
                permissionManager.requestMicrophonePermission()
            }
        }
        .alert("Permission Required", isPresented: .constant(!permissionManager.hasPermission && permissionManager.permissionStatus == .denied)) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Microphone access is required to record snoring sounds. Please enable it in Settings.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
