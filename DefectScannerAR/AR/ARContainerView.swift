import ARKit
import RealityKit
import SwiftUI
import UIKit

struct ARContainerView: UIViewRepresentable {
    let arManager: ARManager
    var isDebugMode: Bool = false
    @Binding var isDraggingToDelete: Bool
    let onDefectDetected: (SIMD3<Float>, UIImage, UUID) -> Void
    var onDefectDeleted: ((UUID) -> Void)? = nil
    var onDefectUpdated: ((UUID, UIImage) -> Void)? = nil

    init(
        arManager: ARManager,
        isDebugMode: Bool = false,
        isDraggingToDelete: Binding<Bool>,
        onDefectDetected: @escaping (SIMD3<Float>, UIImage, UUID) -> Void,
        onDefectDeleted: ((UUID) -> Void)? = nil,
        onDefectUpdated: ((UUID, UIImage) -> Void)? = nil
    ) {
        self.arManager = arManager
        self.isDebugMode = isDebugMode
        self._isDraggingToDelete = isDraggingToDelete
        self.onDefectDetected = onDefectDetected
        self.onDefectDeleted = onDefectDeleted
        self.onDefectUpdated = onDefectUpdated
    }

    func makeUIView(context: Context) -> ARView {
        let arView = arManager.arView
        arManager.setup()

        setupCoachingOverlay(in: arView, context: context)
        setupGestures(in: arView, context: context)

        return arView
    }

    private func setupCoachingOverlay(in arView: ARView, context: Context) {
        guard !arView.subviews.contains(where: { $0 is ARCoachingOverlayView }) else { return }

        let overlay = ARCoachingOverlayView()
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.session = arView.session
        overlay.goal = .horizontalPlane
        overlay.delegate = context.coordinator
        arView.addSubview(overlay)
    }

    private func setupGestures(in arView: ARView, context: Context) {
        arView.gestureRecognizers?.removeAll()
        let handler = context.coordinator.gestureHandler
        handler.setView(arView)

        addTapGesture(to: arView, handler: handler)
        addPanGesture(to: arView, handler: handler)
        addLongPressGesture(to: arView, handler: handler)
        addPinchGesture(to: arView, handler: handler)
    }

    private func addTapGesture(to arView: ARView, handler: ARGestureHandler) {
        let tap = UITapGestureRecognizer(
            target: handler,
            action: #selector(ARGestureHandler.handleTap(_:))
        )
        arView.addGestureRecognizer(tap)
    }

    private func addPanGesture(to arView: ARView, handler: ARGestureHandler) {
        let pan = UIPanGestureRecognizer(
            target: handler,
            action: #selector(ARGestureHandler.handlePan(_:))
        )
        arView.addGestureRecognizer(pan)
    }

    private func addLongPressGesture(to arView: ARView, handler: ARGestureHandler) {
        let lp = UILongPressGestureRecognizer(
            target: handler,
            action: #selector(ARGestureHandler.handleLongPress(_:))
        )
        lp.minimumPressDuration = 0.5
        arView.addGestureRecognizer(lp)
    }

    private func addPinchGesture(to arView: ARView, handler: ARGestureHandler) {
        let pinch = UIPinchGestureRecognizer(
            target: handler,
            action: #selector(ARGestureHandler.handlePinch(_:))
        )
        arView.addGestureRecognizer(pinch)
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        arManager.setDebugOptions(enabled: isDebugMode)
        // Update bindings in handler if needed
        context.coordinator.gestureHandler.isDraggingToDelete = _isDraggingToDelete
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, ARCoachingOverlayViewDelegate {
        var parent: ARContainerView
        let gestureHandler: ARGestureHandler

        init(parent: ARContainerView) {
            self.parent = parent
            // Initialize Handler
            self.gestureHandler = ARGestureHandler(
                arManager: parent.arManager, isDraggingToDelete: parent.$isDraggingToDelete)
            // Hook up callbacks
            self.gestureHandler.onDefectDetected = parent.onDefectDetected
            self.gestureHandler.onDefectDeleted = parent.onDefectDeleted
            self.gestureHandler.onDefectUpdated = parent.onDefectUpdated
        }

        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            coachingOverlayView.activatesAutomatically = false
        }
    }
}
