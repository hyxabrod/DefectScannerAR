import SwiftUI

struct ReviewView: View {
    @ObservedObject var viewModel: ScannerViewModel
    let arManager: ARManager
    @State private var selectedDefect: Defect?

    var body: some View {
        VStack {
            Text("Review Defects")
                .font(.title)
                .padding(.top)

            if viewModel.state.defects.isEmpty {
                Spacer()
                Text("No defects recorded.")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List(viewModel.state.defects) { defect in
                    Button(action: {
                        arManager.highlightAnchor(withID: defect.anchorID)
                        viewModel.dispatch(.switchMode(.scan))
                    }) {
                        HStack(spacing: 12) {
                            Image(uiImage: defect.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8).stroke(
                                        Color.gray.opacity(0.3), lineWidth: 1))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(defect.description)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("\(defect.timestamp, formatter: dateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }

            Button(action: {
                viewModel.dispatch(.switchMode(.scan))
            }) {
                Text("Back to Scan")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }
}
