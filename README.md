# SnoreRecorder - iOS Sleep Recording & Analysis App

A comprehensive iOS application that records snoring sounds during sleep and provides AI-powered analysis with health insights and recommendations.

## Features

### 🎙️ Advanced Recording
- **Background Recording**: Continues recording even when phone is locked or app is in background
- **Real-time Volume Monitoring**: Live volume curves and visualization during recording
- **Scheduled Recording**: Set recording duration (30 minutes to 12 hours)
- **Manual Control**: Start/stop recording anytime
- **High-Quality Audio**: Multiple quality settings (16kHz to 48kHz)

### 📊 Comprehensive Analysis
- **Local AI Processing**: All analysis happens on-device using Core ML
- **Snore Detection**: Automatically identifies and counts snoring events
- **Sleep Quality Scoring**: Rates sleep quality from 1-10 based on multiple factors
- **Volume Pattern Analysis**: Tracks breathing patterns and quiet periods
- **Trend Visualization**: Charts showing progress over time

### 📱 User-Friendly Interface
- **Tab-based Navigation**: Record, History, Analysis, Settings
- **Recording History**: Complete list of all recordings with playback
- **Detailed Views**: In-depth analysis for each recording session
- **Interactive Charts**: Volume curves, trend analysis, and statistics

### 🤖 AI-Powered Insights
- **Personalized Recommendations**: Health tips based on your sleep patterns
- **Severity Assessment**: Categorizes snoring as mild, moderate, or severe
- **Pattern Recognition**: Identifies recurring issues and improvements
- **Privacy-First**: All processing happens locally on your device

## Technical Architecture

### Core Technologies
- **Platform**: iOS 16+ (Native Swift/SwiftUI)
- **Audio Processing**: AVFoundation with real-time audio analysis
- **Data Storage**: Core Data for metadata, local file system for audio
- **Machine Learning**: Core ML for on-device snore analysis
- **Background Processing**: Audio background mode for continuous recording
- **Charts**: Swift Charts for data visualization

### Project Structure
```
SnoreRecorder/
├── SnoreRecorderApp.swift          # Main app entry point
├── Info.plist                     # App configuration and permissions
├── Views/                          # SwiftUI user interface
│   ├── ContentView.swift           # Main tab navigation
│   ├── RecordingView.swift         # Recording interface with live visualization
│   ├── HistoryView.swift           # Recording history and playback
│   ├── AnalysisView.swift          # Charts and insights dashboard
│   └── SettingsView.swift          # App settings and preferences
├── Models/                         # Data models
│   └── Recording.swift             # Core Data recording entity
├── Services/                       # Business logic and services
│   ├── AudioRecordingService.swift # Core audio recording engine
│   ├── AudioPermissionManager.swift # Microphone permissions
│   ├── MLAnalysisService.swift     # AI analysis and insights
│   └── PersistenceController.swift # Core Data management
└── Resources/                      # App resources
    └── SnoreRecorderModel.xcdatamodeld # Core Data model
```

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ target device or simulator
- Apple Developer Account (for device testing)

### Installation Steps

1. **Clone or Download the Project**
   ```bash
   # If using git
   git clone <repository-url>
   cd SnoreRecorder
   
   # Or extract the provided files to a folder named SnoreRecorder
   ```

2. **Open in Xcode**
   ```bash
   open SnoreRecorder.xcodeproj
   ```

3. **Configure Bundle Identifier**
   - Select the project in Xcode navigator
   - Go to "Signing & Capabilities" tab
   - Change bundle identifier to something unique (e.g., `com.yourname.SnoreRecorder`)

4. **Set Development Team**
   - In "Signing & Capabilities", select your development team
   - Ensure "Automatically manage signing" is checked

5. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd+R` to build and run

### Required Permissions

The app will automatically request the following permissions:

- **Microphone Access**: Required for audio recording
- **Background App Refresh**: Allows continued recording when app is backgrounded

### First Launch Setup

1. Grant microphone permission when prompted
2. The app will show the main recording interface
3. Tap the blue record button to start your first recording
4. Test background recording by locking your phone during recording

## Usage Guide

### Recording Sleep Audio

1. **Start Recording**
   - Open the app and go to the "Record" tab
   - Optionally enable "Schedule Recording" and set duration
   - Tap the large blue microphone button
   - Place your phone near your bed (nightstand recommended)

2. **During Recording**
   - The app shows real-time volume levels
   - Recording continues even when phone is locked
   - You can check progress by unlocking your phone

3. **Stop Recording**
   - Unlock your phone and open the app
   - Tap the red stop button
   - Recording is automatically saved

### Viewing Analysis

1. **Automatic Analysis**
   - If auto-analysis is enabled (default), analysis starts automatically
   - Manual analysis can be triggered from the Analysis tab

2. **View Results**
   - Go to "History" tab to see all recordings
   - Tap any recording to view detailed analysis
   - Check "Analysis" tab for trends and insights

### Settings & Customization

- **Auto-analyze**: Automatically analyze recordings when completed
- **Audio Quality**: Choose recording quality (higher = larger files)
- **Storage Management**: Set auto-delete timeframe
- **Data Export**: Export your data for external analysis

## Key Features Explained

### Background Recording Technology
The app uses iOS background audio capabilities to continue recording even when:
- Phone is locked
- App is minimized
- Device is in sleep mode

This is achieved through:
- Audio background mode declaration in Info.plist
- AVAudioSession configuration for background recording
- Background task management to handle app lifecycle

### Local AI Analysis
All audio analysis happens on your device using:
- **Audio Feature Extraction**: RMS energy, zero-crossing rate, spectral analysis
- **Snore Detection**: Pattern recognition algorithms
- **Machine Learning**: Core ML models for classification
- **Privacy Protection**: No data leaves your device

### Real-time Visualization
The recording interface shows:
- Live volume meter with color-coded intensity
- Real-time volume history chart
- Recording duration timer
- Current volume level numeric display

## Privacy & Security

- **Local Processing**: All audio analysis happens on-device
- **No Cloud Upload**: Audio files never leave your device
- **Data Control**: You can delete recordings anytime
- **Encryption**: Data stored using iOS secure storage
- **No Analytics**: No usage data is collected or transmitted

## Troubleshooting

### Common Issues

**Recording doesn't work**
- Ensure microphone permission is granted
- Check if another app is using the microphone
- Restart the app and try again

**Background recording stops**
- Ensure Background App Refresh is enabled for the app
- Check battery optimization settings
- Avoid force-closing the app during recording

**Analysis fails**
- Ensure sufficient storage space available
- Try analyzing shorter recordings first
- Restart the app if analysis seems stuck

**Poor recording quality**
- Adjust audio quality settings
- Ensure phone is close enough to detect snoring
- Check for background noise interference

### Performance Optimization

- **Storage**: Regularly delete old recordings
- **Battery**: Use scheduled recording to avoid all-night recording
- **Quality**: Use lower quality settings for longer recordings
- **Analysis**: Enable auto-analysis only when needed

## Development Notes

### Architecture Decisions

1. **SwiftUI**: Modern, declarative UI framework
2. **MVVM Pattern**: Clear separation of concerns
3. **Combine Framework**: Reactive programming for data flow
4. **Core Data**: Robust local data persistence
5. **Singleton Services**: Shared state management

### Future Enhancements

Potential areas for expansion:
- Export to health apps (HealthKit integration)
- Sleep stage detection
- Integration with smart home devices
- Collaborative analysis with healthcare providers
- Machine learning model improvements

### Contributing

To contribute to this project:
1. Follow Swift style guidelines
2. Add comprehensive comments
3. Include unit tests for new features
4. Update documentation for any changes

## License

This project is provided as-is for educational and personal use. Please ensure compliance with local privacy laws when recording audio.

## Support

For technical support or questions about this implementation, please refer to:
- iOS Development Documentation
- Core ML Documentation
- AVFoundation Programming Guide
- SwiftUI Documentation
