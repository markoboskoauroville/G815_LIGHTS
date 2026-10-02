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

struct Preset: Codable, Identifiable, Equatable {
    var name: String
    var c: String
    var b: Int
    var id: String { name + c + String(b) }
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
    static let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".g815")
    static let file = dir.appendingPathComponent("settings.json")

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
        wire.onError = { [weak self] e in Task { @MainActor in self?.connected = false; self?.error = e } }
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

    func paintAll() { paint(layout.keys.map(\.id)) }

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
                if i == self.s.active { self.paintAll() }
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
        wire.run { kb in try kb.call(try kb.need(0x8100), 3, [0, UInt8(i)]) }
        paintAll()
    }

    // ------------------------------------------------------------ the keyboard's own state
    func setBrightness(_ v: Int) {
        brightness = v
        wire.run { kb in try kb.setBrightness(max(0, min(100, v))) }
    }

    /// Once a second: is it there, which bank, how bright. A keyboard that comes back is painted again;
    /// an M key pressed on the keyboard switches the bank here.
    func poll() {
        guard wire.queued == 0 else { return }
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
                    self.paintAll()
                } else if !was {
                    self.paintAll()
                }
            }
        }
    }

    // ------------------------------------------------------------ presets
    func savePreset(name: String, c: String, b: Int) {
        let n = name.isEmpty ? "#" + c.uppercased() : String(name.uppercased().prefix(16))
        s.presets.append(Preset(name: n, c: c, b: b))
        save()
    }
    func deletePreset(_ p: Preset) { s.presets.removeAll { $0 == p }; save() }
}
