// LightShow.swift — v35 (15.11.2026): the keyboard as a low-resolution LED display, for other apps.
//
// Marko, 15.11.2026: "my lights are like a low resolution LED LCD display, displaying whatever the app is showing ...
// it needs to have new API commands for light shows, or displaying the pictures from basically converting bitmap image
// to image on the keyboard in the best possible way by limitation of the keyboard."
//
// HTTP on 127.0.0.1:8877 (loopback only), see MANTRA_MANIFEST modules/keyboard-lights.md:
//   GET  /status  /layout  /shows
//   POST /frame     a picture (body = PNG/JPEG, Content-Type image/*) or JSON {rgb | keys | color | path | image_base64}
//   POST /show      {"name":"rainbow"|"all", "seconds":25, "counter":true}   (or POST /show/<name>)
//   POST /stop      the bank's own colours come back
//   POST /config    {"gamma":1.8,"gain":1.0,"fit":"stretch|contain|cover"}
//   POST /idle      {"on":true,"minutes":5,"show":"all"}  the switch "light show after N min of inactivity" (v38); POST /idle/start = START NOW
// Stream: TCP 127.0.0.1:8878, frames of 1 type byte (R raw RGB in /layout order, I image, J JSON) + 4 byte big-endian
// length + payload, up to 30 per second; a stream silent for 5 s lets go of the lights.
// While a show, frame or stream runs the app's own painting (banks, Resolve G-keys, night) stands aside.

import Foundation
import Network
import ImageIO
import CoreGraphics

typealias RGB = (UInt8, UInt8, UInt8)

final class LightShow: @unchecked Sendable {
    static let shared = LightShow()
    static let httpPort: UInt16 = 8877
    static let streamPort: UInt16 = 8878

    struct Cap: Codable { let l: String, id: String; let x: Double, y: Double, w: Double, h: Double }
    struct Lay: Codable { let keys: [Cap] }

    let caps: [Cap]
    let ids: [UInt8]
    private let lock = NSLock()
    private let net = DispatchQueue(label: "g815.lightshow.net")
    private let tickQ = DispatchQueue(label: "g815.lightshow.tick")
    private var wire: Wire?
    private var onStop: (() -> Void)?
    private var ticker: DispatchSourceTimer?
    private var listeners: [NWListener] = []

    // state, under lock
    private var _active = false
    private var mode = "off"            // off | frame | show | stream
    private var showName = ""
    private var showSeconds = 25.0
    private var showCounter = true
    private var showStart = Date()
    private var until: Date?
    private var pending: [UInt8: RGB]?
    private var jobQueued = false
    private var sent: [UInt8: RGB] = [:]
    private var fullAt = Date.distantPast
    private var frames = 0
    private var sentFrames: [Date] = []
    private var lastFrameAt = Date.distantPast
    private var gamma = 1.8, gain = 1.0
    private var fit = "stretch"
    private var streams = 0
    private var errorText = ""

    /// the app's own painting asks this; true while a show, frame or stream owns the lights
    var active: Bool { lock.lock(); defer { lock.unlock() }; return _active }

    init() {
        var lay: Lay? = nil
        for p in [Bundle.main.url(forResource: "layout", withExtension: "json"),
                  URL(fileURLWithPath: NSString(string: "~/Developer/G815_LIGHTS/layout.json").expandingTildeInPath)] {
            if let u = p, let d = try? Data(contentsOf: u), let l = try? JSONDecoder().decode(Lay.self, from: d) { lay = l; break }
        }
        caps = lay?.keys ?? []
        ids = caps.map { UInt8($0.id, radix: 16) ?? 0 }
    }

    // MARK: start / stop

