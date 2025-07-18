//
//  SlowOperations.swift
//  EmpowerPlant
//
//  Created by Andrew McKnight on 7/17/25.
//

import Foundation

/// Utilities to simulate slow operations, to help demonstrate how Sentry can help pinpoint such issues in real apps.
struct SlowOperation {
    /// Simulate a long-running file write operation by building a large string and writing it to disk, then deleting it again.
    static public func fileWrite() {
        let longString = String(repeating: UUID().uuidString, count: 5_000_000)
        let data = longString.data(using: .utf8)!
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent("tmp" + UUID().uuidString)
        try! data.write(to: filePath)
        try! FileManager.default.removeItem(at: filePath)
    }

    /// Simulate a long-running file read operation by slowly calculate a number of times to iterate, then depth-first search a directory structure that many times.
    static public func fileRead() {
        let path = FileManager.default.currentDirectoryPath
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: path)
            let loop = fibonacciSeries(num: items.count)
            for _ in 1...loop {
                readDirectory(path: path)
            }
        } catch {
            // TODO: error
        }
    }

    /// Simulate a long-running CPU-bound operation
    static public func computation() {
        _ = getIterator(42);
        sleep(50 / 1000)
    }
}

private extension SlowOperation {
    static func readDirectory(path: String) {
        let fm = FileManager.default

        do {
            let items = try fm.contentsOfDirectory(atPath: path)

            for item in items {
                var isDirectory: ObjCBool = false
                // TODO: check the value of isDirectory after fileExists, unless we want the errors to happen when calling contentsOfDirectory on a path that's not a directory?
                if fm.fileExists(atPath: item, isDirectory: &isDirectory) {
                    readDirectory(path: item)
                } else {
                    return
                }
            }
        } catch {
            // TODO: error
        }
    }

    static func fibonacciSeries(num: Int) -> Int{
        // The value of 0th and 1st number of the fibonacci series are 0 and 1
        var n1 = 0
        var n2 = 1

        // To store the result
        var nR = 0
        // Adding two previous numbers to find ith number of the series
        for _ in 0..<num{
            nR = n1
            n1 = n2
            n2 = nR + n2
        }

        if (n1 < 500) {
            return fibonacciSeries(num: n1)
        }
        return n1
    }

    static func getIterator(_ n: Int) -> Int {
       if (n <= 0) {
           return 0;
       }
       if (n == 1 || n == 2) {
           return 1;
       }
       return getIterator(n - 1) + getIterator(n - 2);
    }
}
