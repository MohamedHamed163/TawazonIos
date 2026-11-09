//
//  KeyboardDismiss.swift
//  tawazon
//

import UIKit

extension UIApplication {
    /// Installs a window-wide tap gesture that dismisses the keyboard when the
    /// user taps anywhere outside the active text field. Safe to call repeatedly.
    func registerKeyboardDismissGesture() {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        if window.gestureRecognizers?.contains(where: { $0 is KeyboardDismissTapGesture }) == true {
            return
        }

        let tap = KeyboardDismissTapGesture(
            target: KeyboardDismissGestureDelegate.shared,
            action: #selector(KeyboardDismissGestureDelegate.dismissKeyboard)
        )
        // Let taps still reach buttons, list rows, etc.
        tap.cancelsTouchesInView = false
        tap.delegate = KeyboardDismissGestureDelegate.shared
        window.addGestureRecognizer(tap)
    }
}

private final class KeyboardDismissTapGesture: UITapGestureRecognizer {}

private final class KeyboardDismissGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissGestureDelegate()

    @objc func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    /// Ignore taps that land on a text input or the system edit/selection menu so
    /// re-tapping a focused field, moving the cursor, and the copy/paste menu all
    /// keep working. Taps on any other view still dismiss the keyboard.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        var view: UIView? = touch.view
        while let current = view {
            if current is UITextField || current is UITextView {
                return false
            }
            let className = String(describing: type(of: current))
            if className.contains("UITextField")
                || className.contains("UITextView")
                || className.contains("EditMenu")
                || className.contains("TextSelection")
                || className.contains("Selection") {
                return false
            }
            view = current.superview
        }
        return true
    }
}
