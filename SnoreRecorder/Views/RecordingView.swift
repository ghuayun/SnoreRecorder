//
//  RecordingView.swift
//  SnoreRecorder
//
//  Main recording interface with real-time volume curves
//

import SwiftUI
import Charts

struct RecordingView: View {
    @StateObject private var audioService = AudioRecordingService.shared
    @StateObject private var permissionManager = AudioPermissionManager.shared
    
    @State private var scheduledHours: Double = 8.0
    @State private var showSchedulePicker = false
    @State private var useScheduledRecording = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Sleep Recording")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Spacer()
                
                // Real-time volume visualization
                if audioService.isRecording {
                    VolumeVisualizationView(
                        volumeHistory: audioService.volumeHistory,
                        currentVolume: audioService.currentVolume
                    )
                    .frame(height: 200)
                    .padding(.horizontal)
                } else {
                    VStack {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 100))
                            .foregroundColor(.gray)
                        Text("Ready to Record")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(height: 200)
                }
                
                // Recording status
                VStack(spacing: 10) {
                    if audioService.isRecording {
                        Text("Recording...")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        Text(formatDuration(audioService.recordingDuration))
                            .font(.title)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        
                        Text("Volume: \(String(format: "%.2f", audioService.currentVolume))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Tap to start recording")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Schedule settings
                if !audioService.isRecording {
                    VStack(spacing: 15) {
                        Toggle("Schedule Recording", isOn: $useScheduledRecording)
                            .font(.headline)
                        
                        if useScheduledRecording {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Duration:")
                                    Spacer()
                                    Text("\(String(format: "%.1f", scheduledHours)) hours")
                                        .foregroundColor(.blue)
                                }
                                
                                Slider(value: $scheduledHours, in: 0.5...12.0, step: 0.5) {
                                    Text("Recording Duration")
                                } minimumValueLabel: {
                                    Text("0.5h")
                                        .font(.caption)
                                } maximumValueLabel: {
                                    Text("12h")
                                        .font(.caption)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Record button
                Button(action: {
                    if audioService.isRecording {
                        audioService.stopRecording()
                    } else {
                        let duration = useScheduledRecording ? scheduledHours * 3600 : nil
                        audioService.startRecording(scheduledDuration: duration)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(audioService.isRecording ? Color.red : Color.blue)
                            .frame(width: 120, height: 120)
                        
                        if audioService.isRecording {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(!permissionManager.hasPermission)
                .scaleEffect(audioService.isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: audioService.isRecording)
                
                if let errorMessage = audioService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct VolumeVisualizationView: View {
    let volumeHistory: [Float]
    let currentVolume: Float
    
    var body: some View {
        VStack(spacing: 10) {
            // Real-time volume bar
            VStack(alignment: .leading, spacing: 5) {
                Text("Current Volume")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 20)
                            .cornerRadius(10)
                        
                        Rectangle()
                            .fill(volumeColor(for: currentVolume))
                            .frame(width: geometry.size.width * CGFloat(min(currentVolume * 5, 1.0)), height: 20)
                            .cornerRadius(10)
                            .animation(.easeInOut(duration: 0.1), value: currentVolume)
                    }
                }
                .frame(height: 20)
            }
            
            // Volume history chart
            if !volumeHistory.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Volume History")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Chart {
                        ForEach(Array(volumeHistory.enumerated()), id: \.offset) { index, volume in
                            LineMark(
                                x: .value("Time", index),
                                y: .value("Volume", volume)
                            )
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    .frame(height: 100)
                    .chartYScale(domain: 0...1)
                    .chartXAxis(.hidden)
                }
            }
        }
    }
    
    private func volumeColor(for volume: Float) -> Color {
        if volume < 0.3 {
            return .green
        } else if volume < 0.7 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}
