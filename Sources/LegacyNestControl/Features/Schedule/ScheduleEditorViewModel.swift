import Foundation

@MainActor
final class ScheduleEditorViewModel: ObservableObject {
    struct EditorContext: Identifiable {
        var id: UUID { block.id }
        var day: ThermostatSchedule.Weekday
        var block: ScheduleBlock
        var isNew: Bool
    }

    @Published var schedule: ThermostatSchedule
    @Published var selectedDay: ThermostatSchedule.Weekday
    @Published var editorContext: EditorContext?

    private let scheduleStore: ScheduleStoring
    private let controlService: ThermostatControlServicing
    private(set) var deviceID: UUID

    init(
        deviceID: UUID,
        schedule: ThermostatSchedule,
        scheduleStore: ScheduleStoring,
        controlService: ThermostatControlServicing
    ) {
        self.deviceID = deviceID
        self.schedule = schedule
        self.scheduleStore = scheduleStore
        self.controlService = controlService
        self.selectedDay =
            ThermostatSchedule.Weekday.allCases.first(where: { schedule.blocksByDay[$0]?.isEmpty == false })
            ?? .monday
        Task { await loadRemoteSchedule() }
    }

    var blocksForSelectedDay: [ScheduleBlock] {
        schedule.blocks(for: selectedDay)
    }

    func addBlockButtonTapped() {
        let existingBlocks = schedule.blocks(for: selectedDay)
        let referenceBlock = existingBlocks.last
        let defaultMode = referenceBlock?.mode ?? .heat
        let block = ScheduleBlock(
            timeMinutes: referenceBlock?.timeMinutes ?? 8 * 60,
            mode: defaultMode,
            targetC: referenceBlock?.targetC ?? 21,
            rangeLowC: referenceBlock?.rangeLowC ?? 19,
            rangeHighC: referenceBlock?.rangeHighC ?? 23
        )
        editorContext = EditorContext(
            day: selectedDay,
            block: block,
            isNew: true
        )
    }

    func edit(block: ScheduleBlock, day: ThermostatSchedule.Weekday) {
        editorContext = EditorContext(day: day, block: block, isNew: false)
    }

    func delete(at offsets: IndexSet) {
        let blocks = blocksForSelectedDay
        let ids = offsets.compactMap { index in
            blocks.indices.contains(index) ? blocks[index].id : nil
        }
        schedule.deleteBlocks(with: ids, in: selectedDay)
    }

    func saveEditingBlock(_ block: ScheduleBlock) {
        guard let context = editorContext else { return }
        if context.isNew {
            schedule.addBlock(block, to: context.day)
        } else {
            schedule.updateBlock(block, in: context.day)
        }
        editorContext = nil
    }

    func persistChanges() async {
        schedule = ThermostatSchedule(deviceID: schedule.deviceID, blocksByDay: schedule.blocksByDay)
        scheduleStore.saveSchedule(schedule)
        do {
            try await controlService.applySchedule(schedule, for: deviceID)
        } catch {
            #if DEBUG
            print("Failed to apply schedule: \(error)")
            #endif
        }
    }

    private func loadRemoteSchedule() async {
        do {
            let remote = try await controlService.fetchSchedule(for: deviceID)
            await MainActor.run {
                schedule = ThermostatSchedule(deviceID: remote.deviceID, blocksByDay: remote.blocksByDay)
                selectedDay =
                    ThermostatSchedule.Weekday.allCases.first(where: { remote.blocksByDay[$0]?.isEmpty == false })
                    ?? selectedDay
            }
        } catch {
            // Remote fetch not required for mock implementation.
        }
    }
}