    func start(wire: Wire, onStop: @escaping () -> Void) {
        self.wire = wire; self.onStop = onStop
        for (port, handler) in [(Self.httpPort, true), (Self.streamPort, false)] {
            do {
                let params = NWParameters.tcp
                params.requiredInterfaceType = .loopback
                params.acceptLocalOnly = true
                params.allowLocalEndpointReuse = true
                let l = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
                l.newConnectionHandler = { [weak self] c in
                    guard let self else { c.cancel(); return }
                    if handler { HTTPConn(self, c, self.net).start() } else { StreamConn(self, c, self.net).start() }
                }
                l.stateUpdateHandler = { st in
                    if case .failed(let e) = st { Store.log("light show: port \(port) failed: \(e)") }
                    if case .ready = st { Store.log("light show: listening on 127.0.0.1:\(port)") }
                }
                l.start(queue: net)
                listeners.append(l)
            } catch { Store.log("light show: cannot listen on \(port): \(error)") }
        }
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".mantra/ports")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? "\(Self.httpPort)\n".write(to: dir.appendingPathComponent("g815-lights"), atomically: true, encoding: .utf8)
    }

    private func activate(_ m: String) {   // lock held
        mode = m
        if !_active {
            _active = true
            let t = DispatchSource.makeTimerSource(queue: tickQ)
            t.schedule(deadline: .now(), repeating: .milliseconds(50))
            t.setEventHandler { [weak self] in self?.tick() }
            ticker = t; t.resume()
        }
    }

    // MARK: v36 yield to typing (Marko, 15.11.2026): any key stops the show; while he types, nothing from outside paints.
    // v38 (15.11.2026): the stored "resume" is GONE. It was the culprit of the idle light show: a pattern once posted by any
    // caller (Meditation Room's 20 s patterns, a test) was remembered and replayed, without its 20 s limit, after every
    // 300 s of quiet. Now only IdleShow.swift (his switch in the window) starts a show by itself; a stream or /show from
    // outside is simply accepted again when the pause is over.
    private var pausedUntil = Date.distantPast
    private var pauseGen = 0
    /// 300 s; ~/.mantra/g815-yield-seconds (a number) shortens it for a test, never set by default
    static var yieldSeconds: Double {
        if let t = try? String(contentsOfFile: NSString(string: "~/.mantra/g815-yield-seconds").expandingTildeInPath, encoding: .utf8),
           let v = Double(t.trimmingCharacters(in: .whitespacesAndNewlines)), v > 0 { return v }
        return 300
    }
    private var isPaused: Bool { Date() < pausedUntil }   // lock held

    /// any real key on the Mac (Macros' tap calls this, off the main thread)
    func keyPressed() {
        let secs = Self.yieldSeconds
        net.async { [self] in
            lock.lock()
            let wasActive = _active, first = !isPaused
            pausedUntil = Date().addingTimeInterval(secs)
            pauseGen += 1
            let gen = pauseGen
            lock.unlock()
            if wasActive { stop() }
            if first || wasActive { Store.log("light show: paused on key (outside shows and streams wait \(Int(secs)) s of quiet)") }
            net.asyncAfter(deadline: .now() + secs + 0.05) { [self] in
                lock.lock()
                guard gen == pauseGen else { lock.unlock(); return }
                pausedUntil = .distantPast
                lock.unlock()
                Store.log("light show: pause over after \(Int(secs)) s without a key (nothing is replayed)")
            }
        }
    }

    func stop() {
        lock.lock()
        let was = _active
        _active = false; mode = "off"; showName = ""; until = nil; pending = nil; sent = [:]
        ticker?.cancel(); ticker = nil
        lock.unlock()
        if was { Store.log("light show: stopped"); onStop?() }
    }

    // MARK: frames out

    private func push(_ f: [UInt8: RGB]) {
        lock.lock()
        pending = f; frames += 1; lastFrameAt = Date()
        let need = !jobQueued; jobQueued = true
        lock.unlock()
        if need { wire?.run { [weak self] kb in try self?.flush(kb) } }
    }

    private func flush(_ kb: G815) throws {
        lock.lock()
        let f = pending; pending = nil; jobQueued = false
        let full = Date().timeIntervalSince(fullAt) > 5
        if full { fullAt = Date(); sent = [:] }
        let prev = sent
        lock.unlock()
        guard let f else { return }
        var list: [(UInt8, UInt8, UInt8, UInt8)] = []
        for (i, c) in f {
            if let p = prev[i], p == c { continue }
            list.append((i, c.0, c.1, c.2))
        }
        if list.isEmpty { return }
        do { try kb.setKeys(list) } catch {
            lock.lock(); sent = [:]; errorText = "\(error)"; lock.unlock(); throw error
        }
        lock.lock()
        for (i, c) in f { sent[i] = c }; errorText = ""
        sentFrames.append(Date()); if sentFrames.count > 200 { sentFrames.removeFirst(100) }
        lock.unlock()
    }

    private func tick() {
        lock.lock()
        let m = mode, exp = until, name = showName, counter = showCounter, secs = showSeconds, t0 = showStart
        lock.unlock()
        if let e = exp, Date() > e { stop(); return }
        guard m == "show" else { return }
        let t = Date().timeIntervalSince(t0)
        var f = blank()
        var nm = name
        var tt = t
        if name == "all" {
            let n = Int(t / secs) % Shows.names.count
            nm = Shows.names[n]; tt = t - Double(Int(t / secs)) * secs
        }
        shows.render(nm, t: tt, caps: caps, into: &f)
        if counter { Shows.counter(into: &f) }
        push(f)
    }

    private let shows = Shows()

    private func blank() -> [UInt8: RGB] {
        var f: [UInt8: RGB] = [:]
        for i in ids { f[i] = (0, 0, 0) }
        return f
    }

    // MARK: public commands (all return a JSON-able dictionary)

    /// force: his own switch (IdleShow) starts through the key pause
    func showCmd(name: String, seconds: Double?, counter: Bool?, ttl: Double?, force: Bool = false) -> [String: Any] {
        guard name == "all" || Shows.names.contains(name) else { return ["ok": false, "error": "unknown show", "shows": Shows.names + ["all"]] }
        lock.lock()
        if force { pausedUntil = .distantPast; pauseGen += 1 }
        if isPaused { lock.unlock(); return ["ok": true, "show": name, "paused": true] }
        showName = name; showSeconds = max(2, seconds ?? 25); showCounter = counter ?? true; showStart = Date()
        until = (ttl ?? 0) > 0 ? Date().addingTimeInterval(ttl!) : nil
        activate("show")
        lock.unlock()
        Store.log("light show: show \(name)")
        return ["ok": true, "show": name]
    }

    /// One frame by its keys (partial: the rest dark unless keep).
    func frameKeys(_ f: [UInt8: RGB], source: String, ttl: Double?) -> [String: Any] {
        lock.lock()
        if isPaused { lock.unlock(); return ["ok": true, "keys": 0, "paused": true] }
        until = (ttl ?? 0) > 0 ? Date().addingTimeInterval(ttl!) : (source == "stream" ? Date().addingTimeInterval(5) : nil)
        activate(source == "stream" ? "stream" : "frame")
        lock.unlock()
        push(f)
        return ["ok": true, "keys": f.count]
    }

    func config(_ d: [String: Any]) -> [String: Any] {
        lock.lock()
        if let g = d["gamma"] as? Double { gamma = max(0.5, min(4, g)) }
        if let g = d["gain"] as? Double { gain = max(0.1, min(4, g)) }
        if let f = d["fit"] as? String, ["stretch", "contain", "cover"].contains(f) { fit = f }
        let r: [String: Any] = ["ok": true, "gamma": gamma, "gain": gain, "fit": fit]
        lock.unlock()
        return r
    }

    func status() -> [String: Any] {
        lock.lock(); defer { lock.unlock() }
        let now = Date()
        let recent = sentFrames.filter { now.timeIntervalSince($0) < 5 }.count
        var r: [String: Any] = ["ok": true, "active": _active, "mode": mode, "show": showName, "frames": frames,
                                "fps": Double(recent) / 5, "keys": caps.count, "gamma": gamma, "gain": gain, "fit": fit,
                                "http_port": Int(Self.httpPort), "stream_port": Int(Self.streamPort), "version": VERSION, "paused": isPaused,
                                "idle_show": IdleShow.shared.statusDict()]
        r["last_frame_age"] = lastFrameAt == .distantPast ? -1 : now.timeIntervalSince(lastFrameAt)
        if !errorText.isEmpty { r["last_error"] = errorText }
        return r
    }

    func layoutJSON() -> [String: Any] {
        ["ok": true, "order": "index n of an rgb array = keys[n]",
         "keys": caps.enumerated().map { (n, c) in ["n": n, "id": c.id, "label": c.l, "x": c.x, "y": c.y, "w": c.w, "h": c.h] as [String: Any] },
         "width": 24.0, "height": 7.5]
    }

    // MARK: frame requests

    /// body of POST /frame or one stream frame; kind: "image" | "json"
    func handleFrame(kind: String, body: Data, query: [String: String], source: String) -> [String: Any] {
        var ttl = Double(query["ttl"] ?? "")
        if kind == "image" {
            return fromImage(body, fit: query["fit"], gamma: Double(query["gamma"] ?? ""), gain: Double(query["gain"] ?? ""), source: source, ttl: ttl)
        }
        guard let o = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else { return ["ok": false, "error": "body is not JSON"] }
        if let t = o["ttl"] as? Double { ttl = t }
        _ = config(o)
        if let rgb = o["rgb"] as? [Any] {
            var flat: [Int] = []
            for e in rgb {
                if let a = e as? [Any] { flat += a.map { ($0 as? NSNumber)?.intValue ?? 0 } } else if let n = e as? NSNumber { flat.append(n.intValue) }
            }
            guard flat.count >= caps.count * 3 else { return ["ok": false, "error": "rgb needs \(caps.count) colours in /layout order"] }
            var f: [UInt8: RGB] = [:]
            for (n, i) in ids.enumerated() { f[i] = (UInt8(max(0, min(255, flat[n * 3]))), UInt8(max(0, min(255, flat[n * 3 + 1]))), UInt8(max(0, min(255, flat[n * 3 + 2])))) }
            return frameKeys(f, source: source, ttl: ttl)
        }
        if let keys = o["keys"] as? [String: Any] {
            var f = (o["keep"] as? Bool == true) ? lastSent() : blank()
            for (k, v) in keys {
                guard let i = UInt8(k, radix: 16) else { continue }
                if let h = v as? String, let c = Self.parseHex(h) { f[i] = c }
                else if let a = v as? [Any], a.count >= 3 { f[i] = (UInt8(max(0, min(255, (a[0] as? NSNumber)?.intValue ?? 0))), UInt8(max(0, min(255, (a[1] as? NSNumber)?.intValue ?? 0))), UInt8(max(0, min(255, (a[2] as? NSNumber)?.intValue ?? 0)))) }
            }
            return frameKeys(f, source: source, ttl: ttl)
        }
        if let h = o["color"] as? String, let c = Self.parseHex(h) {
            var f = blank(); for i in ids { f[i] = c }
            return frameKeys(f, source: source, ttl: ttl)
        }
        if let b64 = o["image_base64"] as? String, let d = Data(base64Encoded: b64) {
            return fromImage(d, fit: o["fit"] as? String, gamma: nil, gain: nil, source: source, ttl: ttl)
        }
        if let p = o["path"] as? String, let d = try? Data(contentsOf: URL(fileURLWithPath: NSString(string: p).expandingTildeInPath)) {
            return fromImage(d, fit: o["fit"] as? String, gamma: nil, gain: nil, source: source, ttl: ttl)
        }
        return ["ok": false, "error": "give rgb, keys, color, path or image_base64"]
    }

    func handleRaw(_ d: Data, source: String) -> [String: Any] {
        guard d.count >= caps.count * 3 else { return ["ok": false, "error": "raw frame too short"] }
        var f: [UInt8: RGB] = [:]
        let b = [UInt8](d)
        for (n, i) in ids.enumerated() { f[i] = (b[n * 3], b[n * 3 + 1], b[n * 3 + 2]) }
        return frameKeys(f, source: source, ttl: nil)
    }

    private func lastSent() -> [UInt8: RGB] {
        lock.lock(); defer { lock.unlock() }
        var f: [UInt8: RGB] = [:]
        for i in ids { f[i] = sent[i] ?? (0, 0, 0) }
        return f
    }

    static func parseHex(_ s: String) -> RGB? {
        let h = s.hasPrefix("#") ? String(s.dropFirst()) : s
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        return (UInt8(v >> 16 & 0xFF), UInt8(v >> 8 & 0xFF), UInt8(v & 0xFF))
    }

    // MARK: picture to keys

    // sRGB byte to linear light, once
    private static let toLinear: [Float] = (0..<256).map { i in
        let c = Float(i) / 255
        return c <= 0.04045 ? c / 12.92 : powf((c + 0.055) / 1.055, 2.4)
    }
    private static let pxPerUnit = 20

    /// The picture laid over the whole keyboard (24 x 7.5 key units, 20 pixels a unit), each key the average of the
    /// pixels under it (in linear light, with a small margin so the gaps between keys do not count), then
    /// gamma and gain for the LED, then the keyboard's dead zone: a key shows nothing below value 45 (LESSONS 20), so
    /// a colour keeps its channel proportions, its strongest channel runs 46...255 and anything under 2 % stays dark.
    func fromImage(_ data: Data, fit fitIn: String?, gamma gIn: Double?, gain gnIn: Double?, source: String, ttl: Double?) -> [String: Any] {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            return ["ok": false, "error": "not a picture macOS can read (PNG, JPEG, GIF, TIFF, HEIC)"]
        }
        lock.lock(); let g = gIn ?? gamma, gn = gnIn ?? gain, ft = fitIn ?? fit; lock.unlock()
        let P = Self.pxPerUnit, W = 24 * P, H = Int(7.5 * Double(P))
        var buf = [UInt8](repeating: 0, count: W * H * 4)
        let cs = CGColorSpace(name: CGColorSpace.sRGB)!
        let ok: Bool = buf.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: W, height: H, bitsPerComponent: 8, bytesPerRow: W * 4, space: cs,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
            ctx.interpolationQuality = .high
            let iw = Double(img.width), ih = Double(img.height)
            var r = CGRect(x: 0, y: 0, width: W, height: H)
            if ft != "stretch" {
                let sx = Double(W) / iw, sy = Double(H) / ih
                let s = ft == "cover" ? max(sx, sy) : min(sx, sy)
                r = CGRect(x: (Double(W) - iw * s) / 2, y: (Double(H) - ih * s) / 2, width: iw * s, height: ih * s)
            }
            ctx.draw(img, in: r)
            return true
        }
        guard ok else { return ["ok": false, "error": "no drawing context"] }
        var f: [UInt8: RGB] = [:]
        let lin = Self.toLinear
        for (n, c) in caps.enumerated() {
            let inset = min(0.12, c.w * 0.15)
            let x0 = max(0, Int((c.x + inset) * Double(P))), x1 = min(W, max(x0 + 1, Int((c.x + c.w - inset) * Double(P))))
            let y0 = max(0, Int((c.y + inset) * Double(P))), y1 = min(H, max(y0 + 1, Int((c.y + c.h - inset) * Double(P))))
            var sr: Float = 0, sg: Float = 0, sb: Float = 0, cnt: Float = 0
            for y in y0..<y1 {
                var o = (y * W + x0) * 4
                for _ in x0..<x1 { sr += lin[Int(buf[o])]; sg += lin[Int(buf[o + 1])]; sb += lin[Int(buf[o + 2])]; cnt += 1; o += 4 }
            }
            if cnt == 0 { f[ids[n]] = (0, 0, 0); continue }
            f[ids[n]] = Self.led(sr / cnt, sg / cnt, sb / cnt, gamma: g, gain: gn)
        }
        let r = frameKeys(f, source: source, ttl: ttl)
        return r
    }

    /// linear light 0...1 per channel to the LED's bytes
    static func led(_ r: Float, _ g: Float, _ b: Float, gamma: Double, gain: Double) -> RGB {
        let inv = Float(1 / gamma), gn = Float(gain)
        func e(_ x: Float) -> Float { min(1, powf(max(0, x) * gn, inv)) }
        let er = e(r), eg = e(g), eb = e(b)
        let m = max(er, eg, eb)
        if m < 0.02 { return (0, 0, 0) }
        let out = 46 + (255 - 46) * m           // the strongest channel, above the dead zone
        func ch(_ x: Float) -> UInt8 { UInt8(max(0, min(255, (x / m * out).rounded()))) }
        return (ch(er), ch(eg), ch(eb))
    }
}

