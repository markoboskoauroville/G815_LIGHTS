// ask.swift — one key for Marko to press, shown on the big screen until he presses it.
//   ask "MR" ["what to watch"] [--watch probe.txt] [--match "heard"] [--keys 96,122] [--timeout 120]
// A box in the middle of the first screen says the key. It goes away when a key reaches macOS (any key, read by a
// listen-only tap; only those key codes with --keys, none with --keys none), when a new line containing --match
// lands in the watched file (the probe's output, or ~/.g815/log.txt with --match "G keys:"), or when he clicks it (for a key the Mac never
// sees, like MR). It prints what ended it, with the time, so the probe's lines can be matched to the press.
//   swiftc -O tests/ask.swift -o /tmp/ask
import AppKit

var args = Array(CommandLine.arguments.dropFirst())
func opt(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    defer { args.removeSubrange(i...(i + 1)) }
    return args[i + 1]
}
let watch = opt("--watch"), match = opt("--match") ?? "heard", onlyKeys = opt("--keys"), timeout = Double(opt("--timeout") ?? "120") ?? 120
let key = args.first ?? "?", note = args.count > 1 ? args[1] : "nothing happens? click this box"
let start = Date()
func done(_ why: String) {
    print(String(format: "%.2f s  %@", Date().timeIntervalSince(start), why)); fflush(stdout); exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let screen = NSScreen.screens[0].frame
let size = NSSize(width: 760, height: 300)
let panel = NSPanel(contentRect: NSRect(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2,
                                        width: size.width, height: size.height),
                    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
panel.level = .screenSaver
panel.isOpaque = false
panel.backgroundColor = .clear
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

final class Box: NSView {
    override func draw(_ r: NSRect) {
        let p = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 4), xRadius: 28, yRadius: 28)
        NSColor(white: 0.06, alpha: 0.96).setFill(); p.fill()
        NSColor(red: 1, green: 0.54, blue: 0.16, alpha: 1).setStroke(); p.lineWidth = 6; p.stroke()
        func line(_ s: String, _ size: CGFloat, _ y: CGFloat, _ c: NSColor, _ w: NSFont.Weight) {
            let a: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedSystemFont(ofSize: size, weight: w), .foregroundColor: c]
            let t = NSAttributedString(string: s, attributes: a)
            t.draw(at: NSPoint(x: (bounds.width - t.size().width) / 2, y: y))
        }
        line("PRESS", 26, 222, NSColor(white: 0.6, alpha: 1), .semibold)
        line(key, 110, 80, NSColor(red: 1, green: 0.54, blue: 0.16, alpha: 1), .bold)
        line(note, 22, 34, NSColor(white: 0.75, alpha: 1), .regular)
    }
    override func mouseDown(with e: NSEvent) { done("click") }
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
}
panel.contentView = Box()
panel.orderFrontRegardless()

// any key that reaches macOS
let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue) | (1 << 14) // 14: system-defined (media keys)
if let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                               eventsOfInterest: CGEventMask(mask), callback: { _, type, ev, _ in
    if type.rawValue == 14 {
        let d = NSEvent(cgEvent: ev)?.data1 ?? 0
        guard onlyKeys == nil, (d & 0xff00) >> 8 == 0x0a else { return Unmanaged.passUnretained(ev) }   // key down only
        done(String(format: "media key 0x%02x", (d & 0xffff0000) >> 16))
    }
    let code = Int(ev.getIntegerValueField(.keyboardEventKeycode))
    if let k = onlyKeys, !k.split(separator: ",").contains(Substring(String(code))) { return Unmanaged.passUnretained(ev) }
    if type == .keyDown || type == .flagsChanged {
        done("key code \(ev.getIntegerValueField(.keyboardEventKeycode))" + (type == .flagsChanged ? " (modifier)" : ""))
    }
    return Unmanaged.passUnretained(ev)
}, userInfo: nil) {
    CFRunLoopAddSource(CFRunLoopGetMain(), CFMachPortCreateRunLoopSource(nil, tap, 0), .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
} else {
    FileHandle.standardError.write("ask: no key tap (Input Monitoring), only clicks and the probe\n".data(using: .utf8)!)
}

// a new "heard" line in the probe's output
var seen = watch.flatMap { try? String(contentsOfFile: $0, encoding: .utf8) }?.components(separatedBy: "\n").filter { $0.contains(match) }.count ?? 0
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    if Date().timeIntervalSince(start) > timeout { done("timeout") }
    guard let w = watch, let s = try? String(contentsOfFile: w, encoding: .utf8) else { return }
    let lines = s.components(separatedBy: "\n").filter { $0.contains(match) }
    if lines.count > seen { done("seen " + (lines.last ?? "").trimmingCharacters(in: .whitespaces)) }
    seen = lines.count
}
app.run()
