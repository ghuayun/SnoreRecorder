//
//  MLAnalysisService.swift
//  SnoreRecorder
//
//  Local LLM analysis service for snore detection and recommendations
//

import Foundation
import CoreML
import AVFoundation
import Accelerate

class MLAnalysisService: ObservableObject {
    static let shared = MLAnalysisService()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    
    private var analysisQueue = DispatchQueue(label: "com.snorerecorder.analysis", qos: .background)
    
    private init() {}
    
    func analyzeRecording(_ recording: Recording) {
        guard !recording.isAnalyzed else { return }
        
        DispatchQueue.main.async {
            self.isAnalyzing = true
            self.analysisProgress = 0.0
        }
        
        analysisQueue.async {
            self.performAnalysis(for: recording)
        }
    }
    
    private func performAnalysis(for recording: Recording) {
        do {
            // Step 1: Load and analyze audio file
            updateProgress(0.2)
            let audioFeatures = try extractAudioFeatures(from: recording)
            
            // Step 2: Detect snore events
            updateProgress(0.4)
            let snoreEvents = detectSnoreEvents(from: audioFeatures)
            
            // Step 3: Analyze volume patterns
            updateProgress(0.6)
            let volumeAnalysis = analyzeVolumePatterns(recording.volumeDataArray)
            
            // Step 4: Generate insights using local LLM (simulated)
            updateProgress(0.8)
            let insights = generateInsights(
                snoreEvents: snoreEvents,
                volumeAnalysis: volumeAnalysis,
                duration: recording.duration
            )
            
            // Step 5: Calculate sleep quality score
            let sleepQuality = calculateSleepQuality(
                snoreEvents: snoreEvents,
                volumeAnalysis: volumeAnalysis,
                duration: recording.duration
            )
            
            updateProgress(1.0)
            
            // Update recording with analysis results
            DispatchQueue.main.async {
                self.updateRecording(
                    recording,
                    snoreEvents: snoreEvents,
                    insights: insights,
                    sleepQuality: sleepQuality
                )
                self.isAnalyzing = false
                self.analysisProgress = 0.0
            }
            
        } catch {
            DispatchQueue.main.async {
                self.isAnalyzing = false
                print("Analysis failed: \(error)")
            }
        }
    }
    
    private func extractAudioFeatures(from recording: Recording) throws -> AudioFeatures {
        guard let filePath = recording.filePath else {
            throw AnalysisError.noAudioData
        }
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsPath.appendingPathComponent(filePath)
        
        let audioFile = try AVAudioFile(forReading: audioFileURL)
        let format = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AnalysisError.bufferCreationFailed
        }
        
        try audioFile.read(into: buffer)
        
        guard let channelData = buffer.floatChannelData?[0] else {
            throw AnalysisError.noAudioData
        }
        
        // Extract features: RMS energy, zero crossing rate, spectral features
        let rmsEnergy = calculateRMSEnergy(channelData, frameCount: Int(frameCount))
        let zeroCrossingRate = calculateZeroCrossingRate(channelData, frameCount: Int(frameCount))
        let spectralCentroid = calculateSpectralCentroid(channelData, frameCount: Int(frameCount), sampleRate: format.sampleRate)
        
