# DefectScanner AR (Not completed project)

An iOS AR application for capturing and documenting home repair defects in 3D space using ARKit.

## Platform & Stack

### Device

- **Model**: iPhone 14 (tested) / iPhone 12 Pro or later recommended
- **OS**: iOS 15.0+
- **LiDAR**: Optional but recommended for enhanced accuracy

### Technologies

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **AR Framework**: ARKit + RealityKit
- **Architecture**: Clean Architecture + MVI Pattern
- **Dependency Injection**: Swinject
- **Build Tool**: Xcode 15.0+

### Key SDKs

- `ARKit`: World tracking, plane detection, raycasting
- `RealityKit`: 3D marker entities, anchoring
- `UIKit`: Gesture recognizers, haptic feedback
- `Combine`: Reactive state management

## Features Implemented

### ✅ Core Requirements

#### Scan Mode

- **World Tracking**: Full 6DOF tracking with ARKit
- **Defect Markers**: Hollow square markers anchored in 3D space
- **Plane Detection**: Horizontal and vertical surface detection
- **Visual Indicators**: Screenshot capture per defect
- **Descriptions**: Text input for each defect
- **Gestures**:
  - Tap to place marker
  - Pinch to resize marker
  - Long press + drag to delete marker

#### Review Mode

- **Defect List**: Scrollable list with thumbnails, descriptions, timestamps
- **Spatial Rendering**: Tap defect to highlight corresponding 3D marker in AR
- **Persistent Session**: AR session maintained when switching modes

### ➕ Additional Features

- **AR Coaching Overlay**: Guides users through initial plane detection
- **Haptic Feedback**: Touch feedback for interactions
- **Debug Mode**: Toggle feature points and plane visualization
- **Isolated Screenshots**: Only captures relevant marker (others hidden)
- **Marker Resizing**: Pinch gesture auto-updates screenshot
- **Drag-to-Delete**: Visual trash zone for marker removal

### ❌ Not Implemented (Optional in Requirements)

- Video capture per defect (image-only implementation)
- Room mesh capture / RoomPlan SDK integration
- Multi-room support
- Cloud sync / persistence

## Setup Instructions

### Prerequisites

1. macOS 13.0+ with Xcode 15.0+
2. iOS device with iOS 15.0+ (Simulator not supported for AR)
3. Apple Developer account for device deployment

### Installation Steps

1. **Clone Repository**

   ```bash
   git clone <repository-url>
   cd DefectScannerAR
   ```

2. **Open Project**

   ```bash
   open DefectScannerAR.xcodeproj
   ```

3. **Configure Signing**

   - In Xcode, select the project in Navigator
   - Go to "Signing & Capabilities" tab
   - Select your Development Team
   - Xcode will automatically manage provisioning profiles

4. **Install Dependencies**

   - Dependencies are managed via Swift Package Manager (already configured)
   - Xcode will fetch `Swinject` automatically on first build

5. **Update Camera Permissions**

   - Camera permission is already configured in `Info.plist`
   - Key: `NSCameraUsageDescription`
   - Value: "AR scanning requires camera access to detect surfaces and capture defect images."

6. **Build & Run**
   - Connect your iOS device via USB
   - Select your device as the run destination
   - Press `Cmd + R` or click the Run button
   - Grant camera permissions when prompted

### First Run

1. Point device at a floor or table surface
2. Move device slowly to help ARKit detect planes
3. Follow on-screen coaching overlay instructions
4. Tap surface to place first defect marker
5. Enter description and save
6. Tap "Review Defects" to see list

## Architecture Overview

```
DefectScannerAR/
├── AR/                          # AR Engine Layer
│   ├── ARManager.swift          # Facade for AR services
│   ├── ARSessionManager.swift   # Session lifecycle, configuration
│   ├── ARMarkerService.swift    # Marker creation, manipulation
│   ├── ARRaycastService.swift   # Raycasting, position extraction
│   ├── ARCaptureService.swift   # Screenshot handling
│   ├── ARGestureHandler.swift   # Gesture recognition logic
│   └── ARContainerView.swift    # SwiftUI-ARKit bridge
├── Domain/
│   └── Models/
│       ├── Defect.swift         # Core defect model
│       └── ScanMode.swift       # Scan/Review mode enum
├── Presentation/
│   └── Scanner/
│       ├── ScannerView.swift    # Root navigation view
│       ├── ScanView.swift       # Scan mode UI
│       ├── ReviewView.swift     # Review mode UI
│       └── ViewModel/
│           ├── ScannerViewModel.swift  # MVI ViewModel
│           ├── ScannerState.swift      # App state
│           └── ScannerIntent.swift     # User actions
└── Infrastructure/
    └── DI/
        └── AppContainer.swift   # Dependency injection container
```

## Assumptions & Limitations

### Assumptions

- **Single-session usage**: App designed for one repair documentation session
- **Local storage only**: Defects stored in memory (lost on app restart)
- **iPhone-only**: Optimized for iOS, not cross-platform
- **Well-lit environments**: ARKit requires adequate lighting
- **Static scenes**: Best results when furniture/objects don't move during scan

### Known Limitations

#### Technical

- **No data persistence**: Defects cleared when app closes
- **Memory-only storage**: Large sessions (100+ defects) may impact performance
- **Screenshot quality**: Tied to device display resolution
- **Vertical plane detection**: May require 2-3 seconds of device movement on non-LiDAR devices

#### UX/Design

- **No undo**: Defect deletion is permanent (within session)
- **No editing**: Cannot edit defect description after saving
- **No export**: No PDF/share functionality
- **No measurement tools**: Only visual markers (no distance/area calculation)

#### Scope Reductions (Prototype)

- No backend/API integration
- No user authentication
- No multi-user collaboration
- No room-to-room navigation
- No floor plan generation

### Intentional Design Choices

- **Hollow markers**: Better visibility, less occlusion
- **Cyan color**: High contrast against most surfaces
- **Manual placement**: More control than auto-detection
- **Isolated screenshots**: Cleaner defect images for contractors

## Troubleshooting

### "Marker won't place on walls"

- Move device slowly around the wall for 2-3 seconds
- Enable Debug Mode (eye icon) to see plane detection
- Ensure adequate lighting
- LiDAR devices detect vertical planes faster

### "Screenshot appears empty in sheet"

- This should be fixed in latest version (main thread dispatch)
- If persists, wait 1 second after placing marker before tapping

### "App crashes on launch"

- Verify camera permissions in Settings > Privacy > Camera
- Ensure device supports ARKit (iPhone 6s or later)
- Check iOS version is 15.0+

## Development Notes

### Code Quality

This is a **proof-of-concept prototype** prioritizing functionality over production polish. The codebase includes:

- Clean architecture for maintainability
- MVI pattern for predictable state management
- Service composition for modularity
- Method length constraints (<10 lines) for readability

However, it lacks:

- Unit tests
- Error handling UI
- Comprehensive input validation
- Production logging/analytics
- Performance optimizations for large datasets

### Future Enhancements (Out of Scope)

- CoreData/SwiftData persistence
- Export to PDF with 3D model
- Measurements (distance, area)
- Room mesh capture via RoomPlan
- Contractor collaboration features
- AI-powered defect classification

## License

MIT License (or specify your license)

## Contact

[Your name/email for questions]
