//
//  Utils.swift
//  EmpowerPlant
//
//  Created by Andrew McKnight on 10/6/23.
//

import UIKit

public let modifiedDBNotificationName = Notification.Name("io.sentry.empowerplants.newly-generated-db-items-available")

public func wipeDB() {
    guard let url = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
        // TODO: error
        return
    }
    
    do {
        try FileManager.default.removeItem(at: url)
    } catch {
        // TODO: error
        return
    }
}

/** Add a delay based on current version. */
public func checkRelease() {
    guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
        print("failed to read bundle version, not sleeping")
        return
    }
    
    // as a workaround to auto-incremented build numbers, we just calculate the integer sum of all segments
    // of the semantic version, e.g. 0.0.28 -> 0+0+28 = 28 -> sleep, 0.0.29 -> 0+0+29 = 29 -> no sleep
    let versionSum = versionString.components(separatedBy: ".").compactMap { Int($0) }.reduce(0, +)
    
    if versionSum % 2 == 0 {
        print("version sum is even, adding 1s sleep")
        sleep(1) // sleep takes seconds, not ms
    }
}
