import Foundation
import SentrySwift

/*
 Cannot dynamically set KeyId's like in javascript, so coding the product names into the Quantities class

 The following code fails because you can't add key names on the go
    self.instance.quantities.setValue(1, forKey: "someProperty")
    self.instance.quantities.value(forKey: "someProperty"))
 */
class Quantities: NSObject {

    var _name: Int = 0
    var name: Int {
        get {
            return _name
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.name updated",
                attributes: [
                    "newValue": newVal
                ])
            _name = newVal
        }
    }

    var _plantMood: Int = 0
    var plantMood: Int {
        get {
            return _plantMood
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.plantMood updated",
                attributes: [
                    "newValue": newVal
                ])
            _plantMood = newVal
        }
    }

    var _botanaVoice: Int = 0
    var botanaVoice: Int {
        get {
            return _botanaVoice
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.botanaVoice updated",
                attributes: [
                    "newValue": newVal
                ])
            _botanaVoice = newVal
        }
    }

    var _plantStroller: Int = 0
    var plantStroller: Int {
        get {
            return _plantStroller
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.plantStroller updated",
                attributes: [
                    "newValue": newVal
                ])
            _plantStroller = newVal
        }
    }

    var _plantNodes: Int = 0
    var plantNodes: Int {
        get {
            return _plantNodes
        }
        set(newVal) {
            SentrySDK.logger.debug(
                "Quantities.plantNodes updated",
                attributes: [
                    "newValue": newVal
                ])
            _plantNodes = newVal
        }
    }
}
