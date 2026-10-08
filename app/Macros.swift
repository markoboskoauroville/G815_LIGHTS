// Macros.swift — macros for the G815 (Marko, 8.10.2026: "when user presses MR button ... it will be able to create
// macros and the macros will be stored on local computer and updated every time the computer starts. The same
// principles of memory handling as light color ... macro can be run with any key on the keyboard of course G1 to G5,
// but anyone can be assigned as macro trigger. Let's build macro editor and macro recorder").
//
// Kept like the colours: every macro in ~/.g815/settings.json, and each bank M1 M2 M3 says which key plays which.
// Nothing goes into the keyboard's memory; the app is the one that plays them, from login on.
//
// Two ways in. G1–G5 and MR speak HID++ (features 0x8010 G-keys, 0x8030 MR; they arrive through Wire as the
// keyboard's own news). v18: G1–G5 are under the app's control in every bank (Store.syncGKeys), so they never type
// F1–F5 and MR is always heard; a G key with no macro does nothing. Every other key is caught by macOS's event tap, which needs Accessibility
// (System Settings › Privacy & Security › Accessibility); playing a macro needs the same permission. The trigger key
// itself is swallowed, so it types nothing. Modifiers (CTRL SHIFT ALT ⌘), the media keys and ☼ cannot be triggers.
//
// MR on the keyboard (the Logitech way): MR (its light on) → the key to play it → type → MR. The new macro is
// named after the key and put on it in the bank now chosen. MR while waiting for the key cancels.

import AppKit
import ApplicationServices

/// one step: a key pressed or let go (the Mac's virtual key code), a wait, or a text typed as it is
struct MacroStep: Codable, Equatable, Identifiable {
    var uid = UUID().uuidString
    var kind = "key"           // "key", "wait", "text"
    var code = 0
    var down = true
    var ms = 0
    var text = ""
    var id: String { uid }

    static func key(_ code: Int, _ down: Bool) -> MacroStep { var s = MacroStep(); s.code = code; s.down = down; return s }
    static func wait(_ ms: Int) -> MacroStep { var s = MacroStep(); s.kind = "wait"; s.ms = ms; return s }
    static func typed(_ t: String) -> MacroStep { var s = MacroStep(); s.kind = "text"; s.text = t; return s }

    init() {}
    init(from d: Decoder) throws {
        let k = try d.container(keyedBy: CodingKeys.self)
        uid = try k.decodeIfPresent(String.self, forKey: .uid) ?? UUID().uuidString
        kind = try k.decodeIfPresent(String.self, forKey: .kind) ?? "key"
        code = try k.decodeIfPresent(Int.self, forKey: .code) ?? 0
        down = try k.decodeIfPresent(Bool.self, forKey: .down) ?? true
        ms = try k.decodeIfPresent(Int.self, forKey: .ms) ?? 0
        text = try k.decodeIfPresent(String.self, forKey: .text) ?? ""
    }
}

struct Macro: Codable, Equatable, Identifiable {
    var uid = UUID().uuidString
    var name: String
    var steps: [MacroStep] = []
    var id: String { uid }

    init(name: String, steps: [MacroStep] = []) { self.name = name; self.steps = steps }
    init(from d: Decoder) throws {
        let k = try d.container(keyedBy: CodingKeys.self)
        uid = try k.decodeIfPresent(String.self, forKey: .uid) ?? UUID().uuidString
        name = try k.decodeIfPresent(String.self, forKey: .name) ?? "MACRO"
        steps = try k.decodeIfPresent([MacroStep].self, forKey: .steps) ?? []
    }
}

/// the keyboard's keys in the Mac's words: light index → HID usage → virtual key code, and names to show
enum KeyCodes {
    /// marks the events a macro posts, so the tap lets them through and never records or triggers on them
    static let magic: Int64 = 0x6815
    static let gKeys = ["b4", "b5", "b6", "b7", "b8"]

