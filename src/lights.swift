// lights.swift — per-key colour (0x8081 PerKeyLightingV2), brightness (0x8040), onboard mode (0x8100).
//
// A key is addressed by its LIGHT INDEX, not its HID usage: letters and digits are usage - 3
// (A 0x04 -> 0x01), modifiers usage - 0x78 (LCtrl 0xE0 -> 0x68), G1..G5 0xB4..0xB8, the logo 0xD2,
// the media keys 0x9B..0x9E, the lighting key 0x99. The page holds the table; this file only moves bytes.

import Foundation

extension G815 {
    /// Colours for any number of keys, four to a report, then one commit (0x8081 fn1, fn7).
    func setKeys(_ keys: [(UInt8, UInt8, UInt8, UInt8)]) throws {
        let pk = try need(0x8081)
        var i = 0
        while i < keys.count {
            var p: [UInt8] = []
            for (k, r, g, b) in keys[i..<min(i + 4, keys.count)] { p += [k, r, g, b] }
            if p.count < 16 { p += [0xFF] }          // an unused slot is marked, never left as key 0
            try call(pk, 1, p)
            i += 4
        }
        try call(pk, 7, [0, 0, 0, 0])
    }

    /// The global brightness the keyboard's own button sets, 0...100.
    func brightness() throws -> Int {
        let r = try call(try need(0x8040), 1)
        return Int(r[0]) << 8 | Int(r[1])
    }
    func setBrightness(_ v: Int) throws {
        try call(try need(0x8040), 2, [UInt8(v >> 8), UInt8(v & 0xFF)])
    }

    /// 1 = the keyboard plays its onboard profile, 2 = the host drives it.
    func onboardMode() throws -> Int { Int(try call(try need(0x8100), 2)[0]) }
    func setOnboardMode(_ m: Int) throws { try call(try need(0x8100), 1, [UInt8(m)]) }
}
