import Foundation

enum WeightUnit: String, Codable, CaseIterable, Identifiable, RawRepresentable {
    case kg
    case lbs

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kg: return "Kilograms"
        case .lbs: return "Pounds"
        }
    }

    var abbreviation: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }

    func convert(fromKg kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lbs: return kg * 2.20462
        }
    }

    func convertToKg(from value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lbs: return value / 2.20462
        }
    }
}
