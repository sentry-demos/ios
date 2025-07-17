//
//  AppDelegate.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import UIKit
import Sentry
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // the Sentry default is to enable swizzling. we'll use that as our default as well. we check for the launch arg to disable swizzling; if it's provided, then we'll disable swizzling. if it's absent, then swizzling will be enabled.
        let enableSwizzling = !ProcessInfo.processInfo.arguments.contains("--disable-swizzling")
        
        SentrySDK.start { options in
            options.dsn = ProcessInfo.processInfo.environment["--dsn"] ?? "https://9b0dbdfd24daad3f475baa5f5adf1302@sandbox-mirror.sentry.gg/1"
            
            // set the SDK debug mode according to defaults and overrides.
            #if DEBUG
                // in debug builds, we default to enabling debug mode. the launch arg --no-debug-mode-in-debug-build is a way to override that and turn it off, like if you don't want to see the logs in the xcode console.
                options.debug = !ProcessInfo.processInfo.arguments.contains("--no-debug-mode-in-debug-build")
            #else
                // in release builds, we default to disabling debug mode. the launch arg --debug-mode-in-release-build is a way to override that and turn it on.
                options.debug = ProcessInfo.processInfo.arguments.contains("--debug-mode-in-release-build")
            #endif

            options.tracesSampleRate = 1.0
            options.profilesSampleRate = 1.0
            options.enableAppLaunchProfiling = true
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            options.enableSwizzling = enableSwizzling
            options.enablePerformanceV2 = true
            options.enableAutoPerformanceTracing = true
            options.enableTimeToFullDisplayTracing = true
            
            // Enable Mobile Session Replay
            options.sessionReplay.onErrorSampleRate = 1.0
            options.sessionReplay.sessionSampleRate = 1.0
        }
        SentrySDK.configureScope{ scope in
            scope.setTag(value: ["corporate", "enterprise", "self-serve"].randomElement() ?? "unknown", key: "customer.type")
            scope.setTag(value: ProcessInfo.processInfo.environment["USER"] ?? "tda", key: "se")
            scope.setTag(value: "\(enableSwizzling)", key: "enableSwizzling")
        }
        
        if ProcessInfo.processInfo.arguments.contains("--wipe-db") {
            wipeDB()
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
            /*
             The persistent container for the application. This implementation
             creates and returns a container, having loaded the store for the
             application to it. This property is optional since there are legitimate
             error conditions that could cause the creation of the store to fail.
             */
            let container = NSPersistentContainer(name: "Model")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            return container
        }()
        
        // MARK: - Core Data Saving support
        
        func saveContext () {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // TODO: error
                }
            }
        }


}

