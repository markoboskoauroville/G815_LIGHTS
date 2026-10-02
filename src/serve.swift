// serve.swift — `g815 serve`: one line in, one JSON line out, the device kept open between lines.
// The Hammerspoon app (g815.lua) holds this process for as long as it runs. When the keyboard is
// unplugged a command fails, the device is dropped, and the next command opens it again.
//
//   paint 26:ff0000 27:00ff00 ...     colours, then one commit
//   bright [0-100]                    the keyboard's own brightness (the button's), read or set
//   profile <1|2|3>                   switch the keyboard's bank (its M1..M3)
//   status                            connected, serial, brightness, onboard mode and profile
//   onboard <1|2|3|all> <keys> <logo> one still colour per zone into the keyboard's memory

import Foundation

func reply(_ d: [String: Any]) {
    let data = try! JSONSerialization.data(withJSONObject: d)
    FileHandle.standardOutput.write(data + "\n".data(using: .utf8)!)
}

func rgbOf(_ h: Substring) -> (UInt8, UInt8, UInt8)? {
    guard h.count == 6, let c = UInt32(h, radix: 16) else { return nil }
    return (UInt8(c >> 16 & 0xFF), UInt8(c >> 8 & 0xFF), UInt8(c & 0xFF))
}

func serve() {
    setvbuf(stdout, nil, _IONBF, 0)
    var kb: G815? = nil
    while let line = readLine() {
        let w = line.split(separator: " ")
        guard let verb = w.first else { continue }
        do {
            if kb == nil { kb = try G815() }
            let k = kb!
            switch verb {
            case "paint":
                var keys: [(UInt8, UInt8, UInt8, UInt8)] = []
                for a in w.dropFirst() {
                    let p = a.split(separator: ":")
                    guard p.count == 2, let i = UInt8(p[0], radix: 16), let c = rgbOf(p[1]) else { continue }
                    keys.append((i, c.0, c.1, c.2))
                }
                try k.setKeys(keys)
                reply(["ok": true, "painted": keys.count])
            case "bright":
                if w.count > 1, let v = Int(w[1]) { try k.setBrightness(max(0, min(100, v))) }
                reply(["ok": true, "brightness": try k.brightness()])
            case "profile":
                // the keyboard's own bank, as its M1..M3 keys choose it
                guard w.count == 2, let n = Int(w[1]), (1...3).contains(n) else { reply(["ok": false, "error": "profile 1|2|3"]); continue }
                try k.call(try k.need(0x8100), 3, [0, UInt8(n)])
                reply(["ok": true, "profile": n])
            case "status":
                let ob = try k.need(0x8100)
                reply(["ok": true, "connected": true, "serial": k.serial, "brightness": try k.brightness(),
                       "mode": try k.onboardMode(), "profile": Int(try k.call(ob, 4)[1])])
            case "onboard":
                guard w.count == 4, let keys = rgbOf(w[2]), let logo = rgbOf(w[3]) else {
                    reply(["ok": false, "error": "onboard <1|2|3|all> <keys rrggbb> <logo rrggbb>"]); continue
                }
                let which = w[1] == "all" ? [1, 2, 3] : [Int(w[1]) ?? 0]
                var said: [String] = []
                for p in which { said.append(try k.setOnboardStatic(profile: p, keys: keys, logo: logo)) }
                reply(["ok": true, "said": said])
            default:
                reply(["ok": false, "error": "unknown verb \(verb)"])
            }
        } catch {
            kb = nil                                  // unplugged, or asleep: open it again next time
            reply(["ok": false, "connected": false, "error": "\(error)"])
        }
    }
}
