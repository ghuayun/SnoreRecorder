//
//  HistoryView.swift
//  SnoreRecorder
//
//  Recording history with playback and details
//

import SwiftUI
import CoreData
import AVFoundation

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.startTime, ascending: false)],
        animation: .default)
    private var recordings: FetchedResults<Recording>
    
    @State private var selectedRecording: Recording?
    @State private var showingRecordingDetail = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playingRecording: Recording?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(recordings) { recording in
                    RecordingRowView(
                        recording: recording,
                        isPlaying: isPlaying && playingRecording?.id == recording.id,
                        onPlayToggle: { togglePlayback(for: recording) },
                        onShowDetail: { 
                            selectedRecording = recording
                            showingRecordingDetail = true
                        }
                    )
                }
                .onDelete(perform: deleteRecordings)
            }
            .navigationTitle("Recording History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingRecordingDetail) {
                if let recording = selectedRecording {
                    RecordingDetailView(recording: recording)
                }
            }
            .overlay {
                if recordings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "mic.slash.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Recordings Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Start your first recording from the Record tab")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    private func togglePlayback(for recording: Recording) {
        if let player = audioPlayer, isPlaying, playingRecording?.id == recording.id {
            // Stop current playback
            player.stop()
            isPlaying = false
            playingRecording = nil
            audioPlayer = nil
        } else {
            // Start new playback
            stopCurrentPlayback()
            startPlayback(for: recording)
        }
    }
    
    private func startPlayback(for recording: Recording) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsPath.appendingPathComponent(recording.filePath)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.delegate = AudioPlayerDelegate(onFinish: {
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.playingRecording = nil
                    self.audioPlayer = nil
                }
            })
            audioPlayer?.play()
            isPlaying = true
            playingRecording = recording
        } catch {
            print("Error playing audio: \(error)")
        }
    }
    
    private func stopCurrentPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        playingRecording = nil
        audioPlayer = nil
    }
    
    private func deleteRecordings(offsets: IndexSet) {
        withAnimation {
            offsets.map { recordings[$0] }.forEach { recording in
                PersistenceController.shared.deleteRecording(recording)
            }
        }
    }
}

struct RecordingRowView: View {
    let recording: Recording
    let isPlaying: Bool
    let onPlayToggle: () -> Void
    let onShowDetail: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.dateString)
                    .font(.headline)
                
                Text("Duration: \(recording.durationString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    if recording.isAnalyzed {
                        Label("Analyzed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label("Pending Analysis", systemImage: "clock.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    if recording.snoreEvents > 0 {
                        Text("\(recording.snoreEvents) snore events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button(action: onPlayToggle) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Button(action: onShowDetail) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onShowDetail()
        }
    }
}

struct RecordingDetailView: View {
    let recording: Recording
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recording info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recording Details")
                            .font(.headline)
                        
                        InfoRow(label: "Date", value: recording.dateString)
                        InfoRow(label: "Duration", value: recording.durationString)
                        InfoRow(label: "Average Volume", value: String(format: "%.2f", recording.averageVolume))
                        InfoRow(label: "Max Volume", value: String(format: "%.2f", recording.maxVolume))
                        InfoRow(label: "Snore Events", value: "\(recording.snoreEvents)")
                        
                        if recording.sleepQualityScore > 0 {
                            InfoRow(label: "Sleep Quality", value: String(format: "%.1f/10", recording.sleepQualityScore))
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Volume chart
                    if !recording.volumeDataArray.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Volume Over Time")
                                .font(.headline)
                            
                            VolumeChartView(volumeData: recording.volumeDataArray)
                                .frame(height: 200)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Analysis results
                    if recording.isAnalyzed {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AI Analysis")
                                .font(.headline)
                            
                            if let analysisResult = recording.analysisResult {
                                Text(analysisResult)
                                    .font(.body)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            if let recommendations = recording.recommendations {
                                Text("Recommendations")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(recommendations)
                                    .font(.body)
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        VStack {
                            ProgressView()
                            Text("Analysis in progress...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Recording Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct VolumeChartView: View {
    let volumeData: [Float]
    
    var body: some View {
        // Simple line chart implementation for volume data
        GeometryReader { geometry in
            Path { path in
                guard !volumeData.isEmpty else { return }
                
                let stepX = geometry.size.width / CGFloat(volumeData.count - 1)
                let maxVolume = volumeData.max() ?? 1.0
                
                for (index, volume) in volumeData.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - (CGFloat(volume / maxVolume) * geometry.size.height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
