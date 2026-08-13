import AppKit
import CoreGraphics
import SwiftUI

private final class WidgetPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class BlockingHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

@MainActor
final class WidgetAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private let panelSize = NSSize(width: 340, height: 430)
    private let store = AppStateStore()
    private var panel: WidgetPanel?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private let windowOriginDefaultsKey = "ptn.widgetWindowOrigin"
    // 放在桌面图标层之上一层：
    // 既保持“桌面组件”观感，又能避免 Finder 桌面层吃掉滚动和拖动事件。
    private let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        showPanel()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return true
    }

    private func showPanel() {
        if let panel {
            panel.orderFrontRegardless()
            panel.makeKeyAndOrderFront(nil)
            updateStatusItem(isVisible: true)
            return
        }

        let panel = WidgetPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = false
        panel.level = desktopLevel
        panel.isOpaque = false
        panel.backgroundColor = NSColor.white.withAlphaComponent(0.01)
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.isMovable = false
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.animationBehavior = .utilityWindow
        panel.delegate = self

        let hostingView = BlockingHostingView(rootView: MainWidgetView(store: store))
        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 28
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.01).cgColor
        panel.contentView = hostingView
        panel.setContentSize(panelSize)

        position(panel: panel, size: panelSize)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
        updateStatusItem(isVisible: true)
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        updateStatusItem(isVisible: false)
    }

    private func togglePanelVisibility() {
        if let panel, panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = makeStatusBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "异方晶小组件菜单"
        }

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        menu.addItem(NSMenuItem(title: "显示小组件", action: #selector(togglePanelVisibilityFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "半透明小组件", action: #selector(toggleTranslucencyFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))

        self.statusItem = statusItem
        self.statusMenu = menu
        self.statusItem?.menu = menu
        updateStatusItem(isVisible: panel?.isVisible == true)
    }

    private func updateStatusItem(isVisible: Bool) {
        statusItem?.button?.contentTintColor = nil
        statusItem?.button?.alphaValue = isVisible ? 1.0 : 0.72
    }

    private func makeStatusBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor.black.setStroke()
        let circle = NSBezierPath(ovalIn: NSRect(x: 2.4, y: 2.4, width: 13.2, height: 13.2))
        circle.lineWidth = 1.5
        circle.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let font = NSFont.systemFont(ofSize: 10.5, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph
        ]
        let attributedText = NSAttributedString(string: "M", attributes: attributes)
        let textSize = attributedText.size()
        let textOrigin = NSPoint(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2
        )
        attributedText.draw(at: textOrigin)

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu === statusMenu else { return }

        menu.item(at: 0)?.title = panel?.isVisible == true ? "隐藏小组件" : "显示小组件"
        menu.item(at: 0)?.target = self
        menu.item(at: 1)?.target = self
        menu.item(at: 2)?.target = self
        menu.item(at: 1)?.state = store.usesExtraTranslucentBackground ? .on : .off
    }

    @objc
    private func togglePanelVisibilityFromMenu() {
        togglePanelVisibility()
    }

    @objc
    private func toggleTranslucencyFromMenu() {
        store.setUsesExtraTranslucentBackground(!store.usesExtraTranslucentBackground)
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }

    private func position(panel: NSPanel, size: NSSize) {
        if let savedOrigin = loadSavedOrigin() {
            panel.setFrame(
                NSRect(origin: clampedOrigin(savedOrigin, size: size), size: size),
                display: true
            )
            return
        }

        guard let screen = NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        let insetX: CGFloat = 24
        let insetY: CGFloat = 28
        let origin = NSPoint(
            x: visibleFrame.maxX - size.width - insetX,
            y: visibleFrame.maxY - size.height - insetY
        )

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    func windowDidMove(_ notification: Notification) {
        guard let panel else { return }
        saveOrigin(panel.frame.origin)
    }

    func windowWillClose(_ notification: Notification) {
        updateStatusItem(isVisible: false)
    }

    private func loadSavedOrigin() -> NSPoint? {
        guard
            let dict = UserDefaults.standard.dictionary(forKey: windowOriginDefaultsKey),
            let x = dict["x"] as? Double,
            let y = dict["y"] as? Double
        else {
            return nil
        }

        return NSPoint(x: x, y: y)
    }

    private func saveOrigin(_ origin: NSPoint) {
        UserDefaults.standard.set(
            ["x": origin.x, "y": origin.y],
            forKey: windowOriginDefaultsKey
        )
    }

    private func clampedOrigin(_ origin: NSPoint, size: NSSize) -> NSPoint {
        if let containingScreen = NSScreen.screens.first(where: { $0.visibleFrame.contains(origin) }) {
            return clamp(origin, to: containingScreen.visibleFrame, size: size)
        }

        if let mainScreen = NSScreen.main {
            return clamp(origin, to: mainScreen.visibleFrame, size: size)
        }

        return origin
    }

    private func clamp(_ origin: NSPoint, to visibleFrame: NSRect, size: NSSize) -> NSPoint {
        let minX = visibleFrame.minX
        let maxX = visibleFrame.maxX - size.width
        let minY = visibleFrame.minY
        let maxY = visibleFrame.maxY - size.height

        return NSPoint(
            x: min(max(origin.x, minX), maxX),
            y: min(max(origin.y, minY), maxY)
        )
    }
}

@main
struct PTNHypercubeWidgetApp: App {
    @NSApplicationDelegateAdaptor(WidgetAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
