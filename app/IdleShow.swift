// IdleShow.swift — v38 (15.11.2026): the light show on his own switch.
//
// Marko, 15.11.2026: "after few minutes of I am not active, my keyboard start to make a light show. Whatever is doing,
// remove it, but you can add the same process inside my real application ... and then inside give me a switch for light
// show after 5 minutes of an activity or start now."
//
// The culprit (found 15.11.2026): v36's stored "resume" in LightShow.swift replayed a pattern that some caller had once
// posted (Meditation Room's "both" mode posts a 20 s pattern every 5 minutes), without its 20 s limit, after every
// 300 s of quiet. That replay is removed. This file is the only thing in the app that starts a show by itself, and only
// while the switch is ON (default OFF).
//
// Idle = seconds since the last keyboard, mouse or trackpad event of the session (CGEventSource, no permission needed).
// An idle show stops at the first key or mouse event and the bank's own colours come back (LightShow.stop → paintAll).
// A show started with START NOW stops at the next key, or with STOP (the mouse is needed to press them).
// Debug: ~/.mantra/g815-idle-seconds (a number) replaces the minutes, for a test only, never written by the app.

import AppKit

final class IdleShow: ObservableObject, @unchecked Sendable {
    static let shared = IdleShow()
    private let d = UserDefaults.standard

    @Published var on: Bool { didSet { d.set(on, forKey: "idleShowOn") } }
    @Published var minutes: Int { didSet { d.set(minutes, forKey: "idleShowMinutes") } }
    @Published var show: String { didSet { d.set(show, forKey: "idleShowName") } }
    @Published var running = false
    @Published var idleNow = 0
    private var manual = false
    private var timer: Timer?

    static let choices = ["all"] + Shows.names

    init() {
        on = d.bool(forKey: "idleShowOn")                       // default OFF
        let m = d.integer(forKey: "idleShowMinutes"); minutes = m > 0 ? m : 5
        let s = d.string(forKey: "idleShowName") ?? "all"; show = IdleShow.choices.contains(s) ? s : "all"
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
        Store.log("idle show: \(on ? "ON" : "OFF"), after \(Int(threshold)) s, show \(show)")
    }

    var threshold: Double {
        if let t = try? String(contentsOfFile: NSString(string: "~/.mantra/g815-idle-seconds").expandingTildeInPath, encoding: .utf8),
           let v = Double(t.trimmingCharacters(in: .whitespacesAndNewlines)), v > 0 { return v }
        return Double(minutes) * 60
    }

    static var idleSeconds: Double {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    private func tick() {
        let idle = Self.idleSeconds
        idleNow = Int(idle)
        let ls = LightShow.shared
        if running {
            if !ls.active { running = false; manual = false; return }                 // a key, /stop or STOP ended it
            if !manual && idle < 1.5 { ls.stop(); running = false; Store.log("idle show: stopped, he is back") }
            return
        }
        guard on, idle >= threshold, !ls.active, CGDisplayIsAsleep(CGMainDisplayID()) == 0 else { return }
        launch(manual: false)
    }

    private func launch(manual m: Bool) {
        let r = LightShow.shared.showCmd(name: show, seconds: 25, counter: false, ttl: nil, force: true)
        if r["ok"] as? Bool == true {
            running = true; manual = m
            Store.log("idle show: \(m ? "START NOW" : "after \(Int(IdleShow.idleSeconds)) s of inactivity"), show \(show)")
        }
    }

    func startNow() { DispatchQueue.main.async { self.launch(manual: true) } }
    func stopNow() { LightShow.shared.stop(); DispatchQueue.main.async { self.running = false; self.manual = false } }

    func toggle() { on.toggle(); Store.log("idle show: switch \(on ? "ON" : "OFF")") }
    func adjust(_ by: Int) { minutes = min(120, max(1, minutes + by)) }
    func next(_ by: Int) {
        let i = IdleShow.choices.firstIndex(of: show) ?? 0
        show = IdleShow.choices[(i + by + IdleShow.choices.count) % IdleShow.choices.count]
    }

    /// POST /idle
    func apply(_ o: [String: Any]) {
        DispatchQueue.main.async {
            if let v = o["on"] as? Bool { self.on = v }
            if let v = o["minutes"] as? Int { self.minutes = min(120, max(1, v)) }
            if let v = o["show"] as? String, IdleShow.choices.contains(v) { self.show = v }
            Store.log("idle show: set over the API: on \(self.on), \(self.minutes) min, \(self.show)")
        }
    }

    func statusDict() -> [String: Any] {
        ["on": on, "minutes": minutes, "show": show, "running": running, "threshold_seconds": Int(threshold),
         "idle_seconds": Int(Self.idleSeconds), "debug_override": FileManager.default.fileExists(atPath: NSString(string: "~/.mantra/g815-idle-seconds").expandingTildeInPath)]
    }
}
