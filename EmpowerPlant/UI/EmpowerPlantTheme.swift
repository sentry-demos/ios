import SentrySwift
import UIKit

// MARK: - UIColor Hex Initializer

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat((rgb & 0x0000FF)) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - EmpowerPlant Theme

/// Shop chrome uses the Empower Plant leaf green from the React Native logo and the Android launcher.
enum EmpowerPlantTheme {
    static let primary = UIColor(hex: "#9BA547")
    static let primaryDark = UIColor(hex: "#9BA547")
    static let accent = UIColor(hex: "#FF4081")  // Pink
    static let buttonBackground = UIColor(hex: "#9BA547")
    static let buttonPressed = UIColor(hex: "#9BA547")
    static let textHeader = UIColor(hex: "#9BA547")
    static let cardBackground = UIColor.white
    static let tableBackground = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)

    /// Light green bar. Titles and icons stay dark so they remain readable.
    static func applyNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = primaryDark
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .black
    }
}
