import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func triggerImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "instant_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func rescheduleAll(from stateDict: [String: Any]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        // 1. Schedule Task Notifications (4 hours before due + threat/occupation alert at due)
        if let tasks = stateDict["tasks"] as? [[String: Any]] {
            var alreadyOverdueCount = 0
            var upcomingTasks: [(id: String, name: String, dueDate: Date)] = []

            for task in tasks {
                let status = task["status"] as? String ?? ""
                if status == "Xong" { continue }
                guard let id = task["id"] as? String,
                      let name = task["name"] as? String,
                      let dueStr = task["due"] as? String,
                      !dueStr.isEmpty,
                      let dueDate = isoFormatter.date(from: dueStr) else { continue }

                if dueDate <= now {
                    alreadyOverdueCount += 1
                } else {
                    upcomingTasks.append((id: id, name: name, dueDate: dueDate))
                }
            }

            upcomingTasks.sort { $0.dueDate < $1.dueDate }

            for (idx, item) in upcomingTasks.enumerated() {
                // 4 hours before due
                let fourHoursBefore = item.dueDate.addingTimeInterval(-4 * 3600)
                if fourHoursBefore > now {
                    let content = UNMutableNotificationContent()
                    content.title = "⏳ Đến giờ làm · Đếm ngược 4 giờ"
                    content.body = item.name
                    content.sound = .default

                    let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fourHoursBefore)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    center.add(UNNotificationRequest(identifier: "task_pre_\(item.id)", content: content, trigger: trigger))
                }

                // Exact due time: matches Thư đe dọa / Chiếm đóng (3 overdue tasks = mất ổ)
                let projectedOverdue = alreadyOverdueCount + idx + 1
                let content = UNMutableNotificationContent()
                if projectedOverdue >= 3 {
                    content.title = "🚨 Chiếm đóng · Ổ kiến đã bị chiếm!"
                    content.body = "Quá hạn: \(item.name). Hoàn thành các việc trễ để đoạt lại ổ!"
                } else {
                    let remaining = 3 - projectedOverdue
                    content.title = "⚠️ Thư đe dọa · Quá hạn lần \(projectedOverdue)/3"
                    content.body = "\(item.name) — còn \(remaining) việc nữa là mất ổ!"
                }
                content.sound = .default

                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.dueDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(identifier: "task_due_\(item.id)", content: content, trigger: trigger))
            }
        }

        // 2. Schedule Weekly Timetable Slots
        if let slots = stateDict["slots"] as? [[String: Any]],
           let sched = stateDict["sched"] as? [String: String] {
            for dayIndex in 0..<7 {
                // App uses 0=T2(Mon)..6=CN(Sun). Apple Calendar weekday: 1=Sun, 2=Mon..7=Sat
                let appleWeekday = (dayIndex == 6) ? 1 : (dayIndex + 2)
                for slot in slots {
                    guard let slotId = slot["id"] as? String,
                          let startStr = slot["a"] as? String,
                          let title = sched["\(dayIndex)-\(slotId)"],
                          !title.trimmingCharacters(in: .whitespaces).isEmpty else { continue }

                    let parts = startStr.split(separator: ":").compactMap { Int($0) }
                    guard parts.count == 2 else { continue }

                    var comps = DateComponents()
                    comps.weekday = appleWeekday
                    comps.hour = parts[0]
                    comps.minute = parts[1]

                    let content = UNMutableNotificationContent()
                    content.title = "🍃 Bắt đầu nào · Thời khóa biểu"
                    content.body = "\(title) (lúc \(startStr))"
                    content.sound = .default

                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                    center.add(UNNotificationRequest(identifier: "slot_\(dayIndex)_\(slotId)", content: content, trigger: trigger))
                }
            }
        }

        // 3. Daily Habit Reminder at 20:30 if user has habits
        if let habits = stateDict["habits"] as? [[String: Any]], !habits.isEmpty {
            var comps = DateComponents()
            comps.hour = 20
            comps.minute = 30

            let content = UNMutableNotificationContent()
            content.title = "🌿 Tưới cây thói quen hôm nay"
            content.body = "Kiểm tra và đánh dấu các thói quen hằng ngày của bạn nhé!"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(UNNotificationRequest(identifier: "habit_daily_reminder", content: content, trigger: trigger))
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
