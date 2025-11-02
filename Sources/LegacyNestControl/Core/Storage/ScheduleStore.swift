import Foundation

protocol ScheduleStoring {
    func loadSchedule(for deviceID: UUID) -> ThermostatSchedule
    func saveSchedule(_ schedule: ThermostatSchedule)
}

final class ScheduleStore: ScheduleStoring {
    private let userDefaultsStore: UserDefaultsStore
    private let keyPrefix = "schedule_"

    init(userDefaultsStore: UserDefaultsStore) {
        self.userDefaultsStore = userDefaultsStore
    }

    func loadSchedule(for deviceID: UUID) -> ThermostatSchedule {
        let key = storageKey(for: deviceID)
        return userDefaultsStore.value(forKey: key, default: ThermostatSchedule(deviceID: deviceID))
    }

    func saveSchedule(_ schedule: ThermostatSchedule) {
        let key = storageKey(for: schedule.deviceID)
        userDefaultsStore.set(schedule, forKey: key)
    }

    private func storageKey(for deviceID: UUID) -> String {
        "\(keyPrefix)\(deviceID.uuidString)"
    }
}
