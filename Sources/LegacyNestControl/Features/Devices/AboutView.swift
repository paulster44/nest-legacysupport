import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("LegacyNestControl")
                    .font(.largeTitle)
                    .bold()
                Text("Community-maintained control app for legacy Nest Learning Thermostats.")
                    .font(.title3)
                Divider()
                Text("Disclaimer")
                    .font(.headline)
                Text("Not affiliated with Google or Nest. This app communicates only across your local network and does not use Google/Nest cloud services.")
                Divider()
                Text("Version 0.1.0")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("About")
    }
}
