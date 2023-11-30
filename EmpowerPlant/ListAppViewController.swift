//
//  ListAppViewController.swift
//  EmpowerPlant
//
//  Created by William Capozzoli on 3/8/22.
//

import BigInt
import Sentry
import UIKit

class ListAppViewController: UIViewController {

    
    @IBOutlet weak var dsnTextField: UITextField!
    @IBOutlet weak var anrFullyBlockingButton: UIButton!
    @IBOutlet weak var anrFillingRunLoopButton: UIButton!
    @IBOutlet weak var framesLabel: UILabel!
    @IBOutlet weak var breadcrumbLabel: UILabel!
    
    private let dispatchQueue = DispatchQueue(label: "ViewController", attributes: .concurrent)
    //private let diskWriteException = DiskWriteException()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Actions"
        activityIndicator.isHidden = true
    }
    
    @IBAction func addBreadcrumb(_ sender: Any) {
        let crumb = Breadcrumb(level: SentryLevel.info, category: "Debug")
        crumb.message = "tapped addBreadcrumb"
        crumb.type = "user"
        SentrySDK.addBreadcrumb(crumb)
    }
    
    @IBAction func captureMessage(_ sender: Any) {
        let eventId = SentrySDK.capture(message: "Yeah captured a message")
        // Returns eventId in case of successfull processed event
        // otherwise nil
        print("\(String(describing: eventId))")
    }
    
    @IBAction func uiClickTransaction(_ sender: Any) {
        dispatchQueue.async {
            if let path = Bundle.main.path(forResource: "LoremIpsum", ofType: "txt") {
                _ = FileManager.default.contents(atPath: path)
            }
        }

        guard let imgUrl = URL(string: "https://sentry-brand.storage.googleapis.com/sentry-logo-black.png") else {
            return
        }
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let dataTask = session.dataTask(with: imgUrl) { (_, _, _) in }
        dataTask.resume()
    }
    
    @IBAction func captureUserFeedback(_ sender: Any) {
        let error = NSError(domain: "UserFeedbackErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "This never happens."])

        let eventId = SentrySDK.capture(error: error) { scope in
            scope.setLevel(.fatal)
        }
        
        let userFeedback = UserFeedback(eventId: eventId)
        userFeedback.comments = "It broke on iOS-Swift. I don't know why, but this happens."
        userFeedback.email = "john@me.com"
        userFeedback.name = "John Me"
        SentrySDK.capture(userFeedback: userFeedback)
    }
    
    @IBAction func captureError(_ sender: Any) {
        
        do {
            try RandomErrorGenerator.generate()
        } catch {
            SentrySDK.capture(error: error) { (scope) in
                // Changes in here will only be captured for this event
                // The scope in this callback is a clone of the current scope
                // It contains all data but mutations only influence the event being sent
                scope.setTag(value: "value", key: "myTag")
            }
            // TODO: error
        }
         
    }
    
    @IBAction func captureNSException(_ sender: Any) {
        let exception = NSException(name: NSExceptionName("My Custom exeption"), reason: "User clicked the button", userInfo: nil)
        let scope = Scope()
        scope.setLevel(.fatal)
        // !!!: By explicity just passing the scope, only the data in this scope object will be added to the event; the global scope (calls to configureScope) will be ignored. If you do that, be careful–a lot of useful info is lost. If you just want to mutate what's in the scope use the callback, see: captureError.
        SentrySDK.capture(exception: exception, scope: scope)
    }
    
    @IBAction func captureFatalError(_ sender: Any) {
        fatalError("This is a fatal error. Oh no 😬.")
    }
    
    @IBAction func captureTransaction(_ sender: Any) {
        let transaction = SentrySDK.startTransaction(name: "Some Transaction", operation: "Some Operation")
        /*
        //Below Breaks
        transaction.setMeasurement(name: "duration", value: 44, unit: MeasurementUnitDuration.nanosecond)
        transaction.setMeasurement(name: "information", value: 44, unit: MeasurementUnitInformation.bit)
        transaction.setMeasurement(name: "duration-custom", value: 22, unit: MeasurementUnit(unit: "custom"))
        */ //Above Breaks
        let span = transaction.startChild(operation: "user", description: "calls out")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            span.finish()
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.4...0.6), execute: {
            transaction.finish()
        })
    }
   
    @IBAction func crash(_ sender: Any) {
        SentrySDK.crash()
    }

    // swiftlint:disable force_unwrapping
    @IBAction func unwrapCrash(_ sender: Any) {
        let a: String! = nil
        let b: String = a!
        print(b)
    }
    // swiftlint:enable force_unwrapping
    @IBAction func asyncCrash(_ sender: Any) {
        DispatchQueue.main.async {
            self.asyncCrash1()
        }
    }
    
    func asyncCrash1() {
        DispatchQueue.main.async {
            self.asyncCrash2()
        }
    }
    
    func asyncCrash2() {
        DispatchQueue.main.async {
            SentrySDK.crash()
        }
    }

    @IBAction func oomCrash(_ sender: Any) {
        DispatchQueue.main.async {
            let megaByte = 1_024 * 1_024
            let memoryPageSize = NSPageSize()
            let memoryPages = megaByte / memoryPageSize

            while true {
                // Allocate one MB and set one element of each memory page to something.
                let ptr = UnsafeMutablePointer<Int8>.allocate(capacity: megaByte)
                for i in 0..<memoryPages {
                    ptr[i * memoryPageSize] = 40
                }
            }
        }
    }
    
    @IBAction func diskWriteException(_ sender: Any) {
        //diskWriteException.continuouslyWriteToDisk()
        
        // As we are writing to disk continuously we would keep adding spans to this UIEventTransaction.
        SentrySDK.span?.finish()
    }
    
    @IBAction func highCPULoad(_ sender: Any) {
        dispatchQueue.async {
            while true {
                _ = self.calcPi()
            }
        }
    }
    
    private func calcPi() -> Double {
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

    @IBAction func anrFullyBlocking(_ sender: Any) {
        let buttonTitle = self.anrFullyBlockingButton.currentTitle
        var i = 0
        
        for _ in 0...5_000_000 {
            i += Int.random(in: 0...10)
            i -= 1
            
            self.anrFullyBlockingButton.setTitle("\(i)", for: .normal)
        }
        
        self.anrFullyBlockingButton.setTitle(buttonTitle, for: .normal)
    }
    
    @IBAction func anrFillingRunLoop(_ sender: Any) {
        let buttonTitle = self.anrFillingRunLoopButton.currentTitle
        var i = 0

        dispatchQueue.async {
            for _ in 0...100_000 {
                i += Int.random(in: 0...10)
                i -= 1
                
                DispatchQueue.main.async {
                    self.anrFillingRunLoopButton.setTitle("Work in Progress \(i)", for: .normal)
                }
            }
            
            DispatchQueue.main.async {
                self.anrFillingRunLoopButton.setTitle(buttonTitle, for: .normal)
            }
        }
    }
    
    @IBAction func dsnChanged(_ sender: UITextField) {
        let options = Options()
        options.dsn = sender.text
        
        if let dsn = options.dsn {
            sender.backgroundColor = UIColor.systemGreen
            
            dispatchQueue.async {
                //DSNStorage.shared.saveDSN(dsn: dsn)
            }
        } else {
            sender.backgroundColor = UIColor.systemRed
            
            dispatchQueue.async {
                //DSNStorage.shared.deleteDSN()
            }
        }
    }
    
    @IBAction func close(_ sender: Any) {
        SentrySDK.close()
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @available(iOS 15.0, *)
    @IBAction func imageOnMain(_ sender: Any) {
        imageView.isHidden = false
        let span = SentrySDK.startTransaction(name: "test", operation: "image-on-main")
        imageView.image = UIImage(named: "jwt-deep-field.png")
        span.finish()
    }
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    @IBAction func jsonMainThread(_ sender: Any) {
        // build up a huge JSON structure
        progressIndicator.isHidden = false
        DispatchQueue.global(qos: .utility).async {
            var dict = [String: String]()
            let limit = 1_000_000
            for i in 0..<limit {
                dict["\(i)"] = "\(i)\(i)"
                DispatchQueue.main.async {
                    self.progressIndicator.progress = Float(i) / Float(limit)
                }
            }
            let data = try! JSONSerialization.data(withJSONObject: dict)
            DispatchQueue.main.async {
                let span = SentrySDK.startTransaction(name: "test", operation: "json-on-main")
                let _ = try! JSONSerialization.jsonObject(with: data)
                span.finish()
                self.progressIndicator.isHidden = true
            }
        }
    }

    @IBAction func regexOnMainThread(_ sender: Any) {
        let string = try! String(contentsOf: Bundle.main.url(forResource: "mobydick", withExtension: "txt")!)
        let regex = try! NSRegularExpression(pattern: "([Tt]he)?.*([Ww]hale)")
        let span = SentrySDK.startTransaction(name: "test", operation: "regex-on-main")
        regex.matches(in: string, range: NSMakeRange(0, string.count))
        span.finish()
    }
    
    @IBAction func fileIoOnMainThread(_ sender: Any) {
        progressIndicator.isHidden = false
        DispatchQueue.global(qos: .utility).async {
            let longString = String(repeating: UUID().uuidString, count: 5_000_000)
            let data = longString.data(using: .utf8)!
            let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("tmp" + UUID().uuidString)
            DispatchQueue.main.async {
                let transaction = SentrySDK.startTransaction(name: "test", operation: "fileio-on-main", bindToScope: true)
                try! data.write(to: filePath)
                transaction.finish()
                self.progressIndicator.isHidden = true
                DispatchQueue.global(qos: .utility).async {
                    try! FileManager.default.removeItem(at: filePath)
                }
            }
        }
    }
    
    // !!!: profiling doesn't correctly collect backtraces with this (armcknight 12 Oct 2023)
    func factorialRecursive(int x: BigInt) -> BigInt {
        if x == 0 { return 1 }
        return x * factorialRecursive(int: x - 1)
    }
    
    func factorialIterative(int x: BigInt) -> BigInt {
        var i: BigInt = x
        var result: BigInt = 1
        while i > 0 {
            result *= i
            i -= 1
        }
        return result
    }
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func simulateDroppedFrame(_ sender: Any) {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        let span = SentrySDK.startTransaction(name: "test", operation: "gpu-frame-drop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let _ = self.factorialIterative(int: 15_000)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                span.finish()
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
            }
        }
    }
}
