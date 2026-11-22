import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        OfflineTrackerWebView()
            .ignoresSafeArea(.all)
    }
}

struct OfflineTrackerWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        let bridge = WebViewBridge()
        context.coordinator.bridge = bridge
        contentController.add(bridge, name: "trackerBridge")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.945, green: 0.914, blue: 0.867, alpha: 1.0)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false

        if let htmlURL = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") ??
                         Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator {
        var bridge: WebViewBridge?
    }
}
