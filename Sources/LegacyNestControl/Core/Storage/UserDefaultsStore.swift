import Foundation

final class UserDefaultsStore {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            userDefaults.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to encode value for \(key): \(error)")
        }
    }

    func value<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        guard let data = userDefaults.data(forKey: key) else {
            return defaultValue
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            assertionFailure("Failed to decode value for \(key): \(error)")
            return defaultValue
        }
    }
}
