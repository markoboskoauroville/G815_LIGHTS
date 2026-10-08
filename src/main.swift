// main.swift — g815, the command line over the wire.

import Foundation

let NAMES: [UInt16: String] = [
    0x0000: "Root", 0x0001: "FeatureSet", 0x0003: "FirmwareInfo", 0x0005: "DeviceName",
    0x00C2: "DFUControl", 0x00D0: "DFU", 0x1802: "DeviceReset", 0x1803: "GPIO", 0x1806: "ConfigDeviceProps",
    0x1814: "ChangeHost", 0x1815: "Hosts", 0x18A1: "LEDTest", 0x1B04: "ReprogControlsV4",
    0x1BC0: "ReportHIDUsages", 0x4100: "Encryption", 0x4522: "DisableKeys", 0x4530: "DualPlatform",
    0x4540: "KeyboardLayout", 0x8010: "GKeys", 0x8020: "MKeys", 0x8030: "MR", 0x8040: "BrightnessControl",
    0x8060: "ReportRate", 0x8070: "ColorLEDEffects", 0x8071: "RGBEffects", 0x8080: "PerKeyLighting",
    0x8081: "PerKeyLightingV2", 0x8100: "OnboardProfiles", 0x8110: "MouseButtonSpy",
]

func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    if args.first == "serve" { serve(); return }
    let kb = try G815()
    switch args.first ?? "features" {
    case "features":
        print("serial \(kb.serial)")
        for (i, id, v) in try kb.features() {
            print(String(format: "  0x%02x  0x%04x v%d  %@", i, id, v, NAMES[id] ?? "?"))
        }
    case "call":
        // g815 call <featureId hex> <function> [param bytes hex...]
        let fid = UInt16(args[1], radix: 16)!
        let fn = UInt8(args[2])!
        let params = args.dropFirst(3).map { UInt8($0, radix: 16)! }
        let i = try kb.need(fid)
        print(hex(try kb.call(i, fn, params)))
    case "set":
        // g815 set 29:ff0000 2a:00ff00 ...   (light index : rrggbb)
        let keys = try args.dropFirst().map { a -> (UInt8, UInt8, UInt8, UInt8) in
            let part = a.split(separator: ":")
            guard part.count == 2, let k = UInt8(part[0], radix: 16), let c = UInt32(part[1], radix: 16) else {
                throw HidppError(text: "bad key \(a), want index:rrggbb")
            }
            return (k, UInt8(c >> 16 & 0xFF), UInt8(c >> 8 & 0xFF), UInt8(c & 0xFF))
        }
        try kb.setKeys(keys)
        print("ok \(keys.count) keys")
    case "mode":
        if args.count > 1 { try kb.setOnboardMode(Int(args[1])!) }
        print("mode \(try kb.onboardMode())")
    case "brightness":
        if args.count > 1 { try kb.setBrightness(Int(args[1])!) }
        print("brightness \(try kb.brightness())")
    case "onboard":
        // g815 onboard <1|2|3|all> <keys rrggbb> <logo rrggbb>
        func rgb(_ h: String) -> (UInt8, UInt8, UInt8) {
            let c = UInt32(h, radix: 16) ?? 0
            return (UInt8(c >> 16 & 0xFF), UInt8(c >> 8 & 0xFF), UInt8(c & 0xFF))
        }
        let which = args[1] == "all" ? [1, 2, 3] : [Int(args[1])!]
        for p in which { print(try kb.setOnboardStatic(profile: p, keys: rgb(args[2]), logo: rgb(args[3]))) }
    case "probe":
        // g815 probe <seconds> [feature:fn[:bytes]] ... — the calls in order (each reply or error printed), then every
        // report the keyboard sends on its own for <seconds>, timed (T3, 8.10.2026: what do MR, G1, M1..M3 send?)
        // e.g.  g815 probe 20 8010:2:01     G-key software control on, then 20 s of listening
        setvbuf(stdout, nil, _IONBF, 0)
        let start = Date()
        func t() -> String { String(format: "%6.2f", Date().timeIntervalSince(start)) }
        kb.onUnasked = { m in print("\(t())  heard  \(hex(m))") }
        for a in args.dropFirst(2) {
            let p = a.split(separator: ":")
            guard p.count >= 2, let fid = UInt16(p[0], radix: 16), let fn = UInt8(p[1]) else { print("bad call \(a)"); continue }
            let bytes = p.count > 2 ? stride(from: 0, to: p[2].count, by: 2).compactMap { i -> UInt8? in
                let s = p[2].dropFirst(i).prefix(2); return UInt8(s, radix: 16) } : []
            do {
                guard let i = try kb.index(of: fid) else { print("\(t())  \(a)  no such feature"); continue }
                print("\(t())  \(a)  index 0x\(String(format: "%02x", i))  reply \(hex(try kb.call(i, fn, bytes)))")
            } catch { print("\(t())  \(a)  error \(error)") }
        }
        let secs = Double(args.count > 1 ? args[1] : "0") ?? 0
        if secs > 0 { print("\(t())  listening \(Int(secs)) s: press the keys now") }
        while Date().timeIntervalSince(start) < secs { kb.drain(); usleep(10_000) }
        kb.drain()
        print("\(t())  done")
    case "sector":
        print(hex(try kb.readSector(Int(args[1], radix: 16)!)))
    default:
        throw HidppError(text: "usage: g815 features | call <feature> <fn> [bytes] | probe <seconds> [feature:fn:bytes ...] | set i:rrggbb... | mode [1|2] | brightness [0-100]")
    }
}

do { try run() } catch { FileHandle.standardError.write("g815: \(error)\n".data(using: .utf8)!); exit(1) }
