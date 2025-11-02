import SwiftUI

struct DeviceDetailView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject var viewModel: DeviceDetailViewModel
    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureFormatter.Unit.celsius.rawValue
    @State private var dialTemperature: Double
    @State private var autoLow: Double
    @State private var autoHigh: Double

    private var formatter: TemperatureFormatter {
        TemperatureFormatter(unit: TemperatureFormatter.Unit(rawValue: temperatureUnitRawValue) ?? .celsius)
    }

    init(viewModel: DeviceDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _dialTemperature = State(initialValue: viewModel.state.targetTemperatureC)
        _autoLow = State(initialValue: viewModel.state.targetLowC ?? 18)
        _autoHigh = State(initialValue: viewModel.state.targetHighC ?? 24)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                temperatureDialSection
                modeSelector
                environmentReadings
                scheduleSection
            }
            .padding()
            .animation(.easeInOut, value: viewModel.state)
        }
        .navigationTitle(viewModel.state.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Schedule") {
                    coordinator.showSchedule(for: viewModel.state.id)
                }
            }
        }
        .onChange(of: viewModel.state) { newState in
            dialTemperature = newState.targetTemperatureC
            autoLow = newState.targetLowC ?? autoLow
            autoHigh = newState.targetHighC ?? autoHigh
        }
    }

    private var temperatureDialSection: some View {
        VStack(spacing: 16) {
            TemperatureDialView(
                temperature: Binding(
                    get: { dialTemperature },
                    set: { value in
                        dialTemperature = value
                        if viewModel.state.mode == .auto {
                            autoLow = min(autoLow, value)
                            autoHigh = max(autoHigh, value)
                        }
                    }
                ),
                mode: viewModel.state.mode,
                onEditingChanged: { editing in
                    viewModel.isAdjustingTemperature = editing
                },
                onCommit: { value in
                    if viewModel.state.mode == .auto {
                        Task { await applyAutoRange() }
                    } else {
                        viewModel.setTargetTemperature(value)
                    }
                }
            )
            .frame(height: 300)

            if viewModel.state.mode == .auto {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Auto Range")
                        .font(.headline)
                    HStack {
                        Stepper(value: $autoLow, in: 10...autoHigh, step: 0.5) {
                            Text("Low: \(formatter.string(fromCelsius: autoLow))")
                        }
                        Stepper(value: $autoHigh, in: autoLow...30, step: 0.5) {
                            Text("High: \(formatter.string(fromCelsius: autoHigh))")
                        }
                    }
                    Button("Apply Range") {
                        Task { await applyAutoRange() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Slide the dial to adjust the target temperature.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
        )
    }

    private var modeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mode")
                .font(.headline)
            Picker("Mode", selection: Binding(
                get: { viewModel.state.mode },
                set: { viewModel.setMode($0) }
            )) {
                ForEach(HeatingMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var environmentReadings: some View {
        HStack(spacing: 24) {
            VStack {
                Text("Ambient")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(formatter.string(fromCelsius: viewModel.state.ambientTemperatureC))
                    .font(.title2)
            }
            VStack {
                Text("Humidity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(Int(viewModel.state.humidity))%")
                    .font(.title2)
            }
            VStack {
                Text("Target")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if viewModel.state.mode == .auto {
                    Text("\(formatter.string(fromCelsius: autoLow)) - \(formatter.string(fromCelsius: autoHigh))")
                        .font(.title3)
                } else {
                    Text(formatter.string(fromCelsius: viewModel.state.targetTemperatureC))
                        .font(.title2)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scheduling")
                .font(.headline)
            Text("Set automated temperature changes for each day.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                coordinator.showSchedule(for: viewModel.state.id)
            } label: {
                Label("Edit Schedule", systemImage: "calendar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func applyAutoRange() async {
        let low = min(autoLow, autoHigh)
        let high = max(autoLow, autoHigh)
        autoLow = low
        autoHigh = high
        await MainActor.run {
            dialTemperature = (low + high) / 2
        }
        await viewModel.applyAutoRange(low: low, high: high)
    }
}
