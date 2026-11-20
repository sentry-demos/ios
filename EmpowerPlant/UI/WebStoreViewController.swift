import SentrySwift
import UIKit
import WebKit

/// The Empower Plant React web store in a `WKWebView`. It demos `options.webViewTracing`:
/// the SDK writes the app's current trace as `sentry-trace` / `baggage` `<meta>` tags, and
/// the page's `@sentry/react` pageload continues it. One trace runs from the app through the
/// web page to the backend.
final class WebStoreViewController: UIViewController {

    /// Must match an entry in `options.webViewTracing.allowedHosts`.
    static let host = "empower-plant.com"

    /// Open `/products` (not `/`) so the products page is the web pageload. Only the pageload
    /// continues the injected trace, and it fetches /products from the backend.
    private static let path = "/products"

    private let webView: WKWebView = {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.accessibilityIdentifier = "webview-store"
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()

    /// Child of this screen's `ui.load` transaction, spanning the WebView load.
    private var loadSpan: Span?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Web Store"
        view.backgroundColor = .white

        view.addSubview(webView)
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        webView.navigationDelegate = self

        SentrySDK.configureScope { scope in
            scope.setTag(value: "web_store", key: "screen")
        }

        // Load here, while this screen's `ui.load` transaction is the active span: the SDK's
        // `load` swizzle injects that trace, so the web pageload nests under this screen.
        // Time to full display keeps `ui.load` open (and active) until the page finishes.
        let url = Self.makeURL()
        loadSpan = SentrySDK.span?.startChild(operation: "ui.webview.load", description: "webview/empower-plant")
        loadSpan?.setData(value: url.absoluteString, key: "url")
        SentrySDK.logger.info(
            "Loading web store",
            attributes: [
                "screen": "web_store",
                "url": url.absoluteString,
            ])
        spinner.startAnimating()
        webView.load(URLRequest(url: url))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // The user left before the page finished loading.
        finishLoad(status: .cancelled)
    }

    /// Same query the React Native WebView tab uses: Flask backend, SE, and the app's user, so
    /// web events are attributed to the same user.
    private static func makeURL() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = [
            URLQueryItem(name: "backend", value: "flask"),
            URLQueryItem(name: "se", value: ShopSession.se),
            URLQueryItem(name: "userEmail", value: ShopSession.email),
        ]
        // Fixed components, so this never fails.
        return components.url!
    }

    /// Ends the load once. Later navigations inside the page no-op.
    private func finishLoad(status: SentrySpanStatus, error: Error? = nil) {
        guard let span = loadSpan else { return }
        loadSpan = nil
        spinner.stopAnimating()
        if let error {
            span.setData(value: error.localizedDescription, key: "error")
            SentrySDK.logger.error(
                "Web store failed to load",
                attributes: [
                    "screen": "web_store",
                    "error": error.localizedDescription,
                ])
        }
        span.finish(status: status)
        SentrySDK.reportFullyDisplayed()
    }
}

extension WebStoreViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishLoad(status: .ok)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishLoad(status: .internalError, error: error)
    }

    func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error
    ) {
        finishLoad(status: .internalError, error: error)
    }
}
