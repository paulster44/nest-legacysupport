import Combine
import Foundation

@MainActor
final class DeviceListViewModel: ObservableObject {
    @Published var states: [ThermostatState] = []
    @Published var isDiscovering = false
    @Published var showingManualEntry = false

    let controlService: ThermostatControlServicing
    let scheduleStore: ScheduleStoring

    private let discoveryService: ThermostatDiscoveryServicing
    private var cancellables: Set<AnyCancellable> = []
    private var stateSubscriptions: [UUID: AnyCancellable] = [:]

    init(
        discoveryService: ThermostatDiscoveryServicing,
        controlService: ThermostatControlServicing,
        scheduleStore: ScheduleStoring
    ) {
        self.discoveryService = discoveryService
        self.controlService = controlService
        self.scheduleStore = scheduleStore
        bind()
    }

    func start() {
        guard !isDiscovering else { return }
        isDiscovering = true
        discoveryService.startDiscovery()
        Task { await loadInitialStates() }
    }

    func stop() {
        discoveryService.stopDiscovery()
        isDiscovering = false
    }

    func addManualDevice(host: String, port: Int, name: String) async {
        await discoveryService.addManualDevice(host: host, port: port, name: name)
    }

    func schedule(for deviceID: UUID) -> ThermostatSchedule {
        scheduleStore.loadSchedule(for: deviceID)
    }

    private func bind() {
        discoveryService.devicesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                guard let self else { return }
                Task { await self.syncStates(with: devices) }
            }
            .store(in: &cancellables)
    }

    private func loadInitialStates() async {
        let current = await controlService.fetchCurrentStates()
        await MainActor.run {
            states = current
        }
    }

    private func syncStates(with devices: [ThermostatDevice]) async {
        let current = await controlService.fetchCurrentStates()
        let stateByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        var updatedStates: [ThermostatState] = []

        for device in devices {
            if stateSubscriptions[device.id] == nil {
                let subscription = controlService.observeDeviceState(deviceID: device.id)
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] state in
                        guard let self else { return }
                        if let index = self.states.firstIndex(where: { $0.id == state.id }) {
                            self.states[index] = state
                        } else {
                            self.states.append(state)
                        }
                    }
                stateSubscriptions[device.id] = subscription
            }

            if let state = stateByID[device.id] {
                updatedStates.append(state)
            } else {
                let placeholder = ThermostatState(
                    device: device,
                    ambientTemperatureC: 21,
                    targetTemperatureC: 21,
                    humidity: 40,
                    mode: .heat
                )
                updatedStates.append(placeholder)
            }
        }

        await MainActor.run {
            states = updatedStates
        }
    }
}
