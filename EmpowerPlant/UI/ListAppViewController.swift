import SentrySwift
import UIKit

/// Other issues list for the Empower TDA error-list test.
/// Row titles are the accessibility names the test looks up.
/// The home screen button opens it. No other screen has a bar button for it.
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
        Action(title: "File I/O on Main Thread", run: { [weak self] in self?.fileIOOnMainThread() }),
    ]

    private let workQueue = DispatchQueue(label: "EmpowerPlant.ListApp", qos: .userInitiated, attributes: .concurrent)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Other issues"
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
        SentrySDK.flush(timeout: 2)
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

    /// Background writes so the next TDA tap can still land. The captured error is the issue;
    /// MetricKit disk diagnostics are not delivered on the simulator.
    private func diskWriteException() {
        let reason = "Disk write storm: repeated 256KB writes for 8 seconds"
        let error = NSError(
            domain: "DiskWriteException",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: reason,
                NSDebugDescriptionErrorKey: reason,
            ]
        )
        SentrySDK.capture(error: error) { [weak self] scope in
            self?.attachDemoContext(to: scope, action: "DiskWriteException (!)", reason: reason)
        }
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
        let reason = "High CPU load: a background thread is computing pi without stopping"
        let error = NSError(
            domain: "HighCPULoad",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: reason,
                NSDebugDescriptionErrorKey: reason,
            ]
        )
        SentrySDK.capture(error: error) { [weak self] scope in
            self?.attachDemoContext(to: scope, action: "HighCPULoad", reason: reason)
        }
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
            SentrySDK.flush(timeout: 2)
            SentrySDK.crash()
        }
    }

    /// Blocks the main thread for 5 seconds. The app-hang watcher is off, so this
    /// stall is not reported as an App Hang. MetricKit is the hang reporter.
    /// The span still records the block.
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

    /// Fills the main run loop with short blocks for 5 seconds.
    /// The span finishes on the main queue after those blocks drain.
    private func anrFillingRunLoop() {
        let span = ShopTrace.begin(operation: "app.hang", description: "Fill the run loop", bindChildToScope: false)
        span.setData(value: "actions", key: "screen")
        let started = Date()
        let fillDuration: TimeInterval = 5
        workQueue.async {
            let end = Date().addingTimeInterval(fillDuration)
            while Date() < end {
                DispatchQueue.main.async {
                    let sliceEnd = Date().addingTimeInterval(0.02)
                    while Date() < sliceEnd {
                        _ = CFAbsoluteTimeGetCurrent()
                    }
                }
                Thread.sleep(forTimeInterval: 0.02)
            }
            DispatchQueue.main.async {
                let elapsedMs = Int(Date().timeIntervalSince(started) * 1000)
                span.setData(value: elapsedMs, key: "duration_ms")
                span.finish()
            }
        }
    }

    /// Main-thread file read and write. Long enough for the file-I/O-on-main-thread
    /// performance issue, and short of the 2 second hang threshold. The app stays up
    /// so the spans can be sent. The Disk write row remains a background handled error.
    private func fileIOOnMainThread() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sentry-main-thread-io.bin")
        let parent = ShopTrace.begin(
            operation: "file.io",
            description: "File I/O on Main Thread",
            bindChildToScope: false
        )
        parent.setData(value: "actions", key: "screen")
        parent.setData(value: "File I/O on Main Thread", key: "action")
        defer {
            try? FileManager.default.removeItem(at: url)
            parent.finish()
        }

        let chunk = Data(repeating: 0x42, count: 64 * 1024)
        let writeSpan = parent.startChild(operation: "file.write", description: "Write file on main thread")
        writeSpan.setData(value: "actions", key: "screen")
        writeSpan.setData(value: url.lastPathComponent, key: "file.name")
        let writeStarted = Date()
        var bytesWritten = 0
        FileManager.default.createFile(atPath: url.path, contents: nil)
        if let handle = try? FileHandle(forWritingTo: url) {
            let writeEnd = Date().addingTimeInterval(0.3)
            while Date() < writeEnd {
                do {
                    try handle.write(contentsOf: chunk)
                    bytesWritten += chunk.count
                } catch {
                    break
                }
            }
            try? handle.synchronize()
            try? handle.close()
        }
        let writeMs = Int(Date().timeIntervalSince(writeStarted) * 1000)
        writeSpan.setData(value: writeMs, key: "duration_ms")
        writeSpan.setData(value: bytesWritten, key: "file.bytes")
        writeSpan.finish()

        let readSpan = parent.startChild(operation: "file.read", description: "Read file on main thread")
        readSpan.setData(value: "actions", key: "screen")
        readSpan.setData(value: url.lastPathComponent, key: "file.name")
        let readStarted = Date()
        var bytesRead = 0
        if let handle = try? FileHandle(forReadingFrom: url) {
            let readEnd = Date().addingTimeInterval(0.2)
            while Date() < readEnd {
                let data = (try? handle.read(upToCount: chunk.count)) ?? Data()
                if data.isEmpty {
                    try? handle.seek(toOffset: 0)
                } else {
                    bytesRead += data.count
                }
            }
            try? handle.close()
        }
        let readMs = Int(Date().timeIntervalSince(readStarted) * 1000)
        readSpan.setData(value: readMs, key: "duration_ms")
        readSpan.setData(value: bytesRead, key: "file.bytes")
        readSpan.finish()
        parent.setData(value: writeMs + readMs, key: "duration_ms")
    }
}
