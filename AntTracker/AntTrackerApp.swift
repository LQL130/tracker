import SwiftUI
import WidgetKit

@main
struct AntTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
        }
    }
}
