//
//  DefectScannerARApp.swift
//  DefectScannerAR
//
//  Created by Maksim Kolotsai on 05.01.2026.
//

import SwiftUI
import Swinject

@main
struct DefectScannerARApp: App {
    let viewModel: ScannerViewModel
    let arManager: ARManager

    init() {
        let container = AppContainer.shared.container
        self.viewModel = container.resolve(ScannerViewModel.self)!
        self.arManager = container.resolve(ARManager.self)!
    }

    var body: some Scene {
        WindowGroup {
            ScannerView(viewModel: viewModel, arManager: arManager)
        }
    }
}
