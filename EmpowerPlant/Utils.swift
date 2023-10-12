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
