import Foundation
import Swinject

class AppContainer {
    static let shared = AppContainer()
    let container = Container()

    private init() {
        setup()
    }

    func setup() {
        // Register ARManager as a singleton
        container.register(ARManager.self) { _ in
            ARManager()
        }.inObjectScope(.container)

        // Register ScannerViewModel
        container.register(ScannerViewModel.self) { _ in
            ScannerViewModel()
        }.inObjectScope(.container)
    }
}
