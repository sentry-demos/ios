import SentrySwift
import UIKit

/// Debug actions for the Empower TDA error-list test.
/// Row titles are the accessibility names the test looks up.
/// The screen stays in the app, with no navigation-bar button that opens it.
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
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        ShopClick.play()
        actions[indexPath.row].run()
    }

    private func captureError() {
        do {
            try RandomErrorGenerator.generate()
        } catch {
            ErrorToastManager.shared.logErrorAndShowToast(
                error: error,
                message: "A random error occurred while testing the app"
            ) { scope in
                scope.setTag(value: "value", key: "myTag")
            }
        }
    }

    private func captureNSException() {
        let exception = NSException(
            name: NSExceptionName("My Custom exeption"),
            reason: "User clicked the button",
            userInfo: nil
        )
        let scope = Scope()
        scope.setLevel(.fatal)
        SentrySDK.capture(exception: exception, scope: scope)
    }

    private func captureFatalError() {
        fatalError("You've encountered a fatal error. Bummer. 😬")
    }

    /// Background writes so the next TDA tap can still land. MetricKit reports the disk exception.
    private func diskWriteException() {
        workQueue.async {
            let chunk = Data(repeating: 0x41, count: 256 * 1024)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("sentry-disk-write.bin")
            let end = Date().addingTimeInterval(8)
            while Date() < end {
                try? chunk.write(to: url)
            }
            try? FileManager.default.removeItem(at: url)
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
        let end = Date().addingTimeInterval(5)
        var i = 0
        while Date() < end {
            i &+= Int.random(in: 0...10)
            i &-= 1
        }
    }

    /// Fills the main run loop with short blocks instead of one long sleep.
    private func anrFillingRunLoop() {
        workQueue.async {
            for _ in 0...100_000 {
                DispatchQueue.main.async {
                    _ = CFAbsoluteTimeGetCurrent()
                }
            }
        }
    }
}
