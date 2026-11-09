import AudioToolbox

/// Short system click for shop button taps.
enum ShopClick {
    static func play() {
        AudioServicesPlaySystemSound(1104)
    }
}
