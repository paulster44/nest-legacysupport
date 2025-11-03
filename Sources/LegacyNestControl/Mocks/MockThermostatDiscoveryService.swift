import Combine
import Foundation

final class MockThermostatDiscoveryService: ThermostatDiscoveryServicing {
    static let defaultDevices: [ThermostatDevice] = [
        ThermostatDevice(name: "Living Room", host: "192.168.1.20", port: 9559),
        ThermostatDevice(name: "Bedroom", host: "192.168.1.21", port: 9559)
    ]

    private let subject: CurrentValueSubject<[ThermostatDevice], Never>
    private var discoveryTask: Task<Void, Never>?

    init(devices: [ThermostatDevice] = MockThermostatDiscoveryService.defaultDevices) {
        self.subject = CurrentValueSubject(devices)
    }

    var devicesPublisher: AnyPublisher<[ThermostatDevice], Never> {
        subject.eraseToAnyPublisher()
    }

    func startDiscovery() {
        discoveryTask?.cancel()
        discoveryTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                await refreshLastSeen()
            }
        }
    }

    func stopDiscovery() {
        discoveryTask?.cancel()
        discoveryTask = nil
    }

    func addManualDevice(host: String, port: Int, name: String) async {
        var devices = subject.value
        let newDevice = ThermostatDevice(name: name, host: host, port: port, lastSeen: .now)
        if let index = devices.firstIndex(where: { $0.host == host && $0.port == port }) {
            devices[index] = newDevice
        } else {
            devices.append(newDevice)
        }
        subject.send(devices)
    }

    private func refreshLastSeen() async {
        let updated = subject.value.map { device -> ThermostatDevice in
            var mutable = device
            mutable.lastSeen = .now
            return mutable
        }
        subject.send(updated)
    }
}
