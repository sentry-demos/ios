import SentrySwift
import UIKit

public let modifiedDBNotificationName = Notification.Name("io.sentry.empowerplants.newly-generated-db-items-available")

enum DBError: Error {
    case noPersistentStore
}

public func wipeDB() {
    let logger = SentrySDK.logger
    logger.warn("Database wipe operation started")

    guard
        let url = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.persistentStoreCoordinator
            .persistentStores.first?.url
    else {
        logger.error("Failed to locate database file for wiping")

        ErrorToastManager.shared.logErrorAndShowToast(
            error: DBError.noPersistentStore,
            message: "Failed to locate database file for wiping"
        )
        return
    }

    do {
        try FileManager.default.removeItem(at: url)
        logger.info(
            "Database successfully wiped",
            attributes: [
                "databasePath": url.absoluteString
            ])
    } catch {
        logger.error(
            "Failed to wipe database file",
            attributes: [
                "error": error.localizedDescription,
                "databasePath": url.absoluteString,
            ])
        ErrorToastManager.shared.logErrorAndShowToast(
            error: error,
            message: "Failed to wipe database file"
        )
        return
    }
}

/// Even app versions sleep for one second so that release shows a slow span. Odd versions skip it.
/// The check sums the version numbers because build numbers are auto-incremented (0.0.28 -> 28).
public func checkRelease(screen: String) {
    let logger = SentrySDK.logger

    guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
        logger.warn("Failed to read bundle version, not adding version-based delay")
        print("failed to read bundle version, not sleeping")
        return
    }

    let versionSum = versionString.components(separatedBy: ".").compactMap { Int($0) }.reduce(0, +)

    if versionSum % 2 == 0 {
        logger.info(
            "version sum is even, adding 1s sleep",
            attributes: [
                "version": versionString,
                "delaySeconds": 1,
            ])
        let span = ShopTrace.begin(operation: "release.wait", description: "Version check wait", bindChildToScope: false)
        span.setData(value: 1000, key: "duration_ms")
        span.setData(value: screen, key: "screen")
        span.setData(value: versionString, key: "app.version")
        sleep(1)  // sleep takes seconds, not ms
        span.finish()
    }
}
