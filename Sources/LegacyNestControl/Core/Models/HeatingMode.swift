import Foundation

enum HeatingMode: String, Codable, CaseIterable, Identifiable {
    case off
    case heat
    case cool
    case auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .heat: return "Heat"
        case .cool: return "Cool"
        case .auto: return "Auto"
        }
    }

    var supportsTargetRange: Bool {
        self == .auto
    }
}