// MARK: - the ten built-in shows

final class Shows {
    static let names = ["sweep", "rainbow", "digits", "rain", "ripple", "scan", "checker", "chase", "sparkle", "heartbeat"]
    private var drops: [(x: Double, y: Double, v: Double)] = []
    private var sparks: [UInt8: Double] = [:]
    private var lastT = 0.0

    static func hsv(_ h: Double, _ s: Double = 1, _ v: Double = 1) -> RGB {
        let hh = h - floor(h), i = Int(hh * 6), f = hh * 6 - Double(i)
        let p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
        var r = 0.0, g = 0.0, b = 0.0
        switch i % 6 { case 0: r = v; g = t; b = p; case 1: r = q; g = v; b = p; case 2: r = p; g = v; b = t
        case 3: r = p; g = q; b = v; case 4: r = t; g = p; b = v; default: r = v; g = p; b = q }
        return (UInt8(r * 255), UInt8(g * 255), UInt8(b * 255))
    }

    /// F-row: F1...F6 the binary seconds (yellow = 1), F7...F12 dark, ESC green/red toggling each second
    static func counter(into f: inout [UInt8: RGB]) {
        let s = Int(Date().timeIntervalSince1970) % 60
        for b in 0..<6 { f[UInt8(0x37 + b)] = (s >> b) & 1 == 1 ? (255, 255, 0) : (60, 0, 0) }
        for i in 0x3d...0x42 { f[UInt8(i)] = (0, 0, 0) }
        f[0x26] = s % 2 == 1 ? (0, 255, 0) : (255, 0, 0)
    }