    /// HID usage (keyboard page) → the Mac's virtual key code
    static let byUsage: [Int: Int] = [
        0x04: 0x00, 0x05: 0x0B, 0x06: 0x08, 0x07: 0x02, 0x08: 0x0E, 0x09: 0x03, 0x0A: 0x05, 0x0B: 0x04, 0x0C: 0x22,
        0x0D: 0x26, 0x0E: 0x28, 0x0F: 0x25, 0x10: 0x2E, 0x11: 0x2D, 0x12: 0x1F, 0x13: 0x23, 0x14: 0x0C, 0x15: 0x0F,
        0x16: 0x01, 0x17: 0x11, 0x18: 0x20, 0x19: 0x09, 0x1A: 0x0D, 0x1B: 0x07, 0x1C: 0x10, 0x1D: 0x06,
        0x1E: 0x12, 0x1F: 0x13, 0x20: 0x14, 0x21: 0x15, 0x22: 0x17, 0x23: 0x16, 0x24: 0x1A, 0x25: 0x1C, 0x26: 0x19, 0x27: 0x1D,
        0x28: 0x24, 0x29: 0x35, 0x2A: 0x33, 0x2B: 0x30, 0x2C: 0x31, 0x2D: 0x1B, 0x2E: 0x18, 0x2F: 0x21, 0x30: 0x1E,
        0x31: 0x2A, 0x32: 0x2A, 0x33: 0x29, 0x34: 0x27, 0x35: 0x32, 0x36: 0x2B, 0x37: 0x2F, 0x38: 0x2C, 0x39: 0x39,
        0x3A: 0x7A, 0x3B: 0x78, 0x3C: 0x63, 0x3D: 0x76, 0x3E: 0x60, 0x3F: 0x61, 0x40: 0x62, 0x41: 0x64, 0x42: 0x65,
        0x43: 0x6D, 0x44: 0x67, 0x45: 0x6F, 0x46: 0x69, 0x47: 0x6B, 0x48: 0x71,
        0x49: 0x72, 0x4A: 0x73, 0x4B: 0x74, 0x4C: 0x75, 0x4D: 0x77, 0x4E: 0x79, 0x4F: 0x7C, 0x50: 0x7B, 0x51: 0x7D, 0x52: 0x7E,
        0x53: 0x47, 0x54: 0x4B, 0x55: 0x43, 0x56: 0x4E, 0x57: 0x45, 0x58: 0x4C, 0x59: 0x53, 0x5A: 0x54, 0x5B: 0x55,
        0x5C: 0x56, 0x5D: 0x57, 0x5E: 0x58, 0x5F: 0x59, 0x60: 0x5B, 0x61: 0x5C, 0x62: 0x52, 0x63: 0x41, 0x65: 0x6E,
        0xE0: 0x3B, 0xE1: 0x38, 0xE2: 0x3A, 0xE3: 0x37, 0xE4: 0x3E, 0xE5: 0x3C, 0xE6: 0x3D, 0xE7: 0x36,
    ]

    /// the modifiers: their flag, held while a macro plays them; they are never triggers
    static let modifier: [Int: CGEventFlags] = [
        0x38: .maskShift, 0x3C: .maskShift, 0x3B: .maskControl, 0x3E: .maskControl,
        0x3A: .maskAlternate, 0x3D: .maskAlternate, 0x37: .maskCommand, 0x36: .maskCommand,
    ]

    /// light index → HID usage: letters, digits and most keys usage - 3, modifiers usage - 0x78 (lights.swift)
    static func usage(_ light: Int) -> Int? {
        if (0x68...0x6F).contains(light) { return light + 0x78 }
        if (0x01...0x62).contains(light) { return light + 3 }
        return nil
    }

    static func code(forKey id: String) -> Int? {
        guard let l = Int(id, radix: 16), let u = usage(l) else { return nil }
        return byUsage[u]
    }

