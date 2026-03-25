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

/// Centralized color palette matching the Android demo app's design.
enum EmpowerPlantTheme {
    static let primary        = UIColor(hex: "#3F51B5")  // Indigo
    static let primaryDark    = UIColor(hex: "#303F9F")  // Darker indigo
    static let accent         = UIColor(hex: "#FF4081")  // Pink
    static let buttonBackground = UIColor(hex: "#6C5FC7") // Purple
    static let buttonPressed  = UIColor(hex: "#562E7D")  // Deep purple
    static let textHeader     = UIColor(hex: "#361A67")  // Dark purple for titles
    static let cardBackground = UIColor.white
    static let tableBackground = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)

    /// Applies the purple/indigo navigation bar theme globally.
    static func applyNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = primaryDark
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }
}
