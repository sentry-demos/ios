import UIKit

public class InAppDebugMenu: NSObject {
    public static let shared = InAppDebugMenu()

    static var displayingMenu = false

    let window = {
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return Window(windowScene: scene)
            }
        }
        return Window()
    }()

    lazy var rootVC = {
        let uivc = UIViewController(nibName: nil, bundle: nil)
        uivc.view.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: uivc.view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            button.bottomAnchor.constraint(equalTo: uivc.view.safeAreaLayoutGuide.bottomAnchor, constant: -75),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalTo: button.widthAnchor, multiplier: 1)
        ])

        return uivc
    }()

    lazy var button = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(displayDebugMenu), for: .touchUpInside)
        button.setImage(UIImage(systemName: "wrench.and.screwdriver"), for: .normal)
        button.contentMode = .scaleAspectFill
        button.tintColor = .darkGray

        button.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(pannedButton(recognizer:))))

        return button
    }()

    @objc public func pannedButton(recognizer: UIPanGestureRecognizer) {
        let deltas = recognizer.translation(in: rootVC.view);
        let transform = CGAffineTransformMakeTranslation(deltas.x, deltas.y);
        button.center = CGPointApplyAffineTransform(button.center, transform);
        recognizer.setTranslation(.zero, in:rootVC.view);

    }

    @objc public func display() {
        window.rootViewController = rootVC
        window.isHidden = false
    }

    @objc func displayDebugMenu() {
        InAppDebugMenu.displayingMenu = true

        let listVC = DSNDisplayViewController(nibName: nil, bundle: nil)
        listVC.presentationController?.delegate = self
        rootVC.present(listVC, animated: true)
    }

    class Window: UIWindow {

        @available(iOS 13.0, *)
        override init(windowScene: UIWindowScene) {
            super.init(windowScene: windowScene)
            commonInit()
        }

        init() {
            super.init(frame: UIScreen.main.bounds)
            commonInit()
        }

        func commonInit() {
            windowLevel = UIWindow.Level.alert + 1
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            guard !InAppDebugMenu.displayingMenu else {
                return super.hitTest(point, with: event)
            }

            guard let result = super.hitTest(point, with: event) else {
                return nil
            }
            guard result.isKind(of: UIButton.self) else {
                return nil
            }
            return result
        }
    }
}

extension InAppDebugMenu: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        rootVC.dismiss(animated: true)
        InAppDebugMenu.displayingMenu = false
    }
}
