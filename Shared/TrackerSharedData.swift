import Foundation

struct WidgetSnapshot: Codable {
    var queenLevel: Int
    var queenRank: String
    var overdueCount: Int
    var todayCount: Int
    var futureCount: Int
    var doneCount: Int
    var nextTaskTitle: String
    var nextTaskDue: String
    var nextSlotTitle: String
    var nextSlotTime: String
    var habitPercentToday: Int
    var habitStreak: Int
    var updatedAt: Date

    static let placeholder = WidgetSnapshot(
        queenLevel: 1,
        queenRank: "Kiến con",
        overdueCount: 0,
        todayCount: 2,
        futureCount: 3,
        doneCount: 5,
        nextTaskTitle: "Hoàn thành mục tiêu hôm nay",
        nextTaskDue: "Hôm nay",
        nextSlotTitle: "Học tập & Làm việc",
        nextSlotTime: "08:00–10:00",
        habitPercentToday: 75,
        habitStreak: 3,
        updatedAt: Date()
    )
}

enum SharedStore {
    static let appGroupID = "group.com.anttracker.app"
    static let snapshotKey = "ant_tracker_widget_snapshot_v1"

    static var defaults: UserDefaults {
        if let groupDefaults = UserDefaults(suiteName: appGroupID) {
            return groupDefaults
        }
        return .standard
    }

    static func saveSnapshot(_ snapshot: WidgetSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
            defaults.synchronize()
        }
    }

    static func loadSnapshot() -> WidgetSnapshot {
        if let data = defaults.data(forKey: snapshotKey),
           let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) {
            return snap
        }
        return .placeholder
    }
}
