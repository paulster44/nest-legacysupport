import Combine
import Foundation

@MainActor
final class DeviceDetailViewModel: ObservableObject {
    @Published var state: ThermostatState
    @Published var temperatureFormatter = TemperatureFormatter()
    @Published var isAdjustingTemperature = false

    private let controlService: ThermostatControlServicing
    private var cancellable: AnyCancellable?

    init(state: ThermostatState, controlService: ThermostatControlServicing) {
        self.state = state
        self.controlService = controlService
        listenForUpdates()
    }

    func setTargetTemperature(_ celsius: Double) {
        Task {
            try? await controlService.setTargetTemperature(celsius, for: state.id)
        }
    }

    func setMode(_ mode: HeatingMode) {
        Task {
            try? await controlService.setMode(mode, for: state.id)
        }
    }

    func applyAutoRange(low: Double, high: Double) async {
        try? await controlService.setTargetRange(low: low, high: high, for: state.id)
    }

    private func listenForUpdates() {
        cancellable = controlService
            .observeDeviceState(deviceID: state.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.state = newState
            }
    }
}