        return AudioFeatures(
            rmsEnergy: rmsEnergy,
            zeroCrossingRate: zeroCrossingRate,
            spectralCentroid: spectralCentroid,
            duration: recording.duration
        )
    }
    
    private func detectSnoreEvents(from features: AudioFeatures) -> Int {
        // Simple snore detection algorithm based on energy and spectral characteristics
        var snoreEvents = 0
        let threshold: Float = 0.02 // Energy threshold for snore detection
        let windowSize = 1.0 // 1 second windows
        let totalWindows = Int(features.duration / windowSize)
        
        for i in 0..<totalWindows {
            let windowStart = i * Int(windowSize)
            let windowEnd = min(windowStart + Int(windowSize), features.rmsEnergy.count)
            
            if windowEnd > windowStart {
                let windowEnergy = Array(features.rmsEnergy[windowStart..<windowEnd])
                let avgEnergy = windowEnergy.reduce(0, +) / Float(windowEnergy.count)
                
                // Detect snore based on energy patterns and spectral characteristics
                if avgEnergy > threshold && 
                   features.spectralCentroid[min(i, features.spectralCentroid.count - 1)] < 1000 {
                    snoreEvents += 1
                }
            }
        }
        
        return snoreEvents
    }
    
    private func analyzeVolumePatterns(_ volumeData: [Float]) -> VolumeAnalysis {
        guard !volumeData.isEmpty else {
            return VolumeAnalysis(avgVolume: 0, maxVolume: 0, variability: 0, quietPeriods: 0)
        }
        
        let avgVolume = volumeData.reduce(0, +) / Float(volumeData.count)
        let maxVolume = volumeData.max() ?? 0
        
        // Calculate variability (standard deviation)
        let variance = volumeData.map { pow($0 - avgVolume, 2) }.reduce(0, +) / Float(volumeData.count)
        let variability = sqrt(variance)
        
        // Count quiet periods (consecutive samples below threshold)
        let quietThreshold: Float = 0.01
        var quietPeriods = 0
        var inQuietPeriod = false
        
        for volume in volumeData {
            if volume < quietThreshold {
                if !inQuietPeriod {
                    quietPeriods += 1
                    inQuietPeriod = true
                }
            } else {
                inQuietPeriod = false
            }
        }
        
        return VolumeAnalysis(
            avgVolume: avgVolume,
            maxVolume: maxVolume,
            variability: variability,
            quietPeriods: quietPeriods
        )
    }
    
    private func generateInsights(snoreEvents: Int, volumeAnalysis: VolumeAnalysis, duration: TimeInterval) -> AnalysisInsights {
        // Simulated LLM analysis - in a real implementation, this would use Core ML
        let hoursSlept = duration / 3600
        let snoreRate = Float(snoreEvents) / Float(hoursSlept)
        
        var severity: SnoreSeverity
        var analysisText: String
        var recommendations: [String] = []
        
        // Determine severity
        if snoreRate < 5 {
            severity = .mild
            analysisText = "Your snoring was minimal during this recording session. You had \(snoreEvents) snore events over \(String(format: "%.1f", hoursSlept)) hours, which is considered mild."
        } else if snoreRate < 15 {
            severity = .moderate
            analysisText = "You experienced moderate snoring with \(snoreEvents) events over \(String(format: "%.1f", hoursSlept)) hours. This may be affecting your sleep quality."
            recommendations.append("Consider sleeping on your side rather than your back")
            recommendations.append("Elevate your head with an extra pillow")
        } else {
            severity = .severe
            analysisText = "You had frequent snoring episodes (\(snoreEvents) events) during this \(String(format: "%.1f", hoursSlept))-hour period. This level of snoring may significantly impact your sleep quality and should be addressed."
            recommendations.append("Consult with a healthcare provider about sleep apnea")
            recommendations.append("Consider weight management if applicable")
            recommendations.append("Avoid alcohol and sedatives before bedtime")
        }
        
        // Add volume-based recommendations
        if volumeAnalysis.variability > 0.1 {
            recommendations.append("Your breathing patterns show high variability - consider stress reduction techniques")
        }
        
        if volumeAnalysis.quietPeriods < 5 {
            recommendations.append("Few quiet periods detected - ensure your sleeping environment is conducive to restful sleep")
        }
        
        return AnalysisInsights(
            severity: severity,
            analysisText: analysisText,
            recommendations: recommendations,
            snoreRate: snoreRate
        )
    }
    
    private func calculateSleepQuality(snoreEvents: Int, volumeAnalysis: VolumeAnalysis, duration: TimeInterval) -> Float {
        let hoursSlept = Float(duration / 3600)
        let snoreRate = Float(snoreEvents) / hoursSlept
        
        // Base score starts at 10
        var score: Float = 10.0
        
        // Reduce score based on snoring frequency
        score -= min(snoreRate * 0.3, 4.0)
        
        // Reduce score based on volume variability
        score -= min(volumeAnalysis.variability * 20, 2.0)
        
        // Bonus for quiet periods
        score += min(Float(volumeAnalysis.quietPeriods) * 0.1, 1.0)
        
        return max(min(score, 10.0), 1.0) // Clamp between 1 and 10
    }
    
    private func updateRecording(_ recording: Recording, snoreEvents: Int, insights: AnalysisInsights, sleepQuality: Float) {
        let context = PersistenceController.shared.container.viewContext
        
        recording.snoreEvents = Int32(snoreEvents)
        recording.sleepQualityScore = sleepQuality
        recording.analysisResult = insights.analysisText
        recording.recommendations = insights.recommendations.joined(separator: "\n\n")
        recording.isAnalyzed = true
        
        PersistenceController.shared.save()
    }
    
    private func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.analysisProgress = progress
        }
    }
    
    // MARK: - Audio Processing Utilities
    
    private func calculateRMSEnergy(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) -> [Float] {
        let windowSize = 1024
        var rmsValues: [Float] = []
        
        for i in stride(from: 0, to: frameCount, by: windowSize) {
            let actualWindowSize = min(windowSize, frameCount - i)
            var rms: Float = 0
            
            vDSP_rmsqv(samples.advanced(by: i), 1, &rms, vDSP_Length(actualWindowSize))
            rmsValues.append(rms)
        }
        
        return rmsValues
    }
    
    private func calculateZeroCrossingRate(_ samples: UnsafeMutablePointer<Float>, frameCount: Int) -> [Float] {
        let windowSize = 1024
        var zcrValues: [Float] = []
        
        for i in stride(from: 0, to: frameCount, by: windowSize) {
            let actualWindowSize = min(windowSize, frameCount - i)
            var crossings = 0
            
            for j in 1..<actualWindowSize {
                let current = samples[i + j]
                let previous = samples[i + j - 1]
                if (current >= 0) != (previous >= 0) {
                    crossings += 1
                }
            }
            
            let zcr = Float(crossings) / Float(actualWindowSize)
            zcrValues.append(zcr)
        }
        
        return zcrValues
    }
    
    private func calculateSpectralCentroid(_ samples: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) -> [Float] {
        // Simplified spectral centroid calculation
        let windowSize = 1024
        var centroidValues: [Float] = []
        
        for i in stride(from: 0, to: frameCount, by: windowSize) {
            let actualWindowSize = min(windowSize, frameCount - i)
            
            // Simple approximation - in real implementation would use FFT
            var weightedSum: Float = 0
            var magnitudeSum: Float = 0
            
            for j in 0..<actualWindowSize {
                let sample = abs(samples[i + j])
                let frequency = Float(j) * Float(sampleRate) / Float(windowSize)
                weightedSum += frequency * sample
                magnitudeSum += sample
            }
            
            let centroid = magnitudeSum > 0 ? weightedSum / magnitudeSum : 0
            centroidValues.append(centroid)
        }
        
        return centroidValues
    }
}

// MARK: - Data Structures

struct AudioFeatures {
    let rmsEnergy: [Float]
    let zeroCrossingRate: [Float]
    let spectralCentroid: [Float]
    let duration: TimeInterval
}

struct VolumeAnalysis {
    let avgVolume: Float
    let maxVolume: Float
    let variability: Float
    let quietPeriods: Int
}

struct AnalysisInsights {
    let severity: SnoreSeverity
    let analysisText: String
    let recommendations: [String]
    let snoreRate: Float
}

enum SnoreSeverity {
    case mild, moderate, severe
    
    var description: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
}

enum AnalysisError: Error {
    case bufferCreationFailed
    case noAudioData
    case analysisNotSupported
    
    var localizedDescription: String {
        switch self {
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .noAudioData:
            return "No audio data found"
        case .analysisNotSupported:
            return "Analysis not supported for this audio format"
        }
    }
}
