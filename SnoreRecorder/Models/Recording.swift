//
//  Recording.swift
//  SnoreRecorder
//
//  Core Data model for recording metadata
//

import Foundation
import CoreData

@objc(Recording)
public class Recording: NSManagedObject {
    
}

extension Recording {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recording> {
        return NSFetchRequest<Recording>(entityName: "Recording")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var filePath: String?
    @NSManaged public var isAnalyzed: Bool
    @NSManaged public var analysisResult: String?
    @NSManaged public var volumeData: Data?
    @NSManaged public var averageVolume: Float
    @NSManaged public var maxVolume: Float
    @NSManaged public var snoreEvents: Int32
    @NSManaged public var sleepQualityScore: Float
    @NSManaged public var recommendations: String?
    
}

extension Recording : Identifiable {
    
    public var durationString: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    public var dateString: String {
        guard let startTime = startTime else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    public var volumeDataArray: [Float] {
        guard let data = volumeData else { return [] }
        return data.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self))
        }
    }
    
    public func setVolumeData(_ volumes: [Float]) {
        volumeData = volumes.withUnsafeBytes { Data($0) }
    }
    
}