    private static let font: [Character: String] = [
        "0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111", "4": "101101111001001",
        "5": "111100111001111", "6": "111100111101111", "7": "111001001001001", "8": "111101111101111", "9": "111101111001111"]

    func render(_ name: String, t: Double, caps: [LightShow.Cap], into f: inout [UInt8: RGB]) {
        let keys = caps.map { (id: UInt8($0.id, radix: 16) ?? 0, cx: $0.x + $0.w / 2, cy: $0.y + $0.h / 2, x: $0.x, y: $0.y) }
        let main = keys.filter { $0.y >= 2.4 }
        switch name {
        case "sweep":
            let pos = (t * 8).truncatingRemainder(dividingBy: 28) - 2
            for k in keys { let d = abs(k.cx - pos); if d < 2 { f[k.id] = Shows.hsv(t * 0.05, 1, 1 - d / 2) } }
        case "rainbow":
            for k in keys { f[k.id] = Shows.hsv(k.cx / 14 - t * 0.4 + k.cy * 0.03) }
        case "digits":
            let s = Int(Date().timeIntervalSince1970) % 100
            let txt = String(format: "%02d", s)
            for k in main { f[k.id] = (0, 0, 25) }
            let rows = Array(Set(main.map { $0.y })).sorted()
            for (n, ch) in txt.enumerated() {
                guard let bits = Shows.font[ch] else { continue }
                for (j, bit) in bits.enumerated() where bit == "1" {
                    let col = 3 + n * 4 + j % 3, row = j / 3
                    for k in main where Int(k.cx - 1.5) + 1 == col && rows.firstIndex(of: k.y) == row {
                        f[k.id] = n == 0 ? (255, 255, 255) : (255, 160, 0)
                    }
                }
            }
        case "rain":
            let dt = max(0, min(0.2, t - lastT)); lastT = t
            if Double.random(in: 0...1) < 0.45 { drops.append((Double.random(in: 1.5...16), 1.0, Double.random(in: 5...9))) }
            drops = drops.map { ($0.x, $0.y + $0.v * dt, $0.v) }.filter { $0.y < 7.5 }
            for d in drops { for k in main where abs(k.cx - d.x) < 0.7 {
                let dy = d.y - k.cy
                if dy >= 0 && dy < 2.2 { f[k.id] = (0, UInt8(255 * (1 - dy / 2.2)), 255) }
            } }
        case "ripple":
            for k in keys {
                let d = hypot(k.cx - 8.7, (k.cy - 4.5) * 1.6)
                let v = pow(max(0, cos((d - t * 6) * 1.2)), 3)
                f[k.id] = Shows.hsv(0.55 + d * 0.02, 1, v)
            }
        case "scan":
            let y = 1.2 + abs((t * 3).truncatingRemainder(dividingBy: 12) - 6) / 6 * 6
            for k in keys { let d = abs(k.cy - y); if d < 1.1 { f[k.id] = (0, UInt8(255 * (1.1 - d) / 1.1), 60) } }
        case "checker":
            let ph = Int(t) % 2
            for k in keys { f[k.id] = (Int(k.cx) + Int(k.cy) + ph) % 2 == 0 ? (255, 0, 80) : (0, 40, 255) }
        case "chase":
            let cx = main.map { $0.cx }.reduce(0, +) / Double(max(1, main.count)), cy = main.map { $0.cy }.reduce(0, +) / Double(max(1, main.count))
            let ring = main.sorted { atan2($0.cy - cy, $0.cx - cx) < atan2($1.cy - cy, $1.cx - cx) }
            let n = Double(ring.count)
            for (j, k) in ring.enumerated() {
                let d = (Double(j) - t * 12).truncatingRemainder(dividingBy: n)
                let dd = d < 0 ? d + n : d
                if dd < 12 { f[k.id] = Shows.hsv(Double(j) / n, 1, 1 - dd / 12) }
            }
        case "sparkle":
            for k in keys.shuffled().prefix(2) { sparks[k.id] = 1.0 }
            for (i, v) in sparks {
                let nv = v - 0.06
                if nv <= 0 { sparks[i] = nil } else { sparks[i] = nv; f[i] = (UInt8(255 * nv), UInt8(255 * nv), UInt8(255 * nv * nv)) }
            }
        default: // heartbeat
            let ph = (t * 1.1).truncatingRemainder(dividingBy: 1)
            let v = max(exp(-pow((ph - 0.1) / 0.06, 2)), 0.7 * exp(-pow((ph - 0.3) / 0.08, 2)))
            for k in keys { f[k.id] = (UInt8(255 * v), 0, UInt8(30 * v)) }
        }
    }
}

