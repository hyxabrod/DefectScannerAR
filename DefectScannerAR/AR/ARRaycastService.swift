import ARKit
import RealityKit

class ARRaycastService {
    private let arView: ARView

    init(arView: ARView) {
        self.arView = arView
    }

    func performRaycast(at location: CGPoint) -> ARRaycastResult? {
        // CRITICAL: estimatedPlane ALWAYS returns horizontal alignment!
        // For vertical walls, ONLY use detected planes (.existingPlaneGeometry or .existingPlaneInfinite)

        // Try VERTICAL surfaces first (detected planes only!)
        let verticalTargets: [ARRaycastQuery.Target] = [
            .existingPlaneGeometry,
            .existingPlaneInfinite,
        ]

        for target in verticalTargets {
            if let query = arView.makeRaycastQuery(
                from: location, allowing: target, alignment: .vertical),
                let result = arView.session.raycast(query).first
            {
                print(
                    "🎯 VERTICAL hit: target=\(target), result.targetAlignment=\(result.targetAlignment)"
                )
                return result
            }
        }

        // Then try HORIZONTAL surfaces (with estimation fallback)
        let horizontalTargets: [ARRaycastQuery.Target] = [
            .existingPlaneGeometry,
            .existingPlaneInfinite,
            .estimatedPlane,  // Estimation only works for horizontal
        ]

        for target in horizontalTargets {
            if let query = arView.makeRaycastQuery(
                from: location, allowing: target, alignment: .horizontal),
                let result = arView.session.raycast(query).first
            {
                print(
                    "🎯 HORIZONTAL hit: target=\(target), result.targetAlignment=\(result.targetAlignment)"
                )
                return result
            }
        }

        return nil
    }

    func extractPosition(from result: ARRaycastResult) -> SIMD3<Float> {
        return SIMD3<Float>(
            result.worldTransform.columns.3.x,
            result.worldTransform.columns.3.y,
            result.worldTransform.columns.3.z
        )
    }
}
