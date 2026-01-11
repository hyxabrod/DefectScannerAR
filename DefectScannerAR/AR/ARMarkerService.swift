import ARKit
import RealityKit
import UIKit

class ARMarkerService {
    private let arView: ARView
    private var anchors: [UUID: AnchorEntity] = [:]

    init(arView: ARView) {
        self.arView = arView
    }

    // MARK: - Core Logic

    func placeMarker(at result: ARRaycastResult, id: UUID) {
        let anchor = AnchorEntity(world: result.worldTransform)
        anchor.name = id.uuidString

        let markerEntity = createMarkerEntity()

        // Use targetAlignment from ARRaycastResult - Apple's explicit surface type indicator
        // This is the most reliable method per documentation
        let isVerticalSurface = (result.targetAlignment == .vertical)

        // RealityKit planes default to XZ (horizontal)
        // For walls, rotate -90° around X-axis to stand the plane up vertically
        print("🔍 ARMarkerService: targetAlignment = \(result.targetAlignment)")
        // For walls, rotate plane to stand vertically
        // Try Z-axis rotation if X doesn't work
//        if result.targetAlignment == .vertical {
//            print("✅ vv_vv Applying VERTICAL rotation (X-axis +90°)")
//            markerEntity.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [0, 0, 1])
//        } else {
//            print("❌ aa_aa Surface is NOT vertical, alignment: \(result.targetAlignment)")
//        }

        anchor.addChild(markerEntity)

        arView.scene.addAnchor(anchor)
        anchors[id] = anchor

        // Install Gestures for the marker
        // We handle gestures manually (Tap, LongPress, Panning)
        // arView.installGestures([.all], for: markerEntity)
    }

    func moveMarker(for id: UUID, to transform: simd_float4x4) {
        guard let anchor = anchors[id] else { return }
        anchor.move(to: transform, relativeTo: nil)
    }

    func scaleMarker(for id: UUID, by factor: Float) {
        guard let anchor = anchors[id] else { return }
        if let root = anchor.children.first as? ModelEntity {
            let currentScale = root.scale
            root.scale = currentScale * factor
        }
    }

    func resizeMarkerAbsolute(for id: UUID, width: Float, depth: Float) {
        guard let anchor = anchors[id] else { return }
        if let root = anchor.children.first as? ModelEntity {
            // Calculate scale factors from base 0.2m size
            let scaleX = width / 0.2
            let scaleZ = depth / 0.2
            root.scale = SIMD3<Float>(scaleX, 1.0, scaleZ)
        }
    }

    func removeMarker(for id: UUID) {
        guard let anchor = anchors[id] else { return }
        arView.scene.removeAnchor(anchor)
        anchors.removeValue(forKey: id)
    }

    func highlightAnchor(withID id: UUID) {
        for (_, anchor) in anchors {
            resetMarkerAppearance(anchor)
        }

        guard let anchor = anchors[id] else { return }
        highlightMarkerAppearance(anchor)
    }

    func updateMarkerColor(for id: UUID, color: UIColor) {
        guard let anchor = anchors[id] else { return }
        updateAnchorColor(anchor, color: color)
    }

    func findAnchorID(for entity: Entity) -> UUID? {
        var current: Entity? = entity
        while let node = current {
            if let anchor = node as? AnchorEntity, let uuid = UUID(uuidString: anchor.name) {
                return uuid
            }
            current = node.parent
        }
        return nil
    }

    func setOtherMarkersHidden(except id: UUID, hidden: Bool) {
        for (key, anchor) in anchors {
            if key != id {
                anchor.isEnabled = !hidden
            }
        }
    }


    private func createMarkerEntity() -> ModelEntity {
        // Marker dimensions are consistent for all surfaces (floor, walls)
        let width: Float = 0.2  // 20cm square
        let depth: Float = 0.2  // 20cm square
        let thickness: Float = 0.005

        let rootEntity = createRootPlane(width: width, depth: depth)
        let borderMaterial = createBorderMaterial()

        addBorders(
            to: rootEntity, width: width, depth: depth, thickness: thickness,
            material: borderMaterial)

        rootEntity.generateCollisionShapes(recursive: false)
        return rootEntity
    }

    private func createRootPlane(width: Float, depth: Float) -> ModelEntity {
        let rootMesh = MeshResource.generatePlane(width: width, depth: depth)
        let clearMaterial = SimpleMaterial(
            color: .white.withAlphaComponent(0.01), isMetallic: false)
        return ModelEntity(mesh: rootMesh, materials: [clearMaterial])
    }

    private func createBorderMaterial() -> SimpleMaterial {
        return SimpleMaterial(color: .cyan, isMetallic: false)
    }

    private func addBorders(
        to entity: ModelEntity, width: Float, depth: Float, thickness: Float,
        material: SimpleMaterial
    ) {
        let halfWidth = width / 2
        let halfDepth = depth / 2

        let borders = [
            createBorder(
                size: [width, thickness, thickness], position: [0, 0, -halfDepth],
                material: material),
            createBorder(
                size: [width, thickness, thickness], position: [0, 0, halfDepth], material: material
            ),
            createBorder(
                size: [thickness, thickness, depth], position: [-halfWidth, 0, 0],
                material: material),
            createBorder(
                size: [thickness, thickness, depth], position: [halfWidth, 0, 0], material: material
            ),
        ]

        borders.forEach { entity.addChild($0) }
    }

    private func createBorder(size: SIMD3<Float>, position: SIMD3<Float>, material: SimpleMaterial)
        -> ModelEntity
    {
        let mesh = MeshResource.generateBox(size: size)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.position = position
        return entity
    }

    private func updateAnchorColor(_ anchor: AnchorEntity, color: UIColor) {
        guard let root = anchor.children.first as? ModelEntity else { return }
        let material = SimpleMaterial(color: color, isMetallic: false)

        for child in root.children {
            if let border = child as? ModelEntity {
                border.model?.materials = [material]
            }
        }
    }

    private func resetMarkerAppearance(_ anchor: AnchorEntity) {
        updateAnchorColor(anchor, color: .cyan)
    }

    private func highlightMarkerAppearance(_ anchor: AnchorEntity) {
        updateAnchorColor(anchor, color: .yellow)
    }
}
