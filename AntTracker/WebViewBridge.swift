import Foundation
import WebKit
import WidgetKit

final class WebViewBridge: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "trackerBridge",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        if type == "notify" {
            let title = body["title"] as? String ?? "🐜 Tracker tổ kiến"
            let detail = body["body"] as? String ?? "Đến giờ thực hiện công việc!"
            NotificationManager.shared.triggerImmediateNotification(title: title, body: detail)
        } else if type == "syncState", let state = body["state"] as? [String: Any] {
            NotificationManager.shared.rescheduleAll(from: state)
            if let snapDict = body["widget"] as? [String: Any] {
                let snapshot = WidgetSnapshot(
                    queenLevel: snapDict["queenLevel"] as? Int ?? 1,
                    queenRank: snapDict["queenRank"] as? String ?? "Kiến con",
                    overdueCount: snapDict["overdueCount"] as? Int ?? 0,
                    todayCount: snapDict["todayCount"] as? Int ?? 0,
                    futureCount: snapDict["futureCount"] as? Int ?? 0,
                    doneCount: snapDict["doneCount"] as? Int ?? 0,
                    nextTaskTitle: snapDict["nextTaskTitle"] as? String ?? "Không có việc gấp",
                    nextTaskDue: snapDict["nextTaskDue"] as? String ?? "",
                    nextSlotTitle: snapDict["nextSlotTitle"] as? String ?? "Trống lịch",
                    nextSlotTime: snapDict["nextSlotTime"] as? String ?? "",
                    habitPercentToday: snapDict["habitPercentToday"] as? Int ?? 0,
                    habitStreak: snapDict["habitStreak"] as? Int ?? 0,
                    updatedAt: Date()
                )
                SharedStore.saveSnapshot(snapshot)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
