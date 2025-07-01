//
//  AudioPermissionManager.swift
//  SnoreRecorder
//
//  Manages microphone permissions and audio session setup
//

import AVFoundation
import Foundation

class AudioPermissionManager: ObservableObject {
    static let shared = AudioPermissionManager()
    
    @Published var permissionStatus: AVAudioSession.RecordPermission = .undetermined
    @Published var hasPermission: Bool = false
    
    private init() {
        updatePermissionStatus()
    }
    
    func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.updatePermissionStatus()
            }
        }
    }
    
    private func updatePermissionStatus() {
        permissionStatus = AVAudioSession.sharedInstance().recordPermission
        hasPermission = permissionStatus == .granted
    }
    
    func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.playAndRecord,
                                   mode: .default,
                                   options: [.allowBluetooth, .defaultToSpeaker])
        
        try audioSession.setActive(true)
    }
    
    func configureForBackgroundRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.record,
                                   mode: .measurement,
                                   options: [.mixWithOthers])
        
        try audioSession.setActive(true)
    }
    
    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}
