import Foundation
import UIKit

struct Defect: Identifiable {
    let id: UUID
    let anchorID: UUID
    var position: SIMD3<Float>
    var description: String
    var image: UIImage
    var timestamp: Date
}
