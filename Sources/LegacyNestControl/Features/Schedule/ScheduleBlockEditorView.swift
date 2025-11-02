import SwiftUI

struct ScheduleBlockEditorView: View {
    let context: ScheduleEditorViewModel.EditorContext
    var supportsRangeEditing: Bool
    var onSave: (ScheduleBlock) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureFormatter.Unit.celsius.rawValue
    @State private var time: Date
    @State private var mode: HeatingMode
    @State private var targetTemperature: Double
    @State private var lowTemperature: Double
    @State private var highTemperature: Double

    private var formatter: TemperatureFormatter {
        TemperatureFormatter(unit: TemperatureFormatter.Unit(rawValue: temperatureUnitRawValue) ?? .celsius)
    }

    init(
        context: ScheduleEditorViewModel.EditorContext,
        supportsRangeEditing: Bool,
        onSave: @escaping (ScheduleBlock) -> Void
    ) {
        self.context = context
        self.supportsRangeEditing = supportsRangeEditing
        self.onSave = onSave

        let calendar = Calendar.current
        let components = DateComponents(hour: context.block.timeMinutes / 60, minute: context.block.timeMinutes % 60)
        _time = State(initialValue: calendar.date(from: components) ?? Date())
        _mode = State(initialValue: context.block.mode)
        _targetTemperature = State(initialValue: context.block.targetC ?? 21)
        _lowTemperature = State(initialValue: context.block.rangeLowC ?? max((context.block.targetC ?? 21) - 1, 5))
        _highTemperature = State(initialValue: context.block.rangeHighC ?? min((context.block.targetC ?? 21) + 1, 35))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Day") {
                    Text(context.day.displayName)
                }

                Section("Mode") {
                    Picker("Mode", selection: $mode) {
                        ForEach(HeatingMode.allCases) { heatingMode in
                            Text(heatingMode.displayName).tag(heatingMode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Time") {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }

                Section("Temperature") {
                    temperatureInputs
                }
            }
            .navigationTitle(context.isNew ? "New Block" : "Edit Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(makeBlock())
                        dismiss()
                    }
                    .disabled(!isValidConfiguration)
                }
            }
            .onChange(of: mode) { newMode in
                switch newMode {
                case .heat, .cool:
                    targetTemperature = min(max(targetTemperature, 5), 35)
                case .auto:
                    lowTemperature = max(5, min(lowTemperature, highTemperature - 0.5))
                    highTemperature = min(35, max(highTemperature, lowTemperature + 0.5))
                case .off:
                    break
                }
            }
        }
    }

    @ViewBuilder
    private var temperatureInputs: some View {
        switch mode {
        case .off:
            Text("Thermostat will remain off during this block.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .heat, .cool:
            Stepper(value: $targetTemperature, in: 5...35, step: 0.5) {
                Text("Target: \(formatter.string(fromCelsius: targetTemperature))")
            }
        case .auto:
            if supportsRangeEditing {
                Stepper(value: $lowTemperature, in: 5...highTemperature, step: 0.5) {
                    Text("Low: \(formatter.string(fromCelsius: lowTemperature))")
                }
                Stepper(value: $highTemperature, in: lowTemperature...35, step: 0.5) {
                    Text("High: \(formatter.string(fromCelsius: highTemperature))")
                }
            } else {
                Text("Auto mode range editing is not available for this thermostat.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var isValidConfiguration: Bool {
        switch mode {
        case .off:
            return true
        case .heat, .cool:
            return targetTemperature >= 5 && targetTemperature <= 35
        case .auto:
            guard supportsRangeEditing else { return false }
            return lowTemperature < highTemperature
        }
    }

    private func makeBlock() -> ScheduleBlock {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        switch mode {
        case .off:
            return ScheduleBlock(
                id: context.block.id,
                timeMinutes: minutes,
                mode: .off,
                targetC: nil,
                rangeLowC: nil,
                rangeHighC: nil
            )
        case .heat, .cool:
            return ScheduleBlock(
                id: context.block.id,
                timeMinutes: minutes,
                mode: mode,
                targetC: targetTemperature,
                rangeLowC: nil,
                rangeHighC: nil
            )
        case .auto:
            return ScheduleBlock(
                id: context.block.id,
                timeMinutes: minutes,
                mode: .auto,
                targetC: (lowTemperature + highTemperature) / 2,
                rangeLowC: min(lowTemperature, highTemperature),
                rangeHighC: max(lowTemperature, highTemperature)
            )
        }
    }
}
