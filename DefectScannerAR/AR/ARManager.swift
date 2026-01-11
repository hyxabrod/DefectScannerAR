import ARKit
import RealityKit
import UIKit

class ARManager {
    // Services
    private let sessionManager: ARSessionManager
    private let raycastService: ARRaycastService
    private let markerService: ARMarkerService
    private let captureService: ARCaptureService

    // Expose ARView via SessionManager
    var arView: ARView { sessionManager.arView }

    init() {
        self.sessionManager = ARSessionManager()
        self.raycastService = ARRaycastService(arView: sessionManager.arView)
        self.markerService = ARMarkerService(arView: sessionManager.arView)
        self.captureService = ARCaptureService(arView: sessionManager.arView)
    }

    // MARK: - Lifecycle

    func setup() {
        sessionManager.setup()
    }

    func pause() {
        sessionManager.pause()
    }

    func setDebugOptions(enabled: Bool) {
        sessionManager.setDebugOptions(enabled: enabled)
    }

    // MARK: - Interaction

    func handleTap(at location: CGPoint) -> (SIMD3<Float>, UUID)? {
        guard let hitResult = raycastService.performRaycast(at: location) else { return nil }

        let anchorID = UUID()
        markerService.placeMarker(at: hitResult, id: anchorID)

        let position = raycastService.extractPosition(from: hitResult)
        return (position, anchorID)
    }

    func moveMarker(for anchorID: UUID, to location: CGPoint) {
        guard let result = raycastService.performRaycast(at: location) else { return }
        markerService.moveMarker(for: anchorID, to: result.worldTransform)
    }

    func scaleMarker(for anchorID: UUID, by factor: Float) {
        markerService.scaleMarker(for: anchorID, by: factor)
    }

    func resizeMarkerAbsolute(for anchorID: UUID, width: Float, depth: Float) {
        markerService.resizeMarkerAbsolute(for: anchorID, width: width, depth: depth)
    }

    func removeMarker(for anchorID: UUID) {
        markerService.removeMarker(for: anchorID)
    }

    func updateMarkerColor(for anchorID: UUID, color: UIColor) {
        markerService.updateMarkerColor(for: anchorID, color: color)
    }

    func setOtherMarkersHidden(except anchorID: UUID, hidden: Bool) {
        markerService.setOtherMarkersHidden(except: anchorID, hidden: hidden)
    }

    func highlightAnchor(withID id: UUID) {
        markerService.highlightAnchor(withID: id)
    }

    func findAnchorID(for entity: Entity) -> UUID? {
        return markerService.findAnchorID(for: entity)
    }

    // MARK: - Capture

    func takeScreenshot(completion: @escaping (UIImage) -> Void) {
        captureService.takeScreenshot(completion: completion)
    }
}
