import Foundation
import UIKit

enum ScannerIntent {
    case addDefect(Defect)
    case deleteDefect(UUID)
    case updateDefectImage(UUID, UIImage)
    case switchMode(ScanMode)
}
