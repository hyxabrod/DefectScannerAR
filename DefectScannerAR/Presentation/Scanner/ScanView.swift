import SwiftUI

struct ScanView: View {
    @ObservedObject var viewModel: ScannerViewModel
    let arManager: ARManager

    init(viewModel: ScannerViewModel, arManager: ARManager) {
        self.viewModel = viewModel
        self.arManager = arManager
    }

    @State private var pendingDefectImage: UIImage?
    @State private var pendingDefectPosition: SIMD3<Float>?
    @State private var pendingAnchorID: UUID?
    @State private var defectDescription: String = ""
    @State private var isShowingDefectSheet: Bool = false
    @State private var isDebugMode: Bool = false
    @State private var isDraggingToDelete: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ARContainerView(
                arManager: arManager,
                isDebugMode: isDebugMode,
                isDraggingToDelete: $isDraggingToDelete,
                onDefectDetected: { position, image, anchorID in
                    pendingDefectPosition = position
                    pendingDefectImage = image
                    pendingAnchorID = anchorID
                    isShowingDefectSheet = true
                },
                onDefectDeleted: { anchorID in
                    viewModel.dispatch(.deleteDefect(anchorID))
                },
                onDefectUpdated: { anchorID, image in
                    viewModel.dispatch(.updateDefectImage(anchorID, image))
                }
            )
            .edgesIgnoringSafeArea(.all)

            // Trash Overlay Logic
            if isDraggingToDelete {
                DeleteDefectOverlay()
            }

            // Normal UI (Buttons) - Hide when dragging
            if !isDraggingToDelete {
                ScanControlOverlay(
                    defectCount: viewModel.state.defects.count,
                    isDebugMode: $isDebugMode,
                    onReviewTap: {
                        viewModel.dispatch(.switchMode(.review))
                    }
                )
            }
        }

        .sheet(
            isPresented: $isShowingDefectSheet,
            onDismiss: {
                // If we dismissed but didn't save (pending vars still set), clean up
                if let anchorID = pendingAnchorID {
                    arManager.removeMarker(for: anchorID)
                    cleanupPendingState()
                }
            }
        ) {
            NavigationView {
                VStack {
                    if let image = pendingDefectImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                            .padding()
                    }

                    TextField("Enter Description", text: $defectDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Spacer()
                }
                .navigationTitle("New Defect")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        // Explicit cancel
                        if let anchorID = pendingAnchorID {
                            arManager.removeMarker(for: anchorID)
                        }
                        cleanupPendingState()
                        isShowingDefectSheet = false
                    },
                    trailing: Button("Save") {
                        saveDefect()
                    }
                )
            }
        }
    }

    private func saveDefect() {
        if let position = pendingDefectPosition, let image = pendingDefectImage,
            let anchorID = pendingAnchorID
        {
            let newDefect = Defect(
                id: UUID(),
                anchorID: anchorID,
                position: position,
                description: defectDescription.isEmpty ? "New Defect" : defectDescription,
                image: image,
                timestamp: Date()
            )
            viewModel.dispatch(.addDefect(newDefect))
        }

        // Successfully saved, just clear state without removing marker
        cleanupPendingState()
        isShowingDefectSheet = false
    }

    private func cleanupPendingState() {
        defectDescription = ""
        pendingDefectImage = nil
        pendingDefectPosition = nil
        pendingAnchorID = nil
    }
}

// MARK: - Subviews

struct DeleteDefectOverlay: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "trash.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
                .padding()
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.red, lineWidth: 2)
                )
                .padding(.bottom, 50)
        }
        .transition(.opacity)
        .zIndex(2)
    }
}

struct ScanControlOverlay: View {
    let defectCount: Int
    @Binding var isDebugMode: Bool
    let onReviewTap: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Stats & Review Button
            VStack {
                Text("Defects: \(defectCount)")
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)

                Button(action: onReviewTap) {
                    Text("Review Defects")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)  // Center horizontally

            // Debug Toggle (Top Right relative to this overlay, but we want it nicely positioned)
            // The original code had nested VStacks/HStacks. Let's replicate simply.
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isDebugMode.toggle()
                    }) {
                        Image(systemName: isDebugMode ? "eye.fill" : "eye.slash.fill")
                            .padding()
                            .background(Color.gray.opacity(0.7))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
