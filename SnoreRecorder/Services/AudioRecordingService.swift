//
//  AudioRecordingService.swift
//  SnoreRecorder
//
//  Core audio recording engine with background support
//

import AVFoundation
import Foundation
#if canImport(UIKit)
import UIKit
#endif
import CoreData

class AudioRecordingService: NSObject, ObservableObject {
    static let shared = AudioRecordingService()
    
    @Published var isRecording = false
    @Published var currentVolume: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0
    @Published var volumeHistory: [Float] = []
    @Published var errorMessage: String?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var currentRecording: Recording?
    private var recordingTimer: Timer?
    private var volumeTimer: Timer?
    #if canImport(UIKit)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif
    private var scheduledDuration: TimeInterval?
    
    // Volume monitoring
    private let volumeBufferSize = 1024
    private var volumeBuffer: [Float] = []
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    private func setupNotifications() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #endif
    }
    
    func startRecording(scheduledDuration: TimeInterval? = nil) {
        guard !isRecording else { return }
        guard AudioPermissionManager.shared.hasPermission else {
            errorMessage = "Microphone permission required"
            return
        }
        
        self.scheduledDuration = scheduledDuration
        
        do {
            try AudioPermissionManager.shared.configureForBackgroundRecording()
            try setupAudioEngine()
            try startRecordingSession()
            
            startBackgroundTask()
            startTimers()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.errorMessage = nil
                self.volumeHistory.removeAll()
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        stopTimers()
        stopAudioEngine()
        finalizeRecording()
        endBackgroundTask()
        
        DispatchQueue.main.async {
            self.isRecording = false
            self.currentVolume = 0.0
            self.recordingDuration = 0
        }
    }
    
    private func setupAudioEngine() throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { throw RecordingError.engineSetupFailed }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { throw RecordingError.inputNodeNotFound }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Create audio file
        let fileName = "recording_\(UUID().uuidString).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsPath.appendingPathComponent(fileName)
        
        audioFile = try AVAudioFile(forWriting: audioFileURL, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ])
        
        // Setup audio tap for volume monitoring
        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(volumeBufferSize), format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        // Create Core Data recording entry
        let context = PersistenceController.shared.container.viewContext
        currentRecording = Recording(context: context)
        currentRecording?.id = UUID()
        currentRecording?.startTime = Date()
        currentRecording?.filePath = fileName
        currentRecording?.isAnalyzed = false
        
        try audioEngine.start()
    }
    
    private func startRecordingSession() throws {
        guard let audioFile = audioFile else { throw RecordingError.audioFileNotFound }
        guard let inputNode = inputNode else { throw RecordingError.inputNodeNotFound }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFile.processingFormat) { [weak self] buffer, _ in
            do {
                try self?.audioFile?.write(from: buffer)
            } catch {
                print("Error writing audio buffer: \(error)")
            }
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        var sum: Float = 0.0
        
        for i in 0..<frameCount {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameCount)
        
        DispatchQueue.main.async {
            self.currentVolume = average
            self.volumeHistory.append(average)
            
            // Keep only last 300 samples (about 5 minutes at 1 sample/second)
            if self.volumeHistory.count > 300 {
                self.volumeHistory.removeFirst()
            }
        }
    }
    
    private func startTimers() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.recordingDuration += 1.0
            }
            
            // Check if scheduled duration is reached
            if let scheduledDuration = self.scheduledDuration,
               self.recordingDuration >= scheduledDuration {
                self.stopRecording()
            }
        }
        
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            // Volume updates are handled in processAudioBuffer
        }
    }
    
    private func stopTimers() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        volumeTimer?.invalidate()
        volumeTimer = nil
    }
    
    private func stopAudioEngine() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        audioFile = nil
    }
    
    private func finalizeRecording() {
        guard let recording = currentRecording else { return }
        
        recording.endTime = Date()
        recording.duration = recordingDuration
        recording.setVolumeData(volumeHistory)
        
        if !volumeHistory.isEmpty {
            recording.averageVolume = volumeHistory.reduce(0, +) / Float(volumeHistory.count)
            recording.maxVolume = volumeHistory.max() ?? 0.0
        }
        
        PersistenceController.shared.save()
        
        // Trigger auto-analysis if enabled
        let autoAnalyze = UserDefaults.standard.bool(forKey: "autoAnalyze")
        if autoAnalyze {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                MLAnalysisService.shared.analyzeRecording(recording)
            }
        }
        
        currentRecording = nil
    }
    
    private func startBackgroundTask() {
        #if canImport(UIKit)
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "AudioRecording") {
            self.endBackgroundTask()
        }
        #endif
    }
    
    private func endBackgroundTask() {
        #if canImport(UIKit)
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        #endif
    }
    
    @objc private func appDidEnterBackground() {
        // Recording continues in background due to audio background mode
        print("App entered background, recording continues...")
    }
    
    @objc private func appWillEnterForeground() {
        print("App will enter foreground")
    }
}

enum RecordingError: Error {
    case engineSetupFailed
    case inputNodeNotFound
    case audioFileNotFound
    case permissionDenied
    
    var localizedDescription: String {
        switch self {
        case .engineSetupFailed:
            return "Failed to setup audio engine"
        case .inputNodeNotFound:
            return "Audio input not available"
        case .audioFileNotFound:
            return "Could not create audio file"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}
