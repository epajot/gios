//
//  UIUtil.swift v.0.2.1
//  SwiftUtilBiP
//
//  Created by Rudolf Farkas on 04.09.18.
//  Copyright © 2018 Rudolf Farkas. All rights reserved.
//

import UIKit

/**
 Create a UIWindow with a UIViewController to present UIAlertController on it.
 from http://lazyself.io/ios/2017/05/18/present-uialertcontroller-when-not-in-a-uiviewcontroller.html
 */
extension UIAlertController {
    convenience init(alertTitle: String = "", message: String, buttonTitle: String) {
        self.init(title: alertTitle,
                  message: message,
                  preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: { (_: UIAlertAction!) in })
        addAction(action)
    }
}

extension UIViewController {
    /// Present a single-button alert
    /// - Parameters:
    ///   - title:
    ///   - message:
    ///   - buttonTitle:
    func presentSimpleAlert(alertTitle: String, message: String, buttonTitle: String) {
        let alert = UIAlertController(title: alertTitle,
                                      message: message,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: buttonTitle, style: .default, handler: { (_: UIAlertAction!) in })
        alert.addAction(action)

        present(alert, animated: true, completion: nil)
    }
}

// https://www.hackingwithswift.com/example-code/uicolor/how-to-convert-a-hex-color-to-a-uicolor
/// UIColor.init from a #rgba hex string like so:
///     let gold = UIColor(hex: "#ffe700ff")
public extension UIColor {
    convenience init(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x0000_00FF) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        self.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
}

// MARK: factory methods

// https://cocoacasts.com/elegant-controls-in-swift-with-closures
/// Button with storage for an action callback
class ButtonWithAction: UIButton {
    typealias ActionCallback = (ButtonWithAction) -> Void

    // On notification from the button calls the actionCallback
    @objc private func onTouchUpInside(sender: UIButton) {
        if let actionCallback = actionCallback {
            actionCallback(self)
        }
    }

    // Receives an assignment of a callback or nil (to remove it)
    var actionCallback: ActionCallback? {
        didSet {
            if actionCallback != nil {
                addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)
            } else {
                removeTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)
            }
        }
    }
}

/*
 Examples of creation of buttons with actions
 private lazy var backgroundColorButton = UIButton.actionButtonPref(title: "Button0", action: backgroundColorButtonTap)
 private lazy var button1 = UIButton.actionButtonPref(title: "Button1", action: { _ in self.printClassAndFunc(info: "Button1") })
 Example of removing the action
 */
extension UIButton {
    /// Returns an instance of ActionButton, configured and initializeed with an action callback.
    /// - Parameters:
    ///   - title: button title for .normal
    ///   - action: action callback
    static func actionButton(title: String, action: @escaping ButtonWithAction.ActionCallback) -> ButtonWithAction {
        let button = ButtonWithAction(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGray // uncomment for visual debugging
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle(title, for: .normal)
        button.sizeToFit()
        button.actionCallback = action
        return button
    }
}

extension UIButton {
    /// Returns an instance of UIButton, configured.
    /// - Parameter title: button title for .normal
    static func configuredButton(title: String) -> UIButton {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGray // uncomment for visual debugging
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle(title, for: .normal)
        button.sizeToFit()
        return button
    }
}

extension UIButton {
    /// Configure self
    /// - Parameters:
    ///   - imageSystemOrNamed: systemName or assets image name
    ///   - tintColor:
    ///   - pulsate:
    ///   - isHidden:
    func configure(imageSystemOrNamed: String, tintColor: UIColor? = nil, isHidden: Bool = false, pulsate: Bool = false) {
        setImage(UIImage.image(namedOrSystem: imageSystemOrNamed), for: .normal)
        imageView?.tintColor = tintColor
        if pulsate { self.pulsate(scale: 1.0) } else { stopAllAnimations() }
        self.isHidden = isHidden
    }
}

extension UIStackView {
    /// Returns a configured horizontal stack view with subviews
    /// - Parameter subviews: to add to the stack view
    static func horizontal(subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false // vital

        stackView.axis = .horizontal
        stackView.alignment = .fill // .leading .firstBaseline .center .trailing .lastBaseline
        stackView.distribution = .fillEqually // .fillEqually .fillProportionally .equalSpacing .equalCentering
        stackView.spacing = UIStackView.spacingUseSystem
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8)

        for subview in subviews {
            stackView.addArrangedSubview(subview)
        }
        return stackView
    }

    /// Returns a configured vertical stack view with subviews
    /// - Parameter subviews: to add to the stack view
    static func vertical(subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false // vital

        stackView.axis = .vertical
        stackView.alignment = .fill // .leading .firstBaseline .center .trailing .lastBaseline
        stackView.distribution = .fillEqually // .fillEqually .fillProportionally .equalSpacing .equalCentering
        stackView.spacing = UIStackView.spacingUseSystem
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        for subview in subviews {
            stackView.addArrangedSubview(subview)
        }
        return stackView
    }
}

