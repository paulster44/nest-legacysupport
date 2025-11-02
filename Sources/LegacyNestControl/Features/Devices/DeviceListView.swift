import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject var viewModel: DeviceListViewModel
    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureFormatter.Unit.celsius.rawValue

    private var formatter: TemperatureFormatter {
        TemperatureFormatter(unit: TemperatureFormatter.Unit(rawValue: temperatureUnitRawValue) ?? .celsius)
    }

    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            List {
                Section("Thermostats") {
                    ForEach(viewModel.states) { state in
                        Button {
                            coordinator.showDetail(for: state.device)
                        } label: {
                            DeviceRowView(state: state, formatter: formatter)
                        }
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                addButton
                    .padding()
            }
            .navigationTitle("Legacy Nest")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings") { coordinator.showSettings() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("About") { coordinator.showAbout() }
                }
            }
            .sheet(isPresented: $viewModel.showingManualEntry) {
                ManualDeviceEntryView { host, port, name in
                    Task { await viewModel.addManualDevice(host: host, port: port, name: name) }
                }
            }
            .onAppear { viewModel.start() }
            .onDisappear { viewModel.stop() }
            .navigationDestination(for: AppCoordinator.DeviceRoute.self) { route in
                switch route.destination {
                case let .detail(deviceID):
                    if let state = viewModel.states.first(where: { $0.id == deviceID }) {
                        DeviceDetailView(
                            viewModel: DeviceDetailViewModel(state: state, controlService: viewModel.controlService)
                        )
                    } else {
                        Text("Device not found")
                    }
                case let .schedule(deviceID):
                    ScheduleEditorContainerView(
                        deviceID: deviceID,
                        scheduleStore: viewModel.scheduleStore,
                        controlService: viewModel.controlService
                    )
                case .settings:
                    SettingsView()
                case .about:
                    AboutView()
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            viewModel.showingManualEntry = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .padding()
                .background(Circle().fill(.accentColor))
                .foregroundStyle(.white)
                .shadow(radius: 4)
        }
        .accessibilityLabel("Add thermostat manually")
    }
}

private struct DeviceRowView: View {
    let state: ThermostatState
    let formatter: TemperatureFormatter

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.displayName)
                    .font(.headline)
                Text("Mode: \(state.mode.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(formatter.string(fromCelsius: state.targetTemperatureC))
                    .font(.title3)
                Text("Indoor \(formatter.string(fromCelsius: state.ambientTemperatureC))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ManualDeviceEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var host: String = ""
    @State private var port: Int = 9559
    @State private var name: String = ""

    var onSave: (String, Int, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    TextField("IP Address", text: $host)
                        .keyboardType(.numbersAndPunctuation)
                    Stepper(value: $port, in: 1...65_535) {
                        Text("Port: \(port)")
                    }
                }

                Section("Details") {
                    TextField("Friendly Name", text: $name)
                }
            }
            .navigationTitle("Add Thermostat")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(host, port, name.isEmpty ? host : name)
                        dismiss()
                    }
                    .disabled(host.isEmpty)
                }
            }
        }
    }
}