// MARK: - HTTP (one request after another on a connection)

final class HTTPConn {
    let ls: LightShow, c: NWConnection, q: DispatchQueue
    var buf = Data()
    init(_ ls: LightShow, _ c: NWConnection, _ q: DispatchQueue) { self.ls = ls; self.c = c; self.q = q }

    func start() { c.start(queue: q); receive() }

    func receive() {
        c.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { [self] data, _, done, err in
            if let d = data, !d.isEmpty { buf.append(d); process() }
            if done || err != nil { c.cancel(); return }
            receive()
        }
    }

    func process() {
        while let r = buf.range(of: Data([13, 10, 13, 10])) {
            let head = String(decoding: buf[buf.startIndex..<r.lowerBound], as: UTF8.self)
            var lines = head.components(separatedBy: "\r\n")
            let first = lines.removeFirst().split(separator: " ").map(String.init)
            var hdr: [String: String] = [:]
            for l in lines { if let i = l.firstIndex(of: ":") { hdr[l[..<i].lowercased()] = l[l.index(after: i)...].trimmingCharacters(in: .whitespaces) } }
            let len = Int(hdr["content-length"] ?? "0") ?? 0
            if len > 16 << 20 { send(413, ["ok": false, "error": "too big"]); c.cancel(); return }
            guard buf.distance(from: r.upperBound, to: buf.endIndex) >= len else { return }
            let body = Data(buf[r.upperBound..<buf.index(r.upperBound, offsetBy: len)])
            buf = Data(buf[buf.index(r.upperBound, offsetBy: len)...])
            guard first.count >= 2 else { send(400, ["ok": false, "error": "bad request"]); continue }
            let (code, obj) = route(first[0], first[1], hdr, body)
            send(code, obj)
        }
    }

