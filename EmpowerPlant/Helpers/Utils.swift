//
//  Utils.swift
//  EmpowerPlant
//
//  Created by Andrew McKnight on 10/6/23.
//

import UIKit
import Sentry

public let modifiedDBNotificationName = Notification.Name("io.sentry.empowerplants.newly-generated-db-items-available")

enum DBError: Error {
    case noPersistentStore
}

public func wipeDB() {
    let logger = SentrySDK.logger
    logger.warn("Database wipe operation started")
    
    guard let url = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
        logger.error("Failed to locate database file for wiping")
        ErrorToastManager.shared.logErrorAndShowToast(
            error: DBError.noPersistentStore,
            message: "Failed to locate database file for wiping"
        )
        return
    }
    
    do {
        try FileManager.default.removeItem(at: url)
        logger.info("Database successfully wiped", attributes: [
            "databasePath": url.absoluteString
        ])
    } catch {
        logger.error("Failed to wipe database file", attributes: [
            "error": error.localizedDescription,
            "databasePath": url.absoluteString
        ])
        ErrorToastManager.shared.logErrorAndShowToast(
            error: error,
            message: "Failed to wipe database file"
        )
        return
    }
}

/** Add a delay based on current version. */
public func checkRelease() {
    let logger = SentrySDK.logger
    
    guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
        logger.warn("Failed to read bundle version, not adding version-based delay")
        print("failed to read bundle version, not sleeping")
        return
    }
    
    // as a workaround to auto-incremented build numbers, we just calculate the integer sum of all segments
    // of the semantic version, e.g. 0.0.28 -> 0+0+28 = 28 -> sleep, 0.0.29 -> 0+0+29 = 29 -> no sleep
    let versionSum = versionString.components(separatedBy: ".").compactMap { Int($0) }.reduce(0, +)
    
    if versionSum % 2 == 0 {
        logger.info("version sum is even, adding 1s sleep", attributes: [
            "version": versionString,
            "delaySeconds": 1
        ])
        sleep(1) // sleep takes seconds, not ms
    }
}
