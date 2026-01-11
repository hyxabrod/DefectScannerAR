import ARKit
import RealityKit
import SwiftUI

class ARSessionManager {
    // Persistent ARView
    lazy var arView: ARView = {
        let view = ARView(frame: .zero)
        return view
    }()

    private var isConfigured = false

    func setup() {
        guard !isConfigured else {
            // Resume if already configured
            if let config = arView.session.configuration {
                arView.session.run(config)
            }
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        // LiDAR Support
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }

        arView.session.run(configuration)
        isConfigured = true
    }

    func pause() {
        arView.session.pause()
    }

    func setDebugOptions(enabled: Bool) {
        if enabled {
            arView.debugOptions = [.showFeaturePoints, .showWorldOrigin, .showSceneUnderstanding]
        } else {
            arView.debugOptions = []
        }
    }
}
