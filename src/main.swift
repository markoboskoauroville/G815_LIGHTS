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
    default:
        throw HidppError(text: "usage: g815 features | call <feature> <fn> [bytes] | set i:rrggbb... | mode [1|2] | brightness [0-100]")
    }
}

do { try run() } catch { FileHandle.standardError.write("g815: \(error)\n".data(using: .utf8)!); exit(1) }
