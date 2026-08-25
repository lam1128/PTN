#if os(macOS)
import AppKit
import SwiftUI

struct InlineNumericTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let textColor: NSColor
    let font: NSFont
    let onCommit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            isFocused: $isFocused,
            onCommit: onCommit
        )
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = ClearBackgroundTextField()
        textField.delegate = context.coordinator
        textField.isBezeled = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        textField.alignment = .center
        textField.font = font
        textField.textColor = textColor
        textField.placeholderString = ""
        textField.lineBreakMode = .byClipping
        textField.maximumNumberOfLines = 1
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.stringValue = text
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        if textField.stringValue != text {
            textField.stringValue = text
        }

        textField.font = font
        textField.textColor = textColor

        DispatchQueue.main.async {
            guard textField.window != nil else { return }

            if isFocused {
                if textField.window?.firstResponder !== textField.currentEditor() {
                    textField.window?.makeFirstResponder(textField)
                }
            } else if textField.window?.firstResponder === textField.currentEditor() {
                textField.window?.makeFirstResponder(nil)
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding private var text: String
        @Binding private var isFocused: Bool
        private let onCommit: () -> Void

        init(
            text: Binding<String>,
            isFocused: Binding<Bool>,
            onCommit: @escaping () -> Void
        ) {
            self._text = text
            self._isFocused = isFocused
            self.onCommit = onCommit
        }

        func controlTextDidBeginEditing(_ obj: Notification) {
            isFocused = true
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            text = String(textField.stringValue.filter(\.isNumber).prefix(3))
            if textField.stringValue != text {
                textField.stringValue = text
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            isFocused = false
            onCommit()
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                control.window?.makeFirstResponder(nil)
                return true
            }
            return false
        }
    }
}

private final class ClearBackgroundTextField: NSTextField {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        currentEditor()?.drawsBackground = false
        currentEditor()?.backgroundColor = .clear
    }

    override func becomeFirstResponder() -> Bool {
        let becameFirstResponder = super.becomeFirstResponder()
        currentEditor()?.drawsBackground = false
        currentEditor()?.backgroundColor = .clear
        return becameFirstResponder
    }
}

@MainActor
struct ManagedScrollView<Content: View>: NSViewRepresentable {
    @Binding var scrollOffset: CGFloat
    @ViewBuilder let content: Content

    func makeCoordinator() -> Coordinator {
        Coordinator(scrollOffset: $scrollOffset)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.contentView.postsBoundsChangedNotifications = true

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width]
        hostingView.frame = NSRect(x: 0, y: 0, width: scrollView.contentSize.width, height: 1)

        scrollView.documentView = hostingView
        context.coordinator.attach(to: scrollView, hostingView: hostingView)
        context.coordinator.updateLayout()
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.hostingView?.rootView = content
        context.coordinator.updateLayout()
        context.coordinator.restoreScrollPositionIfNeeded()
    }

    @MainActor
    final class Coordinator: NSObject {
        @Binding private var scrollOffset: CGFloat
        weak var scrollView: NSScrollView?
        weak var hostingView: NSHostingView<Content>?
        private var isRestoringScrollPosition = false

        init(scrollOffset: Binding<CGFloat>) {
            self._scrollOffset = scrollOffset
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func attach(to scrollView: NSScrollView, hostingView: NSHostingView<Content>) {
            self.scrollView = scrollView
            self.hostingView = hostingView

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(boundsDidChange(_:)),
                name: NSView.boundsDidChangeNotification,
                object: scrollView.contentView
            )
        }

        @objc private func boundsDidChange(_ notification: Notification) {
            guard !isRestoringScrollPosition, let scrollView else { return }
            scrollOffset = scrollView.contentView.bounds.origin.y
            NSApp.keyWindow?.makeFirstResponder(nil)
        }

        func updateLayout() {
            guard let scrollView, let hostingView else { return }

            let targetWidth = max(scrollView.contentSize.width, 1)
            if abs(hostingView.frame.width - targetWidth) > 0.5 {
                hostingView.frame.size.width = targetWidth
            }

            hostingView.layoutSubtreeIfNeeded()
            let fittingHeight = max(hostingView.fittingSize.height, 1)
            if abs(hostingView.frame.height - fittingHeight) > 0.5 {
                hostingView.frame.size.height = fittingHeight
            }
        }

        func restoreScrollPositionIfNeeded() {
            guard let scrollView else { return }

            DispatchQueue.main.async { [weak self, weak scrollView] in
                guard let self, let scrollView else { return }
                let maxOffset = max(
                    0,
                    (scrollView.documentView?.frame.height ?? 0) - scrollView.contentView.bounds.height
                )
                let clampedOffset = min(max(self.scrollOffset, 0), maxOffset)
                let currentOffset = scrollView.contentView.bounds.origin.y

                guard abs(currentOffset - clampedOffset) > 0.5 else { return }

                self.isRestoringScrollPosition = true
                scrollView.contentView.scroll(to: NSPoint(x: 0, y: clampedOffset))
                scrollView.reflectScrolledClipView(scrollView.contentView)
                self.isRestoringScrollPosition = false
            }
        }
    }
}

struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleNSView {
        DragHandleNSView()
    }

    func updateNSView(_ nsView: DragHandleNSView, context: Context) {}
}

final class DragHandleNSView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        self
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
#endif
