import Foundation

struct ThermostatDevice: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var lastSeen: Date

    init(id: UUID = UUID(), name: String, host: String, port: Int, lastSeen: Date = .now) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.lastSeen = lastSeen
    }
}

struct ThermostatState: Identifiable, Codable, Equatable {
    let id: UUID
    var device: ThermostatDevice
    var ambientTemperatureC: Double
    var targetTemperatureC: Double
    var targetLowC: Double?
    var targetHighC: Double?
    var humidity: Double
    var mode: HeatingMode
    var isOnline: Bool
    var updatedAt: Date

    init(
        device: ThermostatDevice,
        ambientTemperatureC: Double,
        targetTemperatureC: Double,
        targetLowC: Double? = nil,
        targetHighC: Double? = nil,
        humidity: Double,
        mode: HeatingMode,
        isOnline: Bool = true,
        updatedAt: Date = .now
    ) {
        self.id = device.id
        self.device = device
        self.ambientTemperatureC = ambientTemperatureC
        self.targetTemperatureC = targetTemperatureC
        self.targetLowC = targetLowC
        self.targetHighC = targetHighC
        self.humidity = humidity
        self.mode = mode
        self.isOnline = isOnline
        self.updatedAt = updatedAt
    }

    var displayName: String { device.name }

    func temperatureMeasurement(for value: Double) -> Measurement<UnitTemperature> {
        Measurement(value: value, unit: .celsius)
    }
}
