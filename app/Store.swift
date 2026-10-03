// Store.swift — the banks, the presets, and what the keyboard is told.
//
// THREE BANKS, the keyboard's own M1 M2 M3 (Marko, 2.10.2026: "I press the memory button and adjust my
// keyboard settings ... and it stays under that memory as well as my computer as well inside the keyboard").
// Bank i on the Mac holds every key's colour and brightness (~/.g815/settings.json). Bank i in the keyboard
// holds what its memory can hold — one still colour for the keys, one for the logo — written four seconds
// after the last change, so the power-on is still and never a light show. Choosing a bank here switches
// the keyboard; pressing M1..M3 on the keyboard switches this.

import Foundation
import SwiftUI

struct KeyLight: Codable, Equatable {
    var c: String      // rrggbb, the colour chosen
    var b: Int         // 0...100, this key's own brightness
    /// what goes on the wire: the colour times the key's brightness
    var sent: (UInt8, UInt8, UInt8) {
        let v = UInt32(c, radix: 16) ?? 0, f = Double(max(0, min(100, b))) / 100
        func ch(_ x: UInt32) -> UInt8 { UInt8((Double(x & 0xFF) * f).rounded()) }
        return (ch(v >> 16), ch(v >> 8), ch(v))
    }
    var sentHex: String { let s = sent; return String(format: "%02x%02x%02x", s.0, s.1, s.2) }
}

struct Bank: Codable {
    var name: String
    var base = KeyLight(c: "ffffff", b: 100)
    var keys: [String: KeyLight] = [:]
}

/// A saved colour + brightness. Its name may be empty (only the swatch shows) or automatic, made from the colour
/// (Marko, 3.10.2026: "I can even remove the name completely ... a check mark automatic name").
struct Preset: Codable, Identifiable, Equatable {
    var uid = UUID().uuidString
    var name: String
    var c: String
    var b: Int
    var auto = false
    var id: String { uid }

    init(name: String, c: String, b: Int, auto: Bool = false) { self.name = name; self.c = c; self.b = b; self.auto = auto }
    init(from d: Decoder) throws {          // presets saved by v4 had no uid and no auto
        let k = try d.container(keyedBy: CodingKeys.self)
        uid = try k.decodeIfPresent(String.self, forKey: .uid) ?? UUID().uuidString
        name = try k.decodeIfPresent(String.self, forKey: .name) ?? ""
        c = try k.decode(String.self, forKey: .c)
        b = try k.decode(Int.self, forKey: .b)
        auto = try k.decodeIfPresent(Bool.self, forKey: .auto) ?? false
    }

    /// v6 kept the automatic name apart (name empty, auto on); since 3.10.2026 it is written into the name itself
    var shown: String { auto && name.isEmpty ? Preset.autoName(c: c, b: b) : name }

    /// "WHITE", "WARM WHITE 25%", "ORANGE", "OFF": the colour in words, the brightness when it is not 100
    static func autoName(c: String, b: Int) -> String {
        let v = UInt32(c, radix: 16) ?? 0
        let r = Double(v >> 16 & 0xFF) / 255, g = Double(v >> 8 & 0xFF) / 255, bl = Double(v & 0xFF) / 255
        let mx = max(r, g, bl), mn = min(r, g, bl), d = mx - mn
        if b == 0 || mx * Double(b) / 100 < 0.03 { return "OFF" }
        var h = 0.0
        if d > 0 { h = mx == r ? ((g - bl) / d).truncatingRemainder(dividingBy: 6) : mx == g ? (bl - r) / d + 2 : (r - g) / d + 4 }
        h = (h * 60 + 360).truncatingRemainder(dividingBy: 360)
        let sat = mx > 0 ? d / mx : 0
        var word: String
        if sat < 0.12 { word = mx < 0.6 ? "GREY" : "WHITE" }
        else if sat < 0.55 && h >= 15 && h < 60 { word = "WARM WHITE" }
        else if sat < 0.45 && h >= 180 && h < 260 { word = "COOL WHITE" }
        else {
            let names: [(Double, String)] = [(15, "RED"), (40, "ORANGE"), (65, "YELLOW"), (90, "LIME"), (150, "GREEN"),
                (175, "TEAL"), (200, "CYAN"), (225, "AZURE"), (255, "BLUE"), (285, "VIOLET"), (320, "MAGENTA"), (345, "PINK"), (361, "RED")]
            word = names.first { h < $0.0 }!.1
        }
        if mx < 0.45 && word != "GREY" { word = "DARK " + word }
        return b < 100 ? "\(word) \(b)%" : word
    }
}

