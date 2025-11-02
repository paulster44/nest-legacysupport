import XCTest
@testable import LegacyNestControl

final class ScheduleStoreTests: XCTestCase {
    func testSavingAndLoadingSchedule() {
        let userDefaults = UserDefaults(suiteName: "ScheduleStoreTests")!
        userDefaults.removePersistentDomain(forName: "ScheduleStoreTests")
        let store = UserDefaultsStore(userDefaults: userDefaults)
        let scheduleStore = ScheduleStore(userDefaultsStore: store)
        let deviceID = UUID()
        var schedule = ThermostatSchedule(deviceID: deviceID)
        let block = ScheduleBlock(
            timeMinutes: 8 * 60,
            mode: .heat,
            targetC: 21
        )
        schedule.addBlock(block, to: .monday)

        scheduleStore.saveSchedule(schedule)
        let loaded = scheduleStore.loadSchedule(for: deviceID)

        XCTAssertEqual(loaded.blocks(for: .monday).count, 1)
        XCTAssertEqual(loaded.blocks(for: .monday).first?.timeMinutes, block.timeMinutes)
        XCTAssertEqual(loaded.blocks(for: .monday).first?.mode, .heat)
    }
}
