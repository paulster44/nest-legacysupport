import Combine
import Foundation

enum ThermostatControlError: Error {
    case deviceNotFound
}

final class MockThermostatControlService: ThermostatControlServicing {
    private var stateSubjects: [UUID: CurrentValueSubject<ThermostatState, Never>] = [:]
    private let scheduleStore: ScheduleStoring

    init(
        initialStates: [ThermostatState] = MockThermostatControlService.sampleStates,
        scheduleStore: ScheduleStoring
    ) {
        self.scheduleStore = scheduleStore
        for state in initialStates {
            stateSubjects[state.id] = CurrentValueSubject(state)
        }
    }

    func observeDeviceState(deviceID: UUID) -> AnyPublisher<ThermostatState, Never> {
        subject(for: deviceID).eraseToAnyPublisher()
    }

    func fetchCurrentStates() async -> [ThermostatState] {
        stateSubjects.values.map { $0.value }
    }

    func setTargetTemperature(_ value: Double, for deviceID: UUID) async throws {
        try updateState(deviceID: deviceID) { state in
            state.targetTemperatureC = value
            state.targetLowC = nil
            state.targetHighC = nil
            state.updatedAt = .now
        }
    }

    func setTargetRange(low: Double, high: Double, for deviceID: UUID) async throws {
        try updateState(deviceID: deviceID) { state in
            state.targetLowC = low
            state.targetHighC = high
            state.updatedAt = .now
        }
    }

    func setMode(_ mode: HeatingMode, for deviceID: UUID) async throws {
        try updateState(deviceID: deviceID) { state in
            state.mode = mode
            state.updatedAt = .now
        }
    }

    func fetchSchedule(for deviceID: UUID) async throws -> ThermostatSchedule {
        scheduleStore.loadSchedule(for: deviceID)
    }

    func applySchedule(_ schedule: ThermostatSchedule, for deviceID: UUID) async throws {
        scheduleStore.saveSchedule(schedule)
        // TODO: Bind to LAN schedule update endpoint once available.
    }

    private func subject(for deviceID: UUID) -> CurrentValueSubject<ThermostatState, Never> {
        if let subject = stateSubjects[deviceID] {
            return subject
        }
        let device = ThermostatDevice(id: deviceID, name: "Unknown", host: "0.0.0.0", port: 0)
        let state = ThermostatState(
            device: device,
            ambientTemperatureC: 20,
            targetTemperatureC: 21,
            humidity: 40,
            mode: .heat
        )
        let subject = CurrentValueSubject(state)
        stateSubjects[deviceID] = subject
        return subject
    }

    private func updateState(deviceID: UUID, _ transform: (inout ThermostatState) -> Void) throws {
        guard let subject = stateSubjects[deviceID] else { throw ThermostatControlError.deviceNotFound }
        var state = subject.value
        transform(&state)
        subject.send(state)
    }
}

private extension MockThermostatControlService {
    static var sampleStates: [ThermostatState] {
        MockThermostatDiscoveryService.defaultDevices.map { device in
            ThermostatState(
                device: device,
                ambientTemperatureC: 21.0,
                targetTemperatureC: 22.0,
                targetLowC: 20.0,
                targetHighC: 24.0,
                humidity: 45,
                mode: .auto
            )
        }
    }
}