    func route(_ method: String, _ target: String, _ hdr: [String: String], _ body: Data) -> (Int, [String: Any]) {
        let parts = target.split(separator: "?", maxSplits: 1).map(String.init)
        let path = parts[0]
        var query: [String: String] = [:]
        if parts.count > 1 {
            for kv in parts[1].split(separator: "&") {
                let p = kv.split(separator: "=", maxSplits: 1).map(String.init)
                if p.count == 2 { query[p[0]] = p[1].removingPercentEncoding ?? p[1] }
            }
        }
        if method == "POST" || path == "/stop" {   // v38: who calls (the culprit hunt of 15.11.2026)
            Store.log("light show: \(method) \(path) from \(hdr["user-agent"] ?? "an unnamed client")")
        }
        switch (method, path) {
        case ("POST", "/idle"):
            let o = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            IdleShow.shared.apply(o); return (200, IdleShow.shared.statusDict())
        case ("POST", "/idle/start"): IdleShow.shared.startNow(); return (200, ["ok": true])
        case ("GET", "/idle"): return (200, IdleShow.shared.statusDict())
        case ("GET", "/status"), ("GET", "/"), ("GET", "/health"): return (200, ls.status())
        case ("GET", "/layout"): return (200, ls.layoutJSON())
        case ("GET", "/shows"): return (200, ["ok": true, "shows": Shows.names, "also": "all (every show in turn)"])
        case ("POST", "/stop"), ("GET", "/stop"): ls.stop(); return (200, ["ok": true])
        case ("POST", "/config"):
            let o = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            return (200, ls.config(o))
        case ("POST", "/show"):
            let o = (try? JSONSerialization.jsonObject(with: body) as? [String: Any]) ?? [:]
            let name = (o["name"] as? String) ?? query["name"] ?? ""
            let r = ls.showCmd(name: name, seconds: (o["seconds"] as? Double) ?? Double(query["seconds"] ?? ""),
                               counter: (o["counter"] as? Bool) ?? query["counter"].map { $0 != "0" },
                               ttl: (o["ttl"] as? Double) ?? Double(query["ttl"] ?? ""))
            return (r["ok"] as? Bool == true ? 200 : 400, r)
        case ("POST", "/frame"):
            let ct = (hdr["content-type"] ?? "").lowercased()
            let kind = ct.hasPrefix("image/") || ct.contains("octet-stream") ? "image" : "json"
            let r = ls.handleFrame(kind: kind, body: body, query: query, source: "frame")
            return (r["ok"] as? Bool == true ? 200 : 400, r)
        default:
            if method == "POST", path.hasPrefix("/show/") {
                let r = ls.showCmd(name: String(path.dropFirst(6)), seconds: Double(query["seconds"] ?? ""),
                                   counter: query["counter"].map { $0 != "0" }, ttl: Double(query["ttl"] ?? ""))
                return (r["ok"] as? Bool == true ? 200 : 400, r)
            }
            return (404, ["ok": false, "error": "GET /status /layout /shows /idle, POST /frame /show /stop /config /idle /idle/start"])
        }
    }

