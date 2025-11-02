import SwiftUI

struct SettingsView: View {
    @AppStorage("temperature_unit") private var temperatureUnitRawValue: String = TemperatureFormatter.Unit.celsius.rawValue

    var body: some View {
        Form {
            Section("Temperature Units") {
                Picker("Units", selection: $temperatureUnitRawValue) {
                    ForEach(TemperatureFormatter.Unit.allCases) { unit in
                        Text(unit.rawValue.capitalized).tag(unit.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Networking") {
                Text("Discovery and control happen only on your local network.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