    /// names where the legend is not enough (keypad, two ←, the modifiers' sides, space)
    static let names: [String: String] = [
        "25": "RETURN", "27": "BACKSPACE", "29": "SPACE", "4c": "RIGHT", "4d": "LEFT", "4e": "DOWN", "4f": "UP",
        "68": "L CTRL", "69": "L SHIFT", "6a": "L ALT", "6b": "L ⌘", "6c": "R CTRL", "6d": "R SHIFT", "6e": "ALT GR", "6f": "R ⌘",
        "50": "NUM LOCK", "55": "NUM ENTER",
    ]

    static func name(_ k: KeyCap) -> String {
        if let n = names[k.id] { return n }
        if let l = Int(k.id, radix: 16), (0x51...0x60).contains(l) { return "NUM " + k.l }
        return k.l
    }
}

@MainActor
final class Macros: ObservableObject {
    enum Rec: Equatable {
        case idle
        case waitTrigger                 // MR pressed: the next key is the one that will play it
        case recording(String?)          // the trigger key; nil = recording in the editor, into `into`
    }
    @Published var rec = Rec.idle
    /// the macro the editor records into
    @Published var into: String?
    /// Accessibility: needed to catch keys other than G1–G5, and to play any macro
    @Published var trusted = AXIsProcessTrusted()
    /// the last thing that happened, said in the window
    @Published var last = ""
    @Published var keepDelays = true

    unowned let store: Store
    /// the Mac's key code → the keyboard's key id; the ISO key left of 1 comes as 0x0A or 0x32
    let codeToId: [Int: String]
    let nameOf: [String: String]
    private var tap: CFMachPort?
    private var steps: [MacroStep] = []
    private var lastAt: TimeInterval = 0
    private var swallowed = Set<Int>()
    private var gDown = 0
    private var mrDown = false
    private let player = DispatchQueue(label: "g815.macro")
    private var timer: Timer?

