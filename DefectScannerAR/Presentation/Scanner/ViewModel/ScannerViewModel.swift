import Combine
import Foundation
import UIKit

class ScannerViewModel: ObservableObject {
    @Published private(set) var state: ScannerState

    init(initialState: ScannerState = ScannerState()) {
        self.state = initialState
    }

    func dispatch(_ intent: ScannerIntent) {
        switch intent {
        case .addDefect(let defect):
            addDefect(defect)
        case .deleteDefect(let anchorID):
            deleteDefect(anchorID)
        case .switchMode(let mode):
            switchMode(mode)
        case .updateDefectImage(let id, let image):
            updateDefectImage(id: id, image: image)
        }
    }

    private func addDefect(_ defect: Defect) {
        state.defects.append(defect)
    }

    private func deleteDefect(_ anchorID: UUID) {
        state.defects.removeAll { $0.anchorID == anchorID }
    }

    private func switchMode(_ mode: ScanMode) {
        state.mode = mode
    }

    private func updateDefectImage(id: UUID, image: UIImage) {
        if let index = state.defects.firstIndex(where: { $0.anchorID == id }) {
            var defect = state.defects[index]
            defect.image = image
            state.defects[index] = defect
        }
    }
}
