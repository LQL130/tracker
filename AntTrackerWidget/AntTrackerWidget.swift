import WidgetKit
import SwiftUI

struct AntEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct AntProvider: TimelineProvider {
    func placeholder(in context: Context) -> AntEntry {
        AntEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (AntEntry) -> Void) {
        completion(AntEntry(date: Date(), snapshot: SharedStore.loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AntEntry>) -> Void) {
        let entry = AntEntry(date: Date(), snapshot: SharedStore.loadSnapshot())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct AntTrackerWidgetEntryView: View {
    var entry: AntProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var scheme

    private var bgColor: Color {
        scheme == .dark
            ? Color(red: 0.141, green: 0.110, blue: 0.086)
            : Color(red: 0.945, green: 0.914, blue: 0.867)
    }

    private var cardColor: Color {
        scheme == .dark
            ? Color(red: 0.184, green: 0.149, blue: 0.118)
            : Color(red: 0.984, green: 0.969, blue: 0.941)
    }

    private var greenAccent: Color {
        scheme == .dark
            ? Color(red: 0.573, green: 0.659, blue: 0.455)
            : Color(red: 0.369, green: 0.541, blue: 0.271)
    }

    private var brownAccent: Color {
        scheme == .dark
            ? Color(red: 0.769, green: 0.541, blue: 0.384)
            : Color(red: 0.541, green: 0.353, blue: 0.231)
    }

    private var redAlert: Color {
        Color(red: 0.710, green: 0.286, blue: 0.227)
    }

    var body: some View {
        let s = entry.snapshot
        ZStack {
            bgColor
            if family == .systemSmall {
                smallView(s)
            } else {
                mediumView(s)
            }
        }
        .widgetBackground(bgColor)
    }

    @ViewBuilder
    private func smallView(_ s: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(s.overdueCount >= 3 ? "🚨 Mất ổ!" : "🐜 Tổ kiến")
                    .font(.caption.bold())
                    .foregroundColor(s.overdueCount >= 3 ? redAlert : greenAccent)
                Spacer()
                Text("Lv.\(s.queenLevel)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(greenAccent.opacity(0.18))
                    .foregroundColor(greenAccent)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(s.todayCount + s.overdueCount)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(s.overdueCount > 0 ? redAlert : greenAccent)
                Text("việc cần làm")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(s.nextTaskTitle)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .foregroundColor(.primary)

            Spacer(minLength: 0)

            HStack {
                Text("🌿 \(s.habitPercentToday)%")
                    .font(.caption2.bold())
                    .foregroundColor(greenAccent)
                Spacer()
                if s.overdueCount > 0 {
                    Text("⚠️ \(s.overdueCount)/3 trễ")
                        .font(.caption2.bold())
                        .foregroundColor(redAlert)
                } else {
                    Text("🍃 \(s.doneCount) xong")
                        .font(.caption2)
                        .foregroundColor(brownAccent)
                }
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private func mediumView(_ s: WidgetSnapshot) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(s.overdueCount >= 3 ? "🚨 Mất ổ" : "🐜 Cấp \(s.queenLevel)")
                        .font(.caption.bold())
                        .foregroundColor(s.overdueCount >= 3 ? redAlert : greenAccent)
                    Text("· \(s.queenRank)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    statBox(count: s.overdueCount, label: "Trễ/3", color: redAlert)
                    statBox(count: s.todayCount, label: "Hôm nay", color: brownAccent)
                    statBox(count: s.doneCount, label: "Xong", color: greenAccent)
                }

                Spacer(minLength: 0)

                HStack {
                    Text("🌿 Thói quen: \(s.habitPercentToday)%")
                        .font(.caption2.bold())
                        .foregroundColor(greenAccent)
                    Spacer()
                    Text("🔥 \(s.habitStreak)d")
                        .font(.caption2.bold())
                        .foregroundColor(brownAccent)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VIỆC TIẾP THEO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(brownAccent)
                    Text(s.nextTaskTitle)
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                    if !s.nextTaskDue.isEmpty {
                        Text(s.nextTaskDue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardColor)
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("THỜI KHÓA BIỂU")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(greenAccent)
                    Text(s.nextSlotTitle)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    if !s.nextSlotTime.isEmpty {
                        Text(s.nextSlotTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardColor)
                .cornerRadius(10)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
    }

    private func statBox(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(cardColor)
        .cornerRadius(8)
    }
}

extension View {
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.background(color)
        }
    }
}

@main
struct AntTrackerWidget: Widget {
    let kind: String = "AntTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AntProvider()) { entry in
            AntTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tracker Tổ kiến")
        .description("Theo dõi công việc, lịch trình và thói quen ngay trên màn hình chính.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
