import SwiftUI

struct ScheduleEditorContainerView: View {
    @StateObject private var viewModel: ScheduleEditorViewModel

    init(deviceID: UUID, scheduleStore: ScheduleStoring, controlService: ThermostatControlServicing) {
        let schedule = scheduleStore.loadSchedule(for: deviceID)
        _viewModel = StateObject(
            wrappedValue: ScheduleEditorViewModel(
                deviceID: deviceID,
                schedule: schedule,
                scheduleStore: scheduleStore,
                controlService: controlService
            )
        )
    }

    var body: some View {
        ScheduleEditorView(viewModel: viewModel, supportsRangeEditing: true)
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await viewModel.persistChanges() }
                    }
                }
            }
    }
}