struct Settings: Codable {
    var memories: [Bank] = (1...3).map { Bank(name: "M\($0)") }
    var active = 1
    var presets: [Preset] = [
        Preset(name: "WHITE", c: "ffffff", b: 100), Preset(name: "WARM", c: "ff8a2a", b: 100),
        Preset(name: "DIM", c: "ffffff", b: 25), Preset(name: "OFF", c: "000000", b: 0),
    ]
}

struct KeyCap: Codable, Identifiable {
    let l: String, id: String
    let x: Double, y: Double, w: Double, h: Double
}
struct BankCap: Codable { let l: String, i: Int, x: Double, y: Double }
struct KeyLayout: Codable { let keys: [KeyCap]; let banks: [BankCap]; let w: Double; let h: Double }

@MainActor
final class Store: ObservableObject {
    nonisolated static let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".g815")
    static let file = dir.appendingPathComponent("settings.json")
    nonisolated static let logFile = dir.appendingPathComponent("log.txt")

    /// ~/.g815/log.txt: what the keyboard and the app did, so a lost bank after a restart can be read back
    nonisolated static func log(_ t: String) {
        let f = DateFormatter(); f.dateFormat = "d.M.yyyy HH:mm:ss.SSS"
        let line = f.string(from: Date()) + "  " + t + "\n"
        guard let h = try? FileHandle(forWritingTo: logFile) else {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? line.write(to: logFile, atomically: true, encoding: .utf8); return
        }
        defer { try? h.close() }
        if let end = try? h.seekToEnd(), end > 400_000 {
            let keep = (try? Data(contentsOf: logFile))?.suffix(200_000) ?? Data()
            try? h.truncate(atOffset: 0); try? h.write(contentsOf: keep)
        }
        try? h.write(contentsOf: Data(line.utf8))
    }

    @Published var s = Settings()
    @Published var connected = false
    @Published var serial = ""
    @Published var brightness = 0          // the keyboard's own, the button's
    @Published var error = ""
    @Published var bankNote: [Int: String] = [:]

    let layout: KeyLayout
    let wire = Wire()
    private var dirty = Set<String>()
    private var paintQueued = false
    private var bankTimer: Timer?
    private var chosenAt = Date.distantPast

    init() {
        let url = Bundle.main.url(forResource: "layout", withExtension: "json")!
        layout = try! JSONDecoder().decode(KeyLayout.self, from: Data(contentsOf: url))
        if let d = try? Data(contentsOf: Store.file), let t = try? JSONDecoder().decode(Settings.self, from: d) { s = t }
        while s.memories.count < 3 { s.memories.append(Bank(name: "M\(s.memories.count + 1)")) }
        s.memories = Array(s.memories.prefix(3))
        for i in 0..<3 { s.memories[i].name = "M\(i + 1)" }
        if !(1...3).contains(s.active) { s.active = 1 }
        wire.onError = { [weak self] e in
            Store.log("error: \(e)")
            Task { @MainActor in self?.connected = false; self?.error = e }
        }
        // a keyboard (re)opened has lost nothing we know of, but its RAM may have been reset while we were away
        wire.onOpen = { [weak self] in
            Store.log("keyboard opened")
            DispatchQueue.main.async { self?.paintAll("opened") }
        }
        // The keyboard's own news (MEASURED 3.10.2026: after a real boot the bank's per-key colours were lost
        // while a replayed login painted them in 4 s, so something reloads the keyboard after the app's paint).
        // Whatever it says, paint again shortly; the bank switch from an M key is still found by poll().
        wire.onUnasked = { [weak self] m in
            Store.log("keyboard says: " + hex(m))
            DispatchQueue.main.async { self?.repaintSoon("keyboard spoke") }
        }
    }

    var bank: Bank { s.memories[s.active - 1] }
    func key(_ id: String) -> KeyLight { bank.keys[id] ?? bank.base }

    func save() {
        try? FileManager.default.createDirectory(at: Store.dir, withIntermediateDirectories: true)
        let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? e.encode(s).write(to: Store.file, options: .atomic)
    }

    // ------------------------------------------------------------ painting
    /// The keys are gathered and their colours read when the job runs, so a drag that changes them
    /// thirty times a second sends one or two reports, never a backlog.
    func paint(_ ids: [String]) {
        dirty.formUnion(ids)
        guard !paintQueued else { return }
        paintQueued = true
        wire.run { [weak self] kb in
            let keys: [(UInt8, UInt8, UInt8, UInt8)] = DispatchQueue.main.sync {
                guard let self else { return [] }
                let ids = self.dirty
                self.dirty = []
                self.paintQueued = false
                return ids.compactMap { id in
                    guard let i = UInt8(id, radix: 16) else { return nil }
                    let c = self.key(id).sent
                    return (i, c.0, c.1, c.2)
                }
            }
            try kb.setKeys(keys)
            DispatchQueue.main.async { self?.connected = true; self?.error = "" }
        }
    }

    func paintAll(_ why: String = "") {
        if !why.isEmpty { Store.log("paint all: " + why) }
        paint(layout.keys.map(\.id))
    }

    private var repaintTimer: Timer?
    func repaintSoon(_ why: String) {
        repaintTimer?.invalidate()
        repaintTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.paintAll(why) }
        }
    }

    /// At start: the keyboard put on the Mac's bank only if it is on another one — switching bank makes it
    /// reload the bank from its memory, which wipes the per-key colours (MEASURED 3.10.2026, M2 then M1:
    /// every key the bank's one orange). Then painted, and painted again a few times while the Mac settles.
    func start() {
        Store.log("start, bank M\(s.active)")
        let want = s.active
        wire.run { [weak self] kb in
            let ob = try kb.need(0x8100)
            let now = Int(try kb.call(ob, 4)[1])
            Store.log("keyboard on M\(now), mode \(try kb.onboardMode())")
            if now != want {
                try kb.call(ob, 3, [0, UInt8(want)])
                Thread.sleep(forTimeInterval: 0.5)
            }
            DispatchQueue.main.async { self?.chosenAt = Date() }
        }
        paintAll("start")
        for t in [3.0, 10, 30, 60, 120] {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in self?.paintAll("start + \(Int(t)) s") }
        }
    }

    /// Change the chosen keys: colour and/or brightness. Kept, painted, and the bank saved later.
    func set(_ ids: Set<String>, c: String? = nil, b: Int? = nil) {
        guard !ids.isEmpty else { return }
        for id in ids {
            var k = key(id)
            if let c { k.c = c }
            if let b { k.b = b }
            s.memories[s.active - 1].keys[id] = k
        }
        save()
        paint(Array(ids))
        bankLater()
    }

    // ------------------------------------------------------------ banks
    /// the colour most keys show: the keyboard's memory holds one per zone
    func dominant(_ b: Bank) -> (UInt8, UInt8, UInt8) {
        var count: [String: Int] = [:]
        for k in layout.keys where k.id != "d2" { count[(b.keys[k.id] ?? b.base).sentHex, default: 0] += 1 }
        let best = count.max { $0.value < $1.value }?.key ?? "ffffff"
        let v = UInt32(best, radix: 16)!
        return (UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF))
    }

    func writeBank(_ i: Int) {
        let b = s.memories[i - 1]
        let keys = dominant(b), logo = (b.keys["d2"] ?? b.base).sent
        bankNote[i] = "saving"
        wire.run { [weak self] kb in
            let said = try kb.setOnboardStatic(profile: i, keys: keys, logo: logo)
            DispatchQueue.main.async {
                guard let self else { return }
                self.bankNote[i] = said.contains("already") ? "saved" : "saved " + Date().formatted(date: .omitted, time: .shortened)
                // a written bank can be reloaded by the keyboard, which drops the per-key colours
                if i == self.s.active { self.paintAll("bank M\(i) written") }
            }
        }
    }

    private func bankLater() {
        bankTimer?.invalidate()
        let i = s.active
        bankTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.bankTimer = nil; self?.writeBank(i) }
        }
    }

    func choose(_ i: Int) {
        guard (1...3).contains(i) else { return }
        if let t = bankTimer { t.fire() }          // the bank being left is saved first
        s.active = i
        chosenAt = Date()
        save()
        wire.run { kb in
            try kb.call(try kb.need(0x8100), 3, [0, UInt8(i)])
            Thread.sleep(forTimeInterval: 0.3)       // the keyboard reloads the bank; paint after, not before
        }
        paintAll("bank M\(i) chosen")
    }

    // ------------------------------------------------------------ the keyboard's own state
    func setBrightness(_ v: Int) {
        brightness = v
        wire.run { kb in try kb.setBrightness(max(0, min(100, v))) }
    }

    /// Once a second: is it there, which bank, how bright. A keyboard that comes back is painted again;
    /// an M key pressed on the keyboard switches the bank here.
    private var ticks = 0
    func poll() {
        guard wire.queued == 0 else { return }
        // The keyboard can reload its bank from memory without a word (MEASURED 3.10.2026: a bank reload under
        // the running app sent no report and left the bank number as it was; F1 went from red to the bank's
        // orange). Nothing can read the per-key colours back, so every 15 s the keys are painted again — the same
        // colours, nothing seen; a loss lasts 15 s at most.
        ticks += 1
        if ticks % 15 == 0 { paintAll() }
        let asked = Date()
        wire.run { [weak self] kb in
            let ob = try kb.need(0x8100)
            let profile = Int(try kb.call(ob, 4)[1])
            let bright = try kb.brightness()
            let serial = kb.serial
            DispatchQueue.main.async {
                guard let self else { return }
                let was = self.connected
                self.connected = true; self.error = ""; self.serial = serial; self.brightness = bright
                if asked < self.chosenAt { return }
                if (1...3).contains(profile) && profile != self.s.active && self.bankTimer == nil {
                    self.s.active = profile
                    self.save()
                    self.paintAll("M\(profile) pressed on the keyboard")
                } else if !was {
                    self.paintAll("keyboard back")
                }
            }
        }
    }

    // ------------------------------------------------------------ presets
    /// "+" at the end of the row: the colour now chosen, named by itself
    func addPreset(c: String, b: Int) { s.presets.append(Preset(name: "", c: c, b: b, auto: true)); save() }
    func renamePreset(_ uid: String, name: String, auto: Bool) {
        guard let i = s.presets.firstIndex(where: { $0.uid == uid }) else { return }
        s.presets[i].name = String(name.trimmingCharacters(in: .whitespaces).uppercased().prefix(24))
        s.presets[i].auto = auto
        save()
    }
    func deletePreset(_ uid: String) { s.presets.removeAll { $0.uid == uid }; save() }
    /// dragged onto another preset: it takes that one's place
    func movePreset(_ uid: String, before target: String) {
        guard uid != target, let from = s.presets.firstIndex(where: { $0.uid == uid }) else { return }
        let p = s.presets.remove(at: from)
        let to = s.presets.firstIndex(where: { $0.uid == target }).map { $0 + (from <= $0 ? 1 : 0) } ?? s.presets.count
        s.presets.insert(p, at: min(to, s.presets.count))
        save()
    }
}
