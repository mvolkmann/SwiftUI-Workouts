import SwiftUI
import UIKit

private struct KeyboardDismissOnTapModifier: ViewModifier {
    let isFocused: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        content.background {
            KeyboardDismissTapInstaller {
                if isFocused.wrappedValue {
                    isFocused.wrappedValue = false
                }
            }
        }
    }
}

private struct KeyboardDismissTapInstaller: UIViewRepresentable {
    let onTapOutsideInput: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTapOutsideInput: onTapOutsideInput)
    }

    func makeUIView(context: Context) -> WindowTapInstallerView {
        let view = WindowTapInstallerView()
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator

        context.coordinator.tapGesture = tapGesture
        view.tapGesture = tapGesture

        return view
    }

    func updateUIView(_ uiView: WindowTapInstallerView, context: Context) {
        context.coordinator.onTapOutsideInput = onTapOutsideInput
    }

    static func dismantleUIView(
        _ uiView: WindowTapInstallerView,
        coordinator: Coordinator
    ) {
        uiView.removeGestureRecognizerFromWindow()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTapOutsideInput: () -> Void
        var tapGesture: UITapGestureRecognizer?

        init(onTapOutsideInput: @escaping () -> Void) {
            self.onTapOutsideInput = onTapOutsideInput
        }

        @objc func handleTap() {
            onTapOutsideInput()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            guard let touchedView = touch.view else { return true }
            return !touchedView.isKeyboardDismissExcluded
        }
    }

    final class WindowTapInstallerView: UIView {
        var tapGesture: UITapGestureRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            updateGestureRecognizerWindow()
        }

        private func updateGestureRecognizerWindow() {
            guard let tapGesture else { return }

            if tapGesture.view !== window {
                removeGestureRecognizerFromWindow()

                if let window {
                    window.addGestureRecognizer(tapGesture)
                }
            }
        }

        func removeGestureRecognizerFromWindow() {
            guard let tapGesture else { return }
            tapGesture.view?.removeGestureRecognizer(tapGesture)
        }
    }
}

private extension UIView {
    var isKeyboardDismissExcluded: Bool {
        var view: UIView? = self

        while let currentView = view {
            if currentView is UITextField || currentView is UITextView {
                return true
            }

            view = currentView.superview
        }

        return false
    }
}

extension View {
    func dismissKeyboardOnTap(_ isFocused: FocusState<Bool>.Binding) -> some View {
        modifier(KeyboardDismissOnTapModifier(isFocused: isFocused))
    }
}
