// onboard.swift — the keyboard's own memory (0x8100 Onboard Profiles): what it plays from power-on.
//
// MEASURED on this G815 (firmware U1 31.02, 2.10.2026): 3 profiles (M1..M3) in sectors 1..3, a directory
// in sector 0, factory copies in 0x0101..0x0103. Sector size 256; the last two bytes are CRC-16/CCITT
// (poly 0x1021, init 0xFFFF) over the first 254, big-endian — checked against all four stored sectors.
// Lighting lives at 0xD0: four 11-byte effect blocks — logo, keys, then logo and keys again for the
// dimmed (power-save) state. An effect is [id, params x10]; 0x01 static = [01, R, G, B, 0...].
// There is no room for per-key colours here: the memory holds one effect per zone. Per-key colour is
// RAM only (0x8081) and is painted again by the app at every login.

import Foundation

let LIGHTING_AT = 0xD0
let SECTOR = 256
/// G1–G5's buttons in a profile (MEASURED 8.10.2026), and "a keyboard key with no usage": the key sends nothing
let G_BUTTONS_AT = 0x20
let G_NOTHING: [UInt8] = [0x80, 0x02, 0x00, 0x00]

func crc16(_ d: ArraySlice<UInt8>) -> UInt16 {
    var c: UInt16 = 0xFFFF
    for b in d {
        c ^= UInt16(b) << 8
        for _ in 0..<8 { c = (c & 0x8000) != 0 ? (c << 1) ^ 0x1021 : c << 1 }
    }
    return c
}

extension G815 {
    func readSector(_ s: Int) throws -> [UInt8] {
        let ob = try need(0x8100)
        var out: [UInt8] = []
        for off in stride(from: 0, to: SECTOR, by: 16) {
            out += try call(ob, 5, [UInt8(s >> 8), UInt8(s & 0xFF), UInt8(off >> 8), UInt8(off & 0xFF)]).prefix(16)
        }
        return out
    }

    func writeSector(_ s: Int, _ data: [UInt8]) throws {
        precondition(data.count == SECTOR)
        let ob = try need(0x8100)
        try call(ob, 6, [UInt8(s >> 8), UInt8(s & 0xFF), 0, 0, UInt8(SECTOR >> 8), UInt8(SECTOR & 0xFF)], timeout: 2)
        for off in stride(from: 0, to: SECTOR, by: 16) {
            try call(ob, 7, Array(data[off..<off + 16]), timeout: 2)
        }
        try call(ob, 8, [], timeout: 3)
    }

    /// Profile 1...3 plays one still colour for the keys and one for the logo, from power-on, and its G1–G5 type nothing.
    /// Refuses unless the sector it read carries a valid CRC; reads back and compares after.
    func setOnboardStatic(profile p: Int, keys: (UInt8, UInt8, UInt8), logo: (UInt8, UInt8, UInt8)) throws -> String {
        guard (1...3).contains(p) else { throw HidppError(text: "profile is 1, 2 or 3") }
        var d = try readSector(p)
        let stored = UInt16(d[SECTOR - 2]) << 8 | UInt16(d[SECTOR - 1])
        guard crc16(d[0..<SECTOR - 2]) == stored else {
            throw HidppError(text: String(format: "profile %d: CRC %04x does not match its contents — not touching it", p, stored))
        }
        func block(_ c: (UInt8, UInt8, UInt8)) -> [UInt8] { [0x01, c.0, c.1, c.2] + [UInt8](repeating: 0, count: 7) }
        let light = block(logo) + block(keys) + block(logo) + block(keys)
        // G1–G5 type nothing from the keyboard's memory either (Marko, 8.10.2026: "Please detach G's with functions").
        // Only when the buttons sit where they were MEASURED (8.10.2026): G1–G5 at 0x20, four bytes each
        // (80 02 00 3a = HID keyboard, F1 in M1; 1e..22 = 1..5 in M2), then M1–M3 as 90 0d 00 01..03.
        let gAt = G_BUTTONS_AT, mAt = G_BUTTONS_AT + 20
        let mKeys: [UInt8] = [0x90, 0x0d, 0x00, 0x01, 0x90, 0x0d, 0x00, 0x02, 0x90, 0x0d, 0x00, 0x03]
        let silent = (0..<5).flatMap { _ in G_NOTHING }
        let gKnown = Array(d[mAt..<mAt + 12]) == mKeys
        if Array(d[LIGHTING_AT..<LIGHTING_AT + 44]) == light && (!gKnown || Array(d[gAt..<gAt + 20]) == silent) {
            return "profile \(p): already so"
        }
        d.replaceSubrange(LIGHTING_AT..<LIGHTING_AT + 44, with: light)
        if gKnown { d.replaceSubrange(gAt..<gAt + 20, with: silent) }
        let c = crc16(d[0..<SECTOR - 2])
        d[SECTOR - 2] = UInt8(c >> 8); d[SECTOR - 1] = UInt8(c & 0xFF)
        try writeSector(p, d)
        let back = try readSector(p)
        guard back == d else { throw HidppError(text: "profile \(p): read back differs after the write") }
        return "profile \(p): written and read back"
    }
}
