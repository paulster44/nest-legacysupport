import SwiftUI

struct TemperatureDialView: View {
    @Binding var temperature: Double
    var mode: HeatingMode
    var minimum: Double = 10
    var maximum: Double = 30
    var onEditingChanged: ((Bool) -> Void)?
    var onCommit: ((Double) -> Void)?

    @GestureState private var dragLocation: CGPoint? = nil

    private var normalized: Double {
        let clamped = min(max(temperature, minimum), maximum)
        return (clamped - minimum) / (maximum - minimum)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                Circle()
                    .stroke(lineWidth: size * 0.08)
                    .foregroundStyle(AngularGradient(
                        gradient: Gradient(colors: modeGradientColors),
                        center: .center,
                        startAngle: .degrees(-135),
                        endAngle: .degrees(135)
                    ))
                    .mask(
                        Circle()
                            .trim(from: 0, to: normalized)
                            .rotation(Angle.degrees(-135))
                    )
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: size * 0.01)
                    .padding(size * 0.04)

                VStack(spacing: 8) {
                    Text(mode.displayName.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(TemperatureFormatter().string(fromCelsius: temperature))
                        .font(.system(size: size * 0.24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
            .gesture(dragGesture(size: size))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var modeGradientColors: [Color] {
        switch mode {
        case .heat: return [.orange, .red]
        case .cool: return [.cyan, .blue]
        case .auto: return [.green, .yellow]
        case .off: return [.gray, .gray]
        }
    }

    private func dragGesture(size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragLocation) { value, state, _ in
                state = value.location
            }
            .onChanged { value in
                onEditingChanged?(true)
                temperature = valueToTemperature(from: value.location, in: size)
            }
            .onEnded { value in
                let newValue = valueToTemperature(from: value.location, in: size)
                temperature = newValue
                onEditingChanged?(false)
                onCommit?(newValue)
            }
    }

    private func valueToTemperature(from location: CGPoint, in size: CGFloat) -> Double {
        let center = CGPoint(x: size / 2, y: size / 2)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        let degrees = angle * 180 / .pi
        let adjusted = degrees + 180 // convert to 0-360
        let normalizedAngle = max(0, min(1, (adjusted - 45) / 270))
        let value = minimum + normalizedAngle * (maximum - minimum)
        return value
    }
}

#Preview {
    TemperatureDialView(
        temperature: .constant(22),
        mode: .auto
    )
    .frame(width: 250, height: 250)
    .padding()
}
