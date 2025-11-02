import Foundation

struct ScheduleBlock: Identifiable, Codable, Equatable {
    var id: UUID
    var timeMinutes: Int
    var mode: HeatingMode
    var targetC: Double?
    var rangeLowC: Double?
    var rangeHighC: Double?

    init(
        id: UUID = UUID(),
        timeMinutes: Int,
        mode: HeatingMode,
        targetC: Double? = nil,
        rangeLowC: Double? = nil,
        rangeHighC: Double? = nil
    ) {
        self.id = id
        self.timeMinutes = max(0, min(1439, timeMinutes))
        self.mode = mode
        self.targetC = targetC
        if let low = rangeLowC, let high = rangeHighC, low > high {
            self.rangeLowC = high
            self.rangeHighC = low
        } else {
            self.rangeLowC = rangeLowC
            self.rangeHighC = rangeHighC
        }
    }

    var time: DateComponents {
        DateComponents(minute: timeMinutes % 60, hour: timeMinutes / 60)
    }

    func displayTime(locale: Locale = .current) -> String {
        guard let date = Calendar.current.date(from: time) else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func displayTemperature(using formatter: TemperatureFormatter) -> String {
        switch mode {
        case .auto:
            if let low = rangeLowC, let high = rangeHighC {
                return "\(formatter.string(fromCelsius: low)) – \(formatter.string(fromCelsius: high))"
            }
            fallthrough
        case .heat, .cool:
            if let target = targetC {
                return formatter.string(fromCelsius: target)
            }
            return "—"
        case .off:
            return "Off"
        }
    }
}

struct ThermostatSchedule: Identifiable, Codable, Equatable {
    enum Weekday: Int, Codable, CaseIterable, Identifiable {
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
        case sunday = 1

        var id: Int { rawValue }

        var displayName: String {
            let symbols = Calendar.current.weekdaySymbols
            let index = rawValue - 1
            guard symbols.indices.contains(index) else { return "" }
            return symbols[index]
        }

        var shortDisplayName: String {
            let symbols = Calendar.current.shortWeekdaySymbols
            let index = rawValue - 1
            guard symbols.indices.contains(index) else { return "" }
            return symbols[index]
        }
    }

    let id: UUID
    var deviceID: UUID
    var blocksByDay: [Weekday: [ScheduleBlock]]

    init(deviceID: UUID, blocksByDay: [Weekday: [ScheduleBlock]] = [:]) {
        self.id = deviceID
        self.deviceID = deviceID
        self.blocksByDay = blocksByDay
        normalize()
    }

    func blocks(for day: Weekday) -> [ScheduleBlock] {
        blocksByDay[day]?.sorted { $0.timeMinutes < $1.timeMinutes } ?? []
    }

    mutating func addBlock(_ block: ScheduleBlock, to day: Weekday) {
        var blocks = blocksByDay[day] ?? []
        blocks.append(block)
        blocksByDay[day] = sort(blocks)
    }

    mutating func updateBlock(_ block: ScheduleBlock, in day: Weekday) {
        var blocks = blocksByDay[day] ?? []
        if let index = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks[index] = block
        } else {
            blocks.append(block)
        }
        blocksByDay[day] = sort(blocks)
    }

    mutating func deleteBlocks(with ids: [UUID], in day: Weekday) {
        guard var blocks = blocksByDay[day] else { return }
        blocks.removeAll { ids.contains($0.id) }
        blocksByDay[day] = sort(blocks)
    }

    private func sort(_ blocks: [ScheduleBlock]) -> [ScheduleBlock] {
        blocks.sorted { $0.timeMinutes < $1.timeMinutes }
    }

    private mutating func normalize() {
        for day in Weekday.allCases {
            let sorted = blocksByDay[day]?.sorted(by: { $0.timeMinutes < $1.timeMinutes }) ?? []
            blocksByDay[day] = sorted
        }
    }
}
