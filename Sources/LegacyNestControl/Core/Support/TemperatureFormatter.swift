import Foundation

struct TemperatureFormatter {
    enum Unit: String, CaseIterable, Identifiable {
        case celsius
        case fahrenheit

        var id: String { rawValue }

        var measurementUnit: UnitTemperature {
            switch self {
            case .celsius: return .celsius
            case .fahrenheit: return .fahrenheit
            }
        }
    }

    var unit: Unit

    init(unit: Unit = .celsius) {
        self.unit = unit
    }

    func string(fromCelsius value: Double) -> String {
        let measurement = Measurement(value: value, unit: UnitTemperature.celsius)
        let converted = measurement.converted(to: unit.measurementUnit)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 0
        formatter.unitOptions = .temperatureWithoutUnit
        return formatter.string(from: converted)
    }
}
