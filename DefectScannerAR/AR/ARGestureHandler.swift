import ARKit
import RealityKit
import SwiftUI
import UIKit

class ARGestureHandler: NSObject {
    private let arManager: ARManager
    private weak var view: UIView?  // Keep weak reference to view for feedback generators

    // Bindings or Callbacks
    var isDraggingToDelete: Binding<Bool>
    var onDefectDetected: ((SIMD3<Float>, UIImage, UUID) -> Void)?
    var onDefectDeleted: ((UUID) -> Void)?
    var onDefectUpdated: ((UUID, UIImage) -> Void)?

    // State
    private var draggedAnchorID: UUID?
    private var pinchedAnchorID: UUID?

    // Drag-to-size state
    private var drawingAnchorID: UUID?
    private var drawStartPoint: CGPoint?
    private var drawStartWorldPos: SIMD3<Float>?

    init(arManager: ARManager, isDraggingToDelete: Binding<Bool>) {
        self.arManager = arManager
        self.isDraggingToDelete = isDraggingToDelete
        super.init()
    }

    func setView(_ view: UIView) {
        self.view = view
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        // Ignore taps if dragging
        guard !isDraggingToDelete.wrappedValue else { return }

        guard let arView = gesture.view as? ARView else { return }
        let location = gesture.location(in: arView)

        if let (position, anchorID) = arManager.handleTap(at: location) {
            // Haptic Feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            // Isolate the new marker for the screenshot
            arManager.setOtherMarkersHidden(except: anchorID, hidden: true)

            // Small delay to ensure render update if needed, or just capture
            // In practice, snapshot() usually captures the current scene state.
            // If we run into race conditions (old frame), we might need loose delay.
            // Trying immediate first.
            arManager.takeScreenshot { [weak self, weak arManager] image in
                // Restore visibility
                DispatchQueue.main.async {
                    arManager?.setOtherMarkersHidden(except: anchorID, hidden: false)
                    self?.onDefectDetected?(position, image, anchorID)
                }
            }
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let arView = gesture.view as? ARView else { return }

        switch gesture.state {
        case .began:
            let location = gesture.location(in: arView)
            if let result = arView.hitTest(location).first,
                let anchorID = arManager.findAnchorID(for: result.entity)
            {
                pinchedAnchorID = anchorID
            }
        case .changed:
            guard let anchorID = pinchedAnchorID else { return }
            let scale = Float(gesture.scale)
            arManager.scaleMarker(for: anchorID, by: scale)
            gesture.scale = 1.0
        case .ended:
            guard let anchorID = pinchedAnchorID else { return }
            // Capture new screenshot
            arManager.setOtherMarkersHidden(except: anchorID, hidden: true)
            arManager.takeScreenshot { [weak self] image in
                DispatchQueue.main.async {
                    self?.arManager.setOtherMarkersHidden(except: anchorID, hidden: false)
                    self?.onDefectUpdated?(anchorID, image)
                }
            }
            pinchedAnchorID = nil
        default:
            pinchedAnchorID = nil
        }
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let arView = gesture.view as? ARView else { return }
        let location = gesture.location(in: arView)

        switch gesture.state {
        case .began:
            handleDragBegan(in: arView, location: location)

        case .changed:
            handleDragChanged(location: location)

        case .ended, .cancelled:
            handleDragEnded(in: arView, location: location)

        default: break
        }
    }

    private func handleDragBegan(in arView: ARView, location: CGPoint) {
        let hitResults = arView.hitTest(location)
        if let firstHit = hitResults.first,
            let anchorID = arManager.findAnchorID(for: firstHit.entity)
        {
            isDraggingToDelete.wrappedValue = true
            draggedAnchorID = anchorID

            arManager.updateMarkerColor(for: anchorID, color: .red)

            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }

    private func handleDragChanged(location: CGPoint) {
        guard let anchorID = draggedAnchorID else { return }
        arManager.moveMarker(for: anchorID, to: location)
    }

    private func handleDragEnded(in arView: ARView, location: CGPoint) {
        guard let anchorID = draggedAnchorID else { return }

        let trashZone = calculateTrashZone(in: arView)

        if trashZone.contains(location) {
            arManager.removeMarker(for: anchorID)
            onDefectDeleted?(anchorID)

            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        } else {
            arManager.updateMarkerColor(for: anchorID, color: .cyan)
        }

        isDraggingToDelete.wrappedValue = false
        draggedAnchorID = nil
    }
    private func calculateTrashZone(in view: UIView) -> CGRect {
        let screenHeight = view.bounds.height
        let screenWidth = view.bounds.width
        return CGRect(
            x: (screenWidth / 2) - 50,
            y: screenHeight - 150,
            width: 100,
            height: 150
        )
    }

    // MARK: - Drag-to-Size Gesture

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard !isDraggingToDelete.wrappedValue else { return }
        guard let arView = gesture.view as? ARView else { return }

        let location = gesture.location(in: arView)

        switch gesture.state {
        case .began: handlePanBegan(at: location)
        case .changed: handlePanChanged(from: drawStartPoint, to: location, in: arView)
        case .ended: handlePanEnded()
        default: cleanupDrawState()
        }
    }

    private func handlePanBegan(at location: CGPoint) {
        drawStartPoint = location
    }

    private func handlePanChanged(from start: CGPoint?, to current: CGPoint, in arView: ARView) {
        guard let startPoint = start else { return }
        guard meetsMinimumDragDistance(from: startPoint, to: current) else { return }

        if drawingAnchorID == nil {
            createDrawingMarker(at: startPoint)
        }
        updateDrawingMarkerSize(from: startPoint, to: current, in: arView)
    }

    private func meetsMinimumDragDistance(from start: CGPoint, to end: CGPoint) -> Bool {
        let distance = hypot(end.x - start.x, end.y - start.y)
        return distance > 20
    }

    private func createDrawingMarker(at point: CGPoint) {
        guard let (position, anchorID) = arManager.handleTap(at: point) else { return }
        drawingAnchorID = anchorID
        drawStartWorldPos = position
        arManager.updateMarkerColor(for: anchorID, color: .yellow)

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func updateDrawingMarkerSize(from start: CGPoint, to end: CGPoint, in arView: ARView) {
        guard let anchorID = drawingAnchorID else { return }
        let size = calculateMarkerSize(from: start, to: end, in: arView)
        arManager.resizeMarkerAbsolute(for: anchorID, width: size.width, depth: size.depth)
    }

    private func handlePanEnded() {
        guard let anchorID = drawingAnchorID else {
            cleanupDrawState()
            return
        }
        finalizeDrawingMarker(anchorID)
        cleanupDrawState()
    }

    private func finalizeDrawingMarker(_ anchorID: UUID) {
        arManager.updateMarkerColor(for: anchorID, color: .cyan)
        arManager.setOtherMarkersHidden(except: anchorID, hidden: true)

        captureAndNotify(for: anchorID)
    }

    private func captureAndNotify(for anchorID: UUID) {
        arManager.takeScreenshot { [weak self] image in
            DispatchQueue.main.async {
                self?.arManager.setOtherMarkersHidden(except: anchorID, hidden: false)
                if let position = self?.drawStartWorldPos {
                    self?.onDefectDetected?(position, image, anchorID)
                }
            }
        }
    }

    private func calculateMarkerSize(from start: CGPoint, to end: CGPoint, in arView: ARView) -> (
        width: Float, depth: Float
    ) {
        // Calculate screen distance
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)

        // Convert to world scale (approximate)
        // Assuming average marker distance of 1.5m from camera
        let worldScaleFactor: Float = 0.002  // Empirical value
        let worldSize = Float(distance) * worldScaleFactor

        // Clamp between 10cm and 1m
        let size = max(0.1, min(1.0, worldSize))

        return (width: size, depth: size)
    }

    private func cleanupDrawState() {
        drawingAnchorID = nil
        drawStartPoint = nil
        drawStartWorldPos = nil
    }
}