extension UIView {
    /// Adds overlaid on top of self, stretching to cover the self
    /// - Parameters:
    ///   - overlaid: sibling view to add
    public func addSibling(overlaid: UIView) {
        if let superview = self.superview {
            superview.addSubview(overlaid)
            overlaid.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                overlaid.leftAnchor.constraint(equalTo: leftAnchor),
                overlaid.rightAnchor.constraint(equalTo: rightAnchor),
                overlaid.topAnchor.constraint(equalTo: topAnchor),
                overlaid.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
    }

    func pulsate(scale: Double) {
//        let flash1 = CABasicAnimation(keyPath: "opacity")
//        flash1.repeatCount = .infinity
//        flash1.duration = 2.0
//        flash1.fromValue = 0.1
//        flash1.toValue = 1.0
//        flash1.autoreverses = true
//        layer.add(flash1, forKey: nil)

        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.repeatCount = .infinity
        pulse.initialVelocity = 1
        pulse.speed = 1.8 // 2
        pulse.duration = 2 // 2
        pulse.fromValue = 0.1
        pulse.toValue = 1.0 * scale
        pulse.autoreverses = false
        layer.add(pulse, forKey: nil)

//        pulse.damping = 0.1
//        pulse.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
//        pulse.isRemovedOnCompletion = false
//        pulse.fillMode = .forwards
    }

    func flash() {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 1
        flash.fromValue = 0
        flash.toValue = 1
        flash.autoreverses = false
        flash.repeatCount = .infinity

//        flash.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

        layer.add(flash, forKey: nil)
    }

    func rise() {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.duration = 1.0
        flash.fromValue = 0.3
        flash.toValue = 1.0
        flash.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        flash.autoreverses = false
        flash.repeatCount = 0 // .infinity
        layer.add(flash, forKey: nil)
    }

    func stopAllAnimations() {
        layer.removeAllAnimations()
        alpha = 1
    }
}

extension NSObject {
    func vibrateLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

extension UITextField {
    func setIcon(_ image: UIImage, width: Double) {
        let iconView = UIImageView(frame:
            CGRect(x: 10, y: 5, width: width, height: width))
        iconView.image = image
        let iconContainerView = UIView(frame:
            CGRect(x: 10, y: 0, width: 30, height: 30))
        iconContainerView.addSubview(iconView)
        leftView = iconContainerView
        leftViewMode = .always
    }

    func setIcon2(_ image: UIImage, width: Double) {
        let iconView = UIImageView(frame:
            CGRect(x: 0, y: 0, width: width, height: width))
        iconView.image = image
        let iconContainerView = UIView(frame:
            CGRect(x: 10, y: 0, width: 20, height: 20))
        iconContainerView.addSubview(iconView)
        leftView = iconContainerView
        leftViewMode = .always
    }
}

extension UIImage {
    static func image(namedOrSystem: String) -> UIImage? {
        if let image = UIImage(systemName: namedOrSystem) {
            return image
        } else {
            return UIImage(named: namedOrSystem)
        }
    }

    // return a monochrome version of self
    var monochrome: UIImage? {
        guard let currentCGImage = cgImage else { return nil }
        let currentCIImage = CIImage(cgImage: currentCGImage)

        guard let filter = CIFilter(name: "CIColorMonochrome") else { return nil }

        filter.setValue(currentCIImage, forKey: "inputImage")
        // set a gray value for the tint color
        filter.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: "inputColor")
        filter.setValue(1.0, forKey: "inputIntensity")

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        guard let cgimg = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        let processedImage = UIImage(cgImage: cgimg)
        print(processedImage.size)

        return processedImage
    }

    // Convert the black-on-white QR code image to white-on-transparent image
    var convertForDisplay: UIImage? {
        guard let colorInvertFilter = CIFilter(name: "CIColorInvert") else {
            return nil
        }
        colorInvertFilter.setValue(ciImage, forKey: "inputImage")
        guard let output1 = colorInvertFilter.outputImage else {
            return nil
        }
        guard let maskToAlphaFilter = CIFilter(name: "CIMaskToAlpha") else {
            return nil
        }
        maskToAlphaFilter.setValue(output1, forKey: "inputImage")
        guard let output2 = maskToAlphaFilter.outputImage else {
            return nil
        }
        return UIImage(ciImage: output2)
    }

    /// Rescale image to size
    /// from https://www.advancedswift.com/resize-uiimage-no-stretching-swift/
    /// - Parameter newSize:
    /// - Returns: rescaled image
    func imageWithSize(scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension UIView {
    /// Print recursively the view and subviews
    /// - Parameter indent: indent (more for each level)
    func printSubviews(indent: String = "") {
        print("\(indent)\(self)")
        let indent = indent + "| "
        for sub in subviews {
            sub.printSubviews(indent: indent)
        }
    }
}