    func send(_ code: Int, _ obj: [String: Any]) {
        let b = (try? JSONSerialization.data(withJSONObject: obj)) ?? Data("{}".utf8)
        let text = code == 200 ? "OK" : (code == 400 ? "Bad Request" : "Error")
        var out = Data("HTTP/1.1 \(code) \(text)\r\nContent-Type: application/json\r\nContent-Length: \(b.count)\r\nConnection: keep-alive\r\n\r\n".utf8)
        out.append(b)
        c.send(content: out, completion: .contentProcessed { _ in })
    }
}

// MARK: - the stream: type byte + 4 byte length + payload

final class StreamConn {
    let ls: LightShow, c: NWConnection, q: DispatchQueue
    var buf = Data()
    init(_ ls: LightShow, _ c: NWConnection, _ q: DispatchQueue) { self.ls = ls; self.c = c; self.q = q }
    func start() { c.start(queue: q); receive() }
    func receive() {
        c.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { [self] data, _, done, err in
            if let d = data, !d.isEmpty { buf.append(d); process() }
            if done || err != nil { c.cancel(); return }
            receive()
        }
    }
    func process() {
        while buf.count >= 5 {
            let s = buf.startIndex
            let type = buf[s]
            let len = Int(buf[s + 1]) << 24 | Int(buf[s + 2]) << 16 | Int(buf[s + 3]) << 8 | Int(buf[s + 4])
            if len > 16 << 20 { c.cancel(); return }
            guard buf.count >= 5 + len else { return }
            let payload = Data(buf[(s + 5)..<(s + 5 + len)])
            buf = Data(buf[(s + 5 + len)...])
            switch type {
            case UInt8(ascii: "R"): _ = ls.handleRaw(payload, source: "stream")
            case UInt8(ascii: "I"): _ = ls.handleFrame(kind: "image", body: payload, query: [:], source: "stream")
            case UInt8(ascii: "J"): _ = ls.handleFrame(kind: "json", body: payload, query: [:], source: "stream")
            default: break
            }
        }
    }
}
