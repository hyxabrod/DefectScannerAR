import ARKit
import RealityKit
import UIKit

class ARCaptureService {
    private let arView: ARView

    init(arView: ARView) {
        self.arView = arView
    }

    func takeScreenshot(completion: @escaping (UIImage) -> Void) {
        arView.snapshot(saveToHDR: false) { image in
            guard let image = image else { return }
            completion(image)
        }
    }
}
