import SwiftUI

struct ScannerView: View {
    @ObservedObject var viewModel: ScannerViewModel
    let arManager: ARManager

    init(viewModel: ScannerViewModel, arManager: ARManager) {
        self.viewModel = viewModel
        self.arManager = arManager
    }

    var body: some View {
        ZStack {
            if viewModel.state.mode == .scan {
                ScanView(viewModel: viewModel, arManager: arManager)
            } else {
                ReviewView(viewModel: viewModel, arManager: arManager)
            }
        }
    }
}
