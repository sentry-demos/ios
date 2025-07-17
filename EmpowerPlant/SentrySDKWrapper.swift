import Sentry

struct SentrySDKWrapper {
    // the Sentry default is to enable swizzling. we'll use that as our default as well. we check for the launch arg to disable swizzling; if it's provided, then we'll disable swizzling. if it's absent, then swizzling will be enabled.
    static let enableSwizzling = !ProcessInfo.processInfo.arguments.contains("--disable-swizzling")

    static func start() {
        SentrySDK.start { options in
            options.dsn = DSNStorage.shared.getDSN()

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
    }

    static func reload() {
        SentrySDK.close()
        start()
    }
}
