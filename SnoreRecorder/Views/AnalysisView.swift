//
//  AnalysisView.swift
//  SnoreRecorder
//
//  Analysis and insights view with charts and recommendations
//

import SwiftUI
import CoreData
import Charts

struct AnalysisView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.startTime, ascending: false)],
        predicate: NSPredicate(format: "isAnalyzed == true"),
        animation: .default)
    private var analyzedRecordings: FetchedResults<Recording>
    
    @StateObject private var analysisService = MLAnalysisService.shared
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if analyzedRecordings.isEmpty {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Analysis Data Yet")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Complete some recordings to see your sleep analysis")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                    } else {
                        // Analysis content
                        let filteredRecordings = getFilteredRecordings()
                        
                        if !filteredRecordings.isEmpty {
                            // Summary cards
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                SummaryCard(
                                    title: "Avg Sleep Quality",
                                    value: String(format: "%.1f", calculateAverageSleepQuality(filteredRecordings)),
                                    subtitle: "out of 10",
                                    color: .blue
                                )
                                
                                SummaryCard(
                                    title: "Snore Events",
                                    value: "\(calculateTotalSnoreEvents(filteredRecordings))",
                                    subtitle: "total events",
                                    color: .orange
                                )
                                
                                SummaryCard(
                                    title: "Recording Hours",
                                    value: String(format: "%.1f", calculateTotalHours(filteredRecordings)),
                                    subtitle: "hours tracked",
                                    color: .green
                                )
                                
                                SummaryCard(
                                    title: "Avg Snore Rate",
                                    value: String(format: "%.1f", calculateAverageSnoreRate(filteredRecordings)),
                                    subtitle: "events/hour",
                                    color: .red
                                )
                            }
                            .padding(.horizontal)
                            
                            // Sleep quality trend chart
                            SleepQualityChartView(recordings: filteredRecordings)
                                .padding(.horizontal)
                            
                            // Snore events trend chart
                            SnoreEventsChartView(recordings: filteredRecordings)
                                .padding(.horizontal)
                            
                            // Recent insights
                            RecentInsightsView(recordings: Array(filteredRecordings.prefix(3)))
                                .padding(.horizontal)
                            
                            // Recommendations summary
                            RecommendationsSummaryView(recordings: filteredRecordings)
                                .padding(.horizontal)
                        } else {
                            Text("No recordings found for selected time range")
                                .foregroundColor(.secondary)
                                .padding(.top, 50)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Sleep Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Analyze All") {
                        analyzeUnanalyzedRecordings()
                    }
                    .disabled(analysisService.isAnalyzing)
                }
            }
            .overlay(alignment: .bottom) {
                if analysisService.isAnalyzing {
                    AnalysisProgressView(progress: analysisService.analysisProgress)
                        .padding()
                }
            }
        }
    }
    
    private func getFilteredRecordings() -> [Recording] {
        let now = Date()
        let calendar = Calendar.current
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return analyzedRecordings.filter { recording in
            recording.startTime >= startDate
        }
    }
    
    private func calculateAverageSleepQuality(_ recordings: [Recording]) -> Float {
        guard !recordings.isEmpty else { return 0 }
        let total = recordings.reduce(0) { $0 + $1.sleepQualityScore }
        return total / Float(recordings.count)
    }
    
    private func calculateTotalSnoreEvents(_ recordings: [Recording]) -> Int {
        return recordings.reduce(0) { $0 + Int($1.snoreEvents) }
    }
    
    private func calculateTotalHours(_ recordings: [Recording]) -> Double {
        return recordings.reduce(0) { $0 + $1.duration } / 3600
    }
    
    private func calculateAverageSnoreRate(_ recordings: [Recording]) -> Float {
        guard !recordings.isEmpty else { return 0 }
        let totalHours = Float(calculateTotalHours(recordings))
        let totalEvents = Float(calculateTotalSnoreEvents(recordings))
        return totalHours > 0 ? totalEvents / totalHours : 0
    }
    
    private func analyzeUnanalyzedRecordings() {
        let unanalyzedRequest: NSFetchRequest<Recording> = Recording.fetchRequest()
        unanalyzedRequest.predicate = NSPredicate(format: "isAnalyzed == false")
        
        do {
            let unanalyzed = try viewContext.fetch(unanalyzedRequest)
            for recording in unanalyzed {
                analysisService.analyzeRecording(recording)
            }
        } catch {
            print("Error fetching unanalyzed recordings: \(error)")
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SleepQualityChartView: View {
    let recordings: [Recording]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sleep Quality Trend")
                .font(.headline)
            
            if !recordings.isEmpty {
                Chart {
                    ForEach(recordings.sorted(by: { $0.startTime < $1.startTime }), id: \.id) { recording in
                        LineMark(
                            x: .value("Date", recording.startTime),
                            y: .value("Quality", recording.sleepQualityScore)
                        )
                        .foregroundStyle(Color.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Date", recording.startTime),
                            y: .value("Quality", recording.sleepQualityScore)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SnoreEventsChartView: View {
    let recordings: [Recording]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Snore Events Over Time")
                .font(.headline)
            
            if !recordings.isEmpty {
                Chart {
                    ForEach(recordings.sorted(by: { $0.startTime < $1.startTime }), id: \.id) { recording in
                        BarMark(
                            x: .value("Date", recording.startTime),
                            y: .value("Events", recording.snoreEvents)
                        )
                        .foregroundStyle(Color.orange.gradient)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RecentInsightsView: View {
    let recordings: [Recording]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Insights")
                .font(.headline)
            
            ForEach(recordings.prefix(3), id: \.id) { recording in
                if let analysisResult = recording.analysisResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(recording.dateString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Quality: \(String(format: "%.1f", recording.sleepQualityScore))/10")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        Text(analysisResult)
                            .font(.body)
                            .lineLimit(3)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if recordings.isEmpty {
                Text("No recent insights available")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RecommendationsSummaryView: View {
    let recordings: [Recording]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Common Recommendations")
                .font(.headline)
            
            let allRecommendations = recordings.compactMap { $0.recommendations }
                .flatMap { $0.components(separatedBy: "\n\n") }
            
            let recommendationCounts = Dictionary(grouping: allRecommendations, by: { $0 })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            
            ForEach(Array(recommendationCounts.prefix(5)), id: \.key) { recommendation, count in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation)
                            .font(.body)
                        Text("Mentioned \(count) time\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            if recommendationCounts.isEmpty {
                Text("No recommendations available yet")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AnalysisProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .monospacedDigit()
            }
            Text("Analyzing recordings...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.9))
        .cornerRadius(12)
    }
}

enum TimeRange: CaseIterable {
    case week, month, threeMonths, year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        case .year: return "Year"
        }
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
