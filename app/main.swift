// main.swift — G815 Lights.app: the window, and the quiet keeper behind it.
//
// Started at login by ~/Library/LaunchAgents/community.auroville.g815lights.plist with --background: no window,
// no Dock icon; it paints the active bank and stays to paint again after sleep, after a replug, and when an
// M key is pressed on the keyboard. Opened again (the star's row, Finder, `open`), the same process shows its
// window; closing the window leaves the keeper running. Quit (⌘Q) ends both.

import AppKit
import IOKit.hid
import SwiftUI

final class Delegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var store: Store!
    var window: NSWindow?
    var poll: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        // ONE COPY ONLY: two would fight over the keyboard (MEASURED 2.10.2026: the login agent's copy and one
        // started by macOS's "Quit & Reopen" ran side by side). A second copy asks the first to show its window
        // and goes; the first listens for that.
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: "community.auroville.g815lights")
            .filter { $0.processIdentifier != me }
        if !others.isEmpty {
            if !CommandLine.arguments.contains("--background") {
                DistributedNotificationCenter.default().postNotificationName(.init("community.auroville.g815lights.show"), object: nil, userInfo: nil, deliverImmediately: true)
            }
            exit(0)
        }
        DistributedNotificationCenter.default().addObserver(forName: .init("community.auroville.g815lights.show"), object: nil, queue: .main) { [weak self] _ in
            self?.show()
        }
        // the G815's light interface sits beside its keys, so macOS asks for Input Monitoring; this shows
        // the system's own question once (System Settings > Privacy & Security > Input Monitoring)
        if IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) != kIOHIDAccessTypeGranted {
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        }
        MainActor.assumeIsolated {
            store = Store()
            store.paintAll()
            store.choose(store.s.active)
            // every bank in the keyboard brought in line with the Mac's; a bank already so is not written
            for i in 1...3 { store.writeBank(i) }
            poll = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.store.poll() }
            }
        }
        let ws = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { MainActor.assumeIsolated { self?.store.paintAll() } }
            }
        }
        if CommandLine.arguments.contains("--background") {
            NSApp.setActivationPolicy(.accessory)
        } else {
            show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool { show(); return true }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func show() {
        NSApp.setActivationPolicy(.regular)
        if window == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1260, height: 820),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            w.title = "G815 Lights"
            w.titlebarAppearsTransparent = true
            w.backgroundColor = NSColor(red: 0x0B / 255, green: 0x0D / 255, blue: 0x10 / 255, alpha: 1)
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.contentView = NSHostingView(rootView: MainView(store: store))
            w.setFrameAutosaveName("G815LightsMain")
            if !w.setFrameUsingName("G815LightsMain") { w.center() }
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // the window goes, the keeper stays
    func windowWillClose(_ notification: Notification) { NSApp.setActivationPolicy(.accessory) }
}

// a minimal menu so ⌘Q, ⌘W and copy/paste in the fields work
func makeMenu() -> NSMenu {
    let main = NSMenu()
    let app = NSMenuItem(); main.addItem(app)
    let am = NSMenu()
    am.addItem(withTitle: "Quit G815 Lights", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    app.submenu = am
    let edit = NSMenuItem(); main.addItem(edit)
    let em = NSMenu(title: "Edit")
    em.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    em.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    em.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    em.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    em.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    edit.submenu = em
    return main
}

let app = NSApplication.shared
let delegate = Delegate()
app.delegate = delegate
app.mainMenu = makeMenu()
app.run()
