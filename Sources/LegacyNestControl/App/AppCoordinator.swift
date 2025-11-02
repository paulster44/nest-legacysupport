import Foundation
import SwiftUI

final class AppCoordinator: ObservableObject {
    struct DeviceRoute: Hashable, Identifiable {
        enum Destination: Hashable {
            case detail(deviceID: UUID)
            case schedule(deviceID: UUID)
            case settings
            case about
        }

        let destination: Destination
        var id: Destination { destination }
    }

    @Published var navigationPath: [DeviceRoute] = []

    private let discoveryService: ThermostatDiscoveryServicing
    private let controlService: ThermostatControlServicing
    private let scheduleStore: ScheduleStoring

    init(
        userDefaults: UserDefaults = .standard,
        discoveryService: ThermostatDiscoveryServicing? = nil,
        controlService: ThermostatControlServicing? = nil
    ) {
        let store = UserDefaultsStore(userDefaults: userDefaults)
        self.discoveryService = discoveryService ?? MockThermostatDiscoveryService()
        let scheduleStore = ScheduleStore(userDefaultsStore: store)
        self.scheduleStore = scheduleStore
        self.controlService = controlService ?? MockThermostatControlService(scheduleStore: scheduleStore)
    }

    func makeRootView() -> some View {
        DeviceListView(
            viewModel: DeviceListViewModel(
                discoveryService: discoveryService,
                controlService: controlService,
                scheduleStore: scheduleStore
            )
        )
        .environmentObject(self)
    }

    func showDetail(for device: ThermostatDevice) {
        navigationPath.append(.init(destination: .detail(deviceID: device.id)))
    }

    func showSchedule(for deviceID: UUID) {
        navigationPath.append(.init(destination: .schedule(deviceID: deviceID)))
    }

    func showSettings() {
        navigationPath.append(.init(destination: .settings))
    }

    func showAbout() {
        navigationPath.append(.init(destination: .about))
    }
}
