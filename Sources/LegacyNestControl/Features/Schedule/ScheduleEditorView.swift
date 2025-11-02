import SwiftUI

struct ScheduleEditorView: View {
    @ObservedObject var viewModel: ScheduleEditorViewModel
    var supportsRangeEditing: Bool
    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureFormatter.Unit.celsius.rawValue

    private var formatter: TemperatureFormatter {
        TemperatureFormatter(unit: TemperatureFormatter.Unit(rawValue: temperatureUnitRawValue) ?? .celsius)
    }

    var body: some View {
        VStack(spacing: 16) {
            daySelector
            List {
                Section(header: Text("Schedule")) {
                    if viewModel.blocksForSelectedDay.isEmpty {
                        Text("No blocks scheduled. Tap Add Block to create one.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.blocksForSelectedDay) { block in
                        Button {
                            viewModel.edit(block: block, day: viewModel.selectedDay)
                        } label: {
                            ScheduleBlockRow(block: block, formatter: formatter)
                        }
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }
            .listStyle(.insetGrouped)

            Button {
                viewModel.addBlockButtonTapped()
            } label: {
                Label("Add Block", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .sheet(item: Binding(
            get: { viewModel.editorContext },
            set: { viewModel.editorContext = $0 }
        )) { context in
            ScheduleBlockEditorView(
                context: context,
                supportsRangeEditing: supportsRangeEditing
            ) { updated in
                viewModel.saveEditingBlock(updated)
            }
        }
    }

    private var daySelector: some View {
        Picker("Day", selection: $viewModel.selectedDay) {
            ForEach(ThermostatSchedule.Weekday.allCases) { day in
                Text(day.shortDisplayName).tag(day)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct ScheduleBlockRow: View {
    let block: ScheduleBlock
    let formatter: TemperatureFormatter

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(block.displayTime())
                    .font(.headline)
                Text(block.mode.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(block.displayTemperature(using: formatter))
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
}
