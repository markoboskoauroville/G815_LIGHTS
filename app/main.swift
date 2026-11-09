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
    var updater: Updater!
    var window: NSWindow?
    var poll: Timer?
    var usb: IOHIDManager?

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
        // v30 NIGHT, the API: ["on": "1"] dark but ⌃⌥⌘F1, ["on": "0"] the bank back (Store.setNight)
        DistributedNotificationCenter.default().addObserver(forName: .init("community.auroville.g815lights.night"), object: nil, queue: .main) { [weak self] n in
            let on = (n.userInfo?["on"] as? String) == "1"
            MainActor.assumeIsolated { self?.store?.setNight(on) }
            // v32: the answer, so the caller knows the API is alive (Screen Brightness Darkening v10 waits for it)
            DistributedNotificationCenter.default().postNotificationName(.init("community.auroville.g815lights.night.ack"), object: nil,
                userInfo: ["on": on ? "1" : "0"], deliverImmediately: true)
        }
        // the G815's light interface sits beside its keys, so macOS asks for Input Monitoring; this shows
        // the system's own question once (System Settings > Privacy & Security > Input Monitoring)
        // v22: never at login (--background, --login): the window's PERMISSIONS waits for him (swift-apps.md)
        let atLogin = CommandLine.arguments.contains("--background") || CommandLine.arguments.contains("--login")
        if !atLogin && IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) != kIOHIDAccessTypeGranted {
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        }
        MainActor.assumeIsolated {
            store = Store()
            store.start()
            store.followResolve()            // v26: the G-key of Resolve's current page lit, alone
            // every bank in the keyboard brought in line with the Mac's; a bank already so is not written
            for i in 1...3 { store.writeBank(i) }
            poll = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.store.poll() }
            }
            // the new version from GitHub, built here (Update.swift)
            updater = Updater(wireIdle: { [weak self] in self?.store.wire.idle ?? true },
                              windowOpen: { [weak self] in self?.window?.isVisible ?? false })
            updater.start()
        }
        // the keyboard arriving on USB (a replug, or macOS resetting it during boot and login): paint again
        let m = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        IOHIDManagerSetDeviceMatching(m, [kIOHIDVendorIDKey: VID, kIOHIDProductIDKey: PID] as CFDictionary)
        IOHIDManagerRegisterDeviceMatchingCallback(m, { ctx, _, _, _ in
            let me = Unmanaged<Delegate>.fromOpaque(ctx!).takeUnretainedValue()
            Store.log("USB: the keyboard arrived")
            MainActor.assumeIsolated { me.store.repaintSoon("USB arrival") }
        }, Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterDeviceRemovalCallback(m, { _, _, _, _ in Store.log("USB: the keyboard left") }, nil)
        IOHIDManagerScheduleWithRunLoop(m, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(m, 0)
        usb = m
        let ws = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            ws.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { MainActor.assumeIsolated { self?.store.paintAll(name.rawValue) } }
            }
        }
        // a restart by the updater from an open window comes back with the window
        let reopened = Updater.takeShowFlag()
        if CommandLine.arguments.contains("--background") && !reopened {
            NSApp.setActivationPolicy(.accessory)
        } else {
            show()
        }
    }

    // v18: the keyboard back in its own mode when the app goes (⌘Q, the updater's restart, launchctl's SIGTERM)
    func applicationWillTerminate(_ n: Notification) { store?.release() }

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
            w.contentView = MainActor.assumeIsolated { NSHostingView(rootView: MainView(store: store, updater: updater, macros: store.macros)) }
            w.setFrameAutosaveName("G815LightsMain")
            if !w.setFrameUsingName("G815LightsMain") { w.center() }
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        MainActor.assumeIsolated { updater?.check() }
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
// launchctl stops the login agent with SIGTERM, which ends a process without applicationWillTerminate
signal(SIGTERM, SIG_IGN)
let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigterm.setEventHandler { delegate.store?.release(); exit(0) }
sigterm.resume()
app.delegate = delegate
app.mainMenu = makeMenu()
app.run()