    init(store: Store) {
        self.store = store
        var c: [Int: String] = [:], n: [String: String] = [:]
        for k in store.layout.keys {
            n[k.id] = KeyCodes.name(k)
            if let code = KeyCodes.code(forKey: k.id) { c[code] = k.id }
        }
        if c[0x32] != nil { c[0x0A] = c[0x32] }
        codeToId = c; nameOf = n
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.watchPermission() }
        }
        watchPermission()
    }

    func name(_ id: String) -> String { nameOf[id] ?? id }
    func codeName(_ code: Int) -> String { codeToId[code].map(name) ?? String(format: "KEY 0x%02X", code) }

    /// the macro this key plays in the bank now chosen
    func macro(for id: String) -> Macro? {
        guard let uid = store.bank.macros[id] else { return nil }
        return store.s.macros.first { $0.uid == uid }
    }

    // ------------------------------------------------------------ the permission and the tap
    private func watchPermission() {
        let t = AXIsProcessTrusted()
        if t != trusted { trusted = t; Store.log("macros: Accessibility " + (t ? "allowed" : "off")) }
        if t && tap == nil { makeTap() }
    }

    /// the system's own question, and its settings page (asked only when he opens the macros, not at every start)
    func askPermission() {
        guard !AXIsProcessTrusted() else { return }
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        if let u = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") { NSWorkspace.shared.open(u) }
    }

    private func makeTap() {
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                        eventsOfInterest: CGEventMask(mask), callback: { _, type, ev, ctx in
            let me = Unmanaged<Macros>.fromOpaque(ctx!).takeUnretainedValue()
            let swallow = MainActor.assumeIsolated { me.tapped(type, ev) }
            return swallow ? nil : Unmanaged.passUnretained(ev)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            Store.log("macros: the key tap could not be made"); return
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, t, 0), .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
        tap = t
        Store.log("macros: key tap on")
    }

    /// every key on the Mac passes here; true = swallowed (a trigger types nothing)
    private func tapped(_ type: CGEventType, _ ev: CGEvent) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return false
        }
        if ev.getIntegerValueField(.eventSourceUserData) == KeyCodes.magic { return false }
        let code = Int(ev.getIntegerValueField(.keyboardEventKeycode))
        switch type {
        case .keyDown:
            let again = ev.getIntegerValueField(.keyboardEventAutorepeat) != 0
            if rec == .waitTrigger {
                guard let id = codeToId[code] else { return false }
                swallowed.insert(code); trigger(id); return true
            }
            if case .recording = rec { if !again { record(code, true) }; return false }
            if swallowed.contains(code) { return true }
            if let id = codeToId[code], let m = macro(for: id) { swallowed.insert(code); run(m); return true }
            return false
        case .keyUp:
            if swallowed.remove(code) != nil { return true }
            if case .recording = rec { record(code, false) }
            return false
        case .flagsChanged:
            if case .recording = rec, let f = KeyCodes.modifier[code] { record(code, ev.flags.contains(f)) }
            return false
        default:
            return false
        }
    }

    // ------------------------------------------------------------ the keyboard's own keys (HID++)
    /// G1–G5 as a bitmask, bit 0 = G1; a press is a bit that was not there before
    func gKeys(_ mask: Int) {
        let pressed = mask & ~gDown
        gDown = mask
        for i in 0..<5 where pressed & (1 << i) != 0 { press(KeyCodes.gKeys[i]) }
    }

    func mr(_ down: Bool) {
        defer { mrDown = down }
        guard down, !mrDown else { return }
        switch rec {
        case .idle:
            steps = []; rec = .waitTrigger; mrLight(true); store.syncGKeys()
            say("MR: press the key that will play the macro (MR again cancels)")
        case .waitTrigger:
            rec = .idle; mrLight(false); store.syncGKeys(); say("MR: cancelled")
        case .recording(let t):
            finish(t)
        }
    }

    private func press(_ id: String) {
        switch rec {
        case .waitTrigger: trigger(id)
        case .recording: break                      // G keys are not recorded
        case .idle:
            if let m = macro(for: id) { run(m) } else { say("\(name(id)) has no macro in M\(store.s.active)") }
        }
    }

    // ------------------------------------------------------------ recording
    private func trigger(_ id: String) {
        steps = []; lastAt = 0
        rec = .recording(id)
        say("recording for \(name(id)) in M\(store.s.active): type the macro, then MR")
    }

    /// the editor's RECORD: into the macro chosen there, until STOP (or MR)
    func recordInto(_ uid: String) {
        guard rec == .idle else { return }
        // T3: the step's text field kept the focus, so what was recorded was typed into it as well
        NSApp.keyWindow?.makeFirstResponder(nil)
        into = uid; steps = []; lastAt = 0
        rec = .recording(nil); mrLight(true)
        say("recording: type the macro, then STOP")
    }

    func stop() {
        switch rec {
        case .recording(let t): finish(t)
        case .waitTrigger: rec = .idle; mrLight(false); store.syncGKeys()
        case .idle: break
        }
    }

    private func record(_ code: Int, _ down: Bool) {
        guard steps.count < 4000 else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if keepDelays && lastAt > 0 {
            let ms = Int(((now - lastAt) * 1000).rounded())
            if ms > 0 { steps.append(.wait(ms)) }
        }
        lastAt = now
        steps.append(.key(code, down))
    }

    private func finish(_ trigger: String?) {
        rec = .idle; mrLight(false); store.syncGKeys()
        let got = steps; steps = []
        if let t = trigger {
            guard !got.isEmpty else { say("nothing typed: no macro kept for \(name(t))"); return }
            let m = Macro(name: "\(name(t)) MACRO", steps: got)
            store.s.macros.append(m)
            store.s.memories[store.s.active - 1].macros[t] = m.uid
            store.save(); store.syncGKeys()
            say("\(m.name): \(got.filter { $0.kind == "key" && $0.down }.count) keys, on \(name(t)) in M\(store.s.active)")
            Store.log("macros: recorded \(m.name), \(got.count) steps, on \(t) in M\(store.s.active)")
        } else if let uid = into {
            update(uid) { $0.steps = got }
            say("recorded \(got.filter { $0.kind == "key" && $0.down }.count) keys")
            into = nil
        }
    }

    // ------------------------------------------------------------ playing
    func run(_ m: Macro) {
        guard AXIsProcessTrusted() else { say("ACCESSIBILITY IS OFF: \(m.name) cannot play"); return }
        say("played \(m.name)")
        let steps = m.steps
        player.async { Macros.post(steps) }
    }

    /// on the player's own thread: the steps as real key events, the modifiers held as flags while they are down
    nonisolated private static func post(_ steps: [MacroStep]) {
        let src = CGEventSource(stateID: .privateState)
        var flags: CGEventFlags = []
        var held = Set<Int>()
        func send(_ e: CGEvent) {
            e.setIntegerValueField(.eventSourceUserData, value: KeyCodes.magic)
            e.post(tap: .cghidEventTap)
        }
        for s in steps {
            switch s.kind {
            case "wait":
                usleep(useconds_t(max(0, min(s.ms, 60_000))) * 1000)
            case "text":
                let u = Array(s.text.utf16)
                var i = 0
                while i < u.count {
                    let chunk = Array(u[i..<min(i + 16, u.count)])
                    for down in [true, false] {
                        guard let e = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: down) else { continue }
                        e.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
                        send(e)
                    }
                    i += 16
                    usleep(3000)
                }
            default:
                if let f = KeyCodes.modifier[s.code] {
                    if s.down { flags.insert(f); held.insert(s.code) } else { flags.remove(f); held.remove(s.code) }
                }
                guard let e = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(s.code), keyDown: s.down) else { continue }
                e.flags = flags
                send(e)
            }
        }
        // a modifier the macro left down is let go, so the Mac is never left with SHIFT held
        for c in held {
            if let e = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(c), keyDown: false) { e.flags = []; send(e) }
        }
    }

    // ------------------------------------------------------------ editing
    func update(_ uid: String, _ change: (inout Macro) -> Void) {
        guard let i = store.s.macros.firstIndex(where: { $0.uid == uid }) else { return }
        change(&store.s.macros[i])
        store.save()
    }

    @discardableResult
    func add() -> String {
        let m = Macro(name: "MACRO \(store.s.macros.count + 1)")
        store.s.macros.append(m); store.save()
        return m.uid
    }

    func delete(_ uid: String) {
        store.s.macros.removeAll { $0.uid == uid }
        for i in store.s.memories.indices { store.s.memories[i].macros = store.s.memories[i].macros.filter { $0.value != uid } }
        store.save(); store.syncGKeys()
    }

    /// put a macro on a key in the bank now chosen, or take it away (nil)
    func assign(_ uid: String?, to id: String) {
        store.s.memories[store.s.active - 1].macros[id] = uid
        store.save(); store.syncGKeys()
        say(uid == nil ? "\(name(id)): no macro in M\(store.s.active)" : "\(name(id)) plays \(store.s.macros.first { $0.uid == uid }?.name ?? "") in M\(store.s.active)")
    }

    func canTrigger(_ id: String) -> Bool { KeyCodes.gKeys.contains(id) || (KeyCodes.code(forKey: id).map { KeyCodes.modifier[$0] == nil } ?? false) }

    // ------------------------------------------------------------ the rest
    private func say(_ t: String) { last = t; Store.log("macros: " + t) }

    /// MR's own light. MEASURED 8.10.2026 (T3 and after): this G815 has no way to set it. 0x8030 function 1 answers
    /// HID++ error 7 (no such function) in onboard and host mode, 0x8020 refuses a fourth bit (error 2), and none of
    /// the free per-key indexes (2e 61 63–67) lights it. So the window shows it: MR on the drawing turns red while
    /// waiting and recording (Views.swift); the keyboard's MR stays dark.
    private func mrLight(_ on: Bool) {}
}
