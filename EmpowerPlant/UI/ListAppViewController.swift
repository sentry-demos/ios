import SentrySwift
import UIKit

/// Debug actions for the Empower TDA error-list test.
/// Row titles are the accessibility names the test looks up.
/// The succulent home screen opens it. No other screen has a bar button for it.
final class ListAppViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private struct Action {
        let title: String
        let run: () -> Void
    }

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "action")
        return table
    }()

    private lazy var actions: [Action] = [
        Action(title: "Error", run: { [weak self] in self?.captureError() }),
        Action(title: "NSException", run: { [weak self] in self?.captureNSException() }),
        Action(title: "Fatal Error", run: { [weak self] in self?.captureFatalError() }),
        Action(title: "DiskWriteException (!)", run: { [weak self] in self?.diskWriteException() }),
        Action(title: "HighCPULoad", run: { [weak self] in self?.highCPULoad() }),
        Action(title: "Permissions (!)", run: { [weak self] in self?.permissions() }),
        Action(title: "Async Crash (!)", run: { [weak self] in self?.asyncCrash() }),
        Action(title: "ANR Fully Blocking", run: { [weak self] in self?.anrFullyBlocking() }),
        Action(title: "ANR Filling Run Loop", run: { [weak self] in self?.anrFillingRunLoop() }),
    ]

    private let workQueue = DispatchQueue(label: "EmpowerPlant.ListApp", qos: .userInitiated, attributes: .concurrent)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Actions"
        view.backgroundColor = EmpowerPlantTheme.tableBackground
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ShopPrivacy.unmaskNavigationButtons(of: self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
        let title = actions[indexPath.row].title
        cell.textLabel?.text = title
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.textLabel?.textColor = EmpowerPlantTheme.textHeader
        // The TDA test looks up XCUIElementTypeStaticText by these names.
        cell.isAccessibilityElement = false
        cell.textLabel?.isAccessibilityElement = true
        cell.textLabel?.accessibilityIdentifier = title
        if let label = cell.textLabel {
            ShopPrivacy.unmask(label)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        ShopClick.play()
        actions[indexPath.row].run()
    }

    private func captureError() {
        let error = DemoFailure.make()
        let reason = error.localizedDescription
        ErrorToastManager.shared.logErrorAndShowToast(error: error, message: reason) { [weak self] scope in
            self?.attachDemoContext(to: scope, action: "Error", reason: reason)
        }
    }

    private func captureNSException() {
        let reason = "Checkout failed: the order total could not be confirmed before payment"
        let exception = NSException(
            name: NSExceptionName("CheckoutFlowException"),
            reason: reason,
            userInfo: nil
        )
        SentrySDK.capture(exception: exception) { [weak self] scope in
            scope.setLevel(.fatal)
            self?.attachDemoContext(to: scope, action: "NSException", reason: reason)
        }
    }

    private func captureFatalError() {
        let reason = "Checkout crashed: the payment session was missing"
        SentrySDK.configureScope { [weak self] scope in
            self?.attachDemoContext(to: scope, action: "Fatal Error", reason: reason)
        }
        fatalError(reason)
    }

    private func attachDemoContext(to scope: Scope, action: String, reason: String) {
        scope.setTag(value: "actions", key: "screen")
        scope.setTag(value: action, key: "action")
        scope.setContext(
            value: [
                "screen": "actions",
                "action": action,
                "reason": reason,
            ],
            key: "demo"
        )
    }

    /// Background writes so the next TDA tap can still land. MetricKit reports the disk exception.
    private func diskWriteException() {
        let span = ShopTrace.begin(operation: "file.write", description: "Disk write", bindChildToScope: false)
        span.setData(value: 8000, key: "duration_ms")
        span.setData(value: "actions", key: "screen")
        workQueue.async {
            let chunk = Data(repeating: 0x41, count: 256 * 1024)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("sentry-disk-write.bin")
            let end = Date().addingTimeInterval(8)
            while Date() < end {
                try? chunk.write(to: url)
            }
            try? FileManager.default.removeItem(at: url)
            span.finish()
        }
    }

    private func highCPULoad() {
        workQueue.async {
            while true {
                _ = Self.calcPi()
            }
        }
    }

    private static func calcPi() -> Double {
        var denominator = 1.0
        var pi = 0.0
        for i in 0..<10_000_000 {
            if i % 2 == 0 {
                pi += 4 / denominator
            } else {
                pi -= 4 / denominator
            }
            denominator += 2
        }
        return pi
    }

    /// A real permission failure that does not abort the process.
    private func permissions() {
        let protected = URL(fileURLWithPath: "/var/root/sentry-demo-permission")
        do {
            _ = try Data(contentsOf: protected)
        } catch {
            SentrySDK.capture(error: error)
        }
    }

    private func asyncCrash() {
        DispatchQueue.main.async { [weak self] in
            self?.asyncCrash1()
        }
    }

    private func asyncCrash1() {
        DispatchQueue.main.async { [weak self] in
            self?.asyncCrash2()
        }
    }

    private func asyncCrash2() {
        DispatchQueue.main.async {
            SentrySDK.crash()
        }
    }

    /// Blocks the main thread. Sentry's hang watcher stays off; MetricKit can still report it.
    private func anrFullyBlocking() {
        let span = ShopTrace.begin(operation: "app.hang", description: "Block main thread", bindChildToScope: false)
        span.setData(value: 5000, key: "duration_ms")
        span.setData(value: "actions", key: "screen")
        let end = Date().addingTimeInterval(5)
        var i = 0
        while Date() < end {
            i &+= Int.random(in: 0...10)
            i &-= 1
        }
        span.finish()
    }

    /// Fills the main run loop with short blocks instead of one long sleep.
    private func anrFillingRunLoop() {
        let span = ShopTrace.begin(operation: "app.hang", description: "Fill the run loop", bindChildToScope: false)
        span.setData(value: "actions", key: "screen")
        let started = Date()
        workQueue.async {
            for _ in 0...100_000 {
                DispatchQueue.main.async {
                    _ = CFAbsoluteTimeGetCurrent()
                }
            }
            DispatchQueue.main.async {
                let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)
                span.setData(value: elapsedMs, key: "duration_ms")
                span.finish()
            }
        }
    }
}
