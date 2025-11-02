import Combine
import Foundation

protocol ThermostatDiscoveryServicing {
    var devicesPublisher: AnyPublisher<[ThermostatDevice], Never> { get }
    func startDiscovery()
    func stopDiscovery()
    func addManualDevice(host: String, port: Int, name: String) async
}

protocol ThermostatControlServicing {
    func observeDeviceState(deviceID: UUID) -> AnyPublisher<ThermostatState, Never>
    func fetchCurrentStates() async -> [ThermostatState]
    func setTargetTemperature(_ value: Double, for deviceID: UUID) async throws
    func setTargetRange(low: Double, high: Double, for deviceID: UUID) async throws
    func setMode(_ mode: HeatingMode, for deviceID: UUID) async throws
    func fetchSchedule(for deviceID: UUID) async throws -> ThermostatSchedule
    func applySchedule(_ schedule: ThermostatSchedule, for deviceID: UUID) async throws
}
