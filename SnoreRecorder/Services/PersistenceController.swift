//
//  PersistenceController.swift
//  SnoreRecorder
//
//  Core Data stack management
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleRecording = Recording(context: viewContext)
        sampleRecording.id = UUID()
        sampleRecording.startTime = Date().addingTimeInterval(-3600)
        sampleRecording.endTime = Date()
        sampleRecording.duration = 3600
        sampleRecording.filePath = "sample_recording.m4a"
        sampleRecording.isAnalyzed = true
        sampleRecording.averageVolume = 0.3
        sampleRecording.maxVolume = 0.8
        sampleRecording.snoreEvents = 12
        sampleRecording.sleepQualityScore = 7.5
        sampleRecording.analysisResult = "Mild snoring detected with occasional loud episodes."
        sampleRecording.recommendations = "Consider sleeping on your side and maintaining a healthy weight."
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SnoreRecorderModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteRecording(_ recording: Recording) {
        let context = container.viewContext
        
        // Delete the audio file
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileURL = documentsPath.appendingPathComponent(recording.filePath)
        
        do {
            try fileManager.removeItem(at: audioFileURL)
        } catch {
            print("Error deleting audio file: \(error)")
        }
        
        // Delete the Core Data record
        context.delete(recording)
        save()
    }
}
