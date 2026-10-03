// Views.swift — the window. The CAMERA language (MANTRA_MANIFEST modules/language-camera.md): words, not
// boxes; green = on, grey = off, amber = armed/chosen. The drawing is the keyboard as it is in the room
// (Marko, 2.10.2026: "my keyboard is black, so keys should be black with lights on ... memory buttons are
// yellow"): black caps on a black body, each legend in its key's own colour, clear and with no glow ("you
// don't need to really to use glow. Should be clear", v2); M1 M2 M3 MR yellow, the
// active bank bright. The key's colour is content, so a chosen key is shown by an amber ring only.

import SwiftUI

let VERSION = 5

extension Color {
    init(hex: String) {
        let v = UInt32(hex, radix: 16) ?? 0
        self.init(red: Double(v >> 16 & 0xFF) / 255, green: Double(v >> 8 & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
    static let ground = Color(hex: "0B0D10"), sand = Color(hex: "F2DDB4"), dimSand = Color(hex: "F2DDB4").opacity(0.45)
    static let on = Color(hex: "33D17A"), off = Color(hex: "7A8087"), amber = Color(hex: "E8A33D"), dead = Color(hex: "33383E")
    static let body = Color(hex: "0E0F11"), cap = Color(hex: "16171A"), bankYellow = Color(hex: "F2B630")
}

func mono(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font { .system(size: size, weight: weight, design: .monospaced) }

// ---------------------------------------------------------------- colour maths
struct HSV: Equatable {
    var h: Double, s: Double, v: Double
    var rgb: (Int, Int, Int) {
        func f(_ n: Double) -> Int {
            let k = (n + h / 60).truncatingRemainder(dividingBy: 6)
            return Int(((v - v * s * max(0, min(k, 4 - k, 1))) * 255).rounded())
        }
        return (f(5), f(3), f(1))
    }
    var hex: String { let c = rgb; return String(format: "%02x%02x%02x", c.0, c.1, c.2) }
    init(h: Double, s: Double, v: Double) { self.h = h; self.s = s; self.v = v }
    init(hex: String) {
        let x = UInt32(hex, radix: 16) ?? 0
        let r = Double(x >> 16 & 0xFF) / 255, g = Double(x >> 8 & 0xFF) / 255, b = Double(x & 0xFF) / 255
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        var hh = 0.0
        if d > 0 { hh = mx == r ? ((g - b) / d).truncatingRemainder(dividingBy: 6) : mx == g ? (b - r) / d + 2 : (r - g) / d + 4 }
        h = (hh * 60 + 360).truncatingRemainder(dividingBy: 360); s = mx > 0 ? d / mx : 0; v = mx
    }
}

// ---------------------------------------------------------------- the keyboard
struct Board: View {
    @ObservedObject var store: Store
    @Binding var sel: Set<String>
    var onChosen: () -> Void
    @State private var adding = true
    @State private var lastId: String?

    var body: some View {
        GeometryReader { geo in
            let pad = 16.0
            let u = min((geo.size.width - 2 * pad) / store.layout.w, (geo.size.height - 2 * pad) / store.layout.h)
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14).fill(Color.body)
                    .frame(width: store.layout.w * u + 2 * pad, height: store.layout.h * u + 2 * pad)
                ForEach(store.layout.keys) { k in
                    cap(k, u).offset(x: pad + k.x * u + 2, y: pad + k.y * u + 2)
                }
                ForEach(store.layout.banks, id: \.l) { b in
                    bankCap(b, u).offset(x: pad + b.x * u + 2, y: pad + b.y * u + 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { g in
                    let p = CGPoint(x: (g.location.x - pad) / u, y: (g.location.y - pad) / u)
                    if g.translation == .zero, let b = store.layout.banks.first(where: { p.x >= $0.x && p.x < $0.x + 1 && p.y >= $0.y && p.y < $0.y + 1 }) {
                        if b.i > 0 { store.choose(b.i) }
                        return
                    }
                    guard let k = store.layout.keys.first(where: { p.x >= $0.x && p.x < $0.x + $0.w && p.y >= $0.y && p.y < $0.y + $0.h }) else { return }
                    if g.translation == .zero || lastId == nil { adding = !sel.contains(k.id) }
                    if k.id != lastId {
                        if adding { sel.insert(k.id) } else { sel.remove(k.id) }
                        lastId = k.id
                    }
                }
                .onEnded { _ in lastId = nil; onChosen() })
        }
    }

    private func cap(_ k: KeyCap, _ u: Double) -> some View {
        let light = store.key(k.id)
        let lit = Color(hex: light.sentHex)
        let dark = light.sent.0 < 12 && light.sent.1 < 12 && light.sent.2 < 12
        let chosen = sel.contains(k.id)
        return ZStack {
            RoundedRectangle(cornerRadius: 5).fill(Color.cap)
            RoundedRectangle(cornerRadius: 5).strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            Text(k.l)
                .font(mono(k.l.count > 3 ? max(7, u * 0.18) : max(9, u * 0.3)))
                .foregroundColor(dark ? Color(hex: "26272A") : lit)
                .lineLimit(1).minimumScaleFactor(0.5).padding(2)
            if chosen { RoundedRectangle(cornerRadius: 5).strokeBorder(Color.amber, lineWidth: 2) }
        }
        .frame(width: k.w * u - 4, height: k.h * u - 4)
    }

    private func bankCap(_ b: BankCap, _ u: Double) -> some View {
        let active = b.i == store.s.active
        let col = b.i == 0 ? Color.dead : Color.bankYellow.opacity(active ? 1 : 0.32)
        return ZStack {
            RoundedRectangle(cornerRadius: 5).fill(Color.cap)
            Text(b.l).font(mono(max(9, u * 0.3))).foregroundColor(col)
        }
        .frame(width: u - 4, height: u - 4)
    }
}

// ---------------------------------------------------------------- the colour square and the hue strip
struct Picker: View {
    @Binding var hsv: HSV
    var commit: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            GeometryReader { g in
                ZStack {
                    Color(hue: hsv.h / 360, saturation: 1, brightness: 1)
                    LinearGradient(colors: [.white, .white.opacity(0)], startPoint: .leading, endPoint: .trailing)
                    LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                    Circle().stroke(hsv.v > 0.5 ? Color.black : Color.white, lineWidth: 2).frame(width: 12, height: 12)
                        .position(x: hsv.s * g.size.width, y: (1 - hsv.v) * g.size.height)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .gesture(DragGesture(minimumDistance: 0).onChanged { d in
                    let x = Double(d.location.x / g.size.width), y = Double(d.location.y / g.size.height)
                    hsv.s = min(1.0, max(0.0, x)); hsv.v = min(1.0, max(0.0, 1.0 - y)); commit(false)
                }.onEnded { _ in commit(true) })
            }
            .frame(width: 260, height: 160)
            GeometryReader { g in
                ZStack(alignment: .top) {
                    LinearGradient(colors: stride(from: 0.0, through: 1.0, by: 1 / 12).map { Color(hue: $0, saturation: 1, brightness: 1) },
                                   startPoint: .top, endPoint: .bottom)
                    Rectangle().stroke(Color.white, lineWidth: 2).frame(height: 4).offset(y: CGFloat(hsv.h / 360) * g.size.height - 2.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .gesture(DragGesture(minimumDistance: 0).onChanged { d in
                    let y = Double(d.location.y / g.size.height)
                    hsv.h = min(359.9, max(0.0, y * 360.0)); commit(false)
                }.onEnded { _ in commit(true) })
            }
            .frame(width: 26, height: 160)
        }
    }
}

struct Word: View {
    let text: String
    var state: Color = .off
    var size: CGFloat = 13
    let act: () -> Void
    var body: some View {
        Button(action: act) { Text(text).font(mono(size)).tracking(0.5).foregroundColor(state) }
            .buttonStyle(.plain).focusable(false).padding(.horizontal, 5).padding(.vertical, 3)
    }
}

struct NumField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var done: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Text(label).font(mono(10, .regular)).foregroundColor(.dimSand)
            TextField("", value: $value, format: .number).textFieldStyle(.plain).font(mono(12, .regular))
                .foregroundColor(.sand).frame(width: 42).padding(3)
                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.dead))
                .onSubmit { value = min(range.upperBound, max(range.lowerBound, value)); done() }
        }
    }
}

// ---------------------------------------------------------------- the window
struct MainView: View {
    @ObservedObject var store: Store
    @State private var sel = Set<String>()
    @State private var hsv = HSV(h: 0, s: 0, v: 1)
    @State private var keyB = 100
    @State private var keyBd = 100.0
    @State private var brightD = 0.0
    @State private var draggingBright = false
    @State private var presetName = ""
    @State private var hexText = "FFFFFF"
    @State private var r = 255
    @State private var g = 255
    @State private var b = 255

    private func label(_ t: String) -> some View { Text(t).font(mono(10, .semibold)).tracking(1.6).foregroundColor(.dimSand) }

    private func syncFields() { let c = hsv.rgb; r = c.0; g = c.1; b = c.2; hexText = hsv.hex.uppercased() }

    private func push(_ final: Bool = true) {
        syncFields()
        store.set(sel, c: hsv.hex, b: keyB)
    }

    private func pickFromSelection() {
        guard let id = sel.first else { return }
        let k = store.key(id)
        hsv = HSV(hex: k.c); keyB = k.b; keyBd = Double(k.b); syncFields()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("G815 LIGHTS").font(mono(14)).tracking(3).foregroundColor(.sand)
                Circle().fill(store.connected ? Color.on : Color(hex: "FF3B30")).frame(width: 8, height: 8)
                Text(store.connected ? "G815 \(store.serial)" : (store.error.isEmpty ? "looking for the keyboard" : store.error))
                    .font(mono(11, .regular)).foregroundColor(.dimSand).lineLimit(1)
                Spacer()
                Text("v\(VERSION)").font(mono(11, .regular)).foregroundColor(.dimSand)
            }
            HStack(spacing: 4) {
                label("BANK").padding(.trailing, 6)
                ForEach(1...3, id: \.self) { i in Word(text: "M\(i)", state: store.s.active == i ? .on : .off, size: 15) { store.choose(i) } }
                Text("in the keyboard: " + (store.bankNote[store.s.active] ?? "as it was"))
                    .font(mono(11, .regular)).foregroundColor(.dimSand).padding(.leading, 10)
            }
            Board(store: store, sel: $sel, onChosen: pickFromSelection)
                .aspectRatio(store.layout.w / store.layout.h, contentMode: .fit)
            HStack(spacing: 4) {
                label("KEYS").padding(.trailing, 6)
                Word(text: "ALL") { sel = Set(store.layout.keys.map(\.id)); pickFromSelection() }
                Word(text: "NONE") { sel = [] }
                Word(text: "SAME COLOUR") {
                    guard let f = sel.first else { return }
                    let k = store.key(f)
                    for c in store.layout.keys where store.key(c.id) == k { sel.insert(c.id) }
                }
                Text(sel.isEmpty ? "click or drag across keys" : "\(sel.count) chosen").font(mono(11, .regular)).foregroundColor(.dimSand).padding(.leading, 8)
            }
            HStack(alignment: .top, spacing: 30) {
                VStack(alignment: .leading, spacing: 10) {
                    label("COLOUR")
                    Picker(hsv: $hsv) { final in push(final) }
                    HStack(spacing: 10) {
                        NumField(label: "R", value: $r, range: 0...255) { hsv = HSV(hex: String(format: "%02x%02x%02x", r, g, b)); push() }
                        NumField(label: "G", value: $g, range: 0...255) { hsv = HSV(hex: String(format: "%02x%02x%02x", r, g, b)); push() }
                        NumField(label: "B", value: $b, range: 0...255) { hsv = HSV(hex: String(format: "%02x%02x%02x", r, g, b)); push() }
                        HStack(spacing: 4) {
                            Text("HEX").font(mono(10, .regular)).foregroundColor(.dimSand)
                            TextField("", text: $hexText).textFieldStyle(.plain).font(mono(12, .regular)).foregroundColor(.sand)
                                .frame(width: 64).padding(3).background(RoundedRectangle(cornerRadius: 4).stroke(Color.dead))
                                .onSubmit {
                                    let h = hexText.replacingOccurrences(of: "#", with: "")
                                    if h.count == 6, UInt32(h, radix: 16) != nil { hsv = HSV(hex: h.lowercased()); push() }
                                }
                        }
                    }
                    HStack(spacing: 6) {
                        ForEach(["000000", "ff0000", "ffff00", "00ff00", "00ffff", "0000ff", "ff00ff", "ffffff"], id: \.self) { c in
                            RoundedRectangle(cornerRadius: 4).fill(Color(hex: c)).frame(width: 24, height: 24)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.12)))
                                .onTapGesture { hsv = HSV(hex: c); push() }
                        }
                    }
                    label("KEY BRIGHTNESS").padding(.top, 6)
                    HStack {
                        Slider(value: $keyBd, in: 0...100, onEditingChanged: { editing in if !editing { keyB = Int(keyBd); push() } })
                            .onChange(of: keyBd) { _, v in keyB = Int(v); push(false) }
                        Text("\(keyB)%").font(mono(15)).foregroundColor(.sand).frame(width: 56, alignment: .trailing)
                    }.frame(width: 300)
                }
                VStack(alignment: .leading, spacing: 10) {
                    label("PRESETS")
                    FlowRow(items: store.s.presets) { p in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 3).fill(Color(hex: KeyLight(c: p.c, b: p.b).sentHex)).frame(width: 14, height: 14)
                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.15)))
                            Text(p.name + (p.b < 100 ? " \(p.b)%" : "")).font(mono(12)).foregroundColor(.off)
                            Text("×").font(mono(12)).foregroundColor(.dead).onTapGesture { store.deletePreset(p) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { hsv = HSV(hex: p.c); keyB = p.b; keyBd = Double(p.b); push() }
                    }
                    HStack(spacing: 8) {
                        TextField("name", text: $presetName).textFieldStyle(.plain).font(mono(12, .regular)).foregroundColor(.sand)
                            .frame(width: 120).padding(4).background(RoundedRectangle(cornerRadius: 4).stroke(Color.dead))
                        Word(text: "+ PRESET") { store.savePreset(name: presetName, c: hsv.hex, b: keyB); presetName = "" }
                    }
                    label("KEYBOARD BRIGHTNESS").padding(.top, 10)
                    HStack {
                        Slider(value: $brightD, in: 0...100, onEditingChanged: { e in
                            draggingBright = e
                            if !e { store.setBrightness(Int(brightD)) }
                        })
                        Text("\(Int(brightD))%").font(mono(15)).foregroundColor(.sand).frame(width: 56, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.ground)
        .preferredColorScheme(.dark)
        .onAppear { brightD = Double(store.brightness) }
        .onChange(of: store.brightness) { _, v in if !draggingBright { brightD = Double(v) } }
        .onChange(of: store.s.active) { _, _ in pickFromSelection() }
    }
}

/// chips that wrap onto the next line
struct FlowRow<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    var body: some View {
        WrapLayout(spacing: 14) { ForEach(items) { content($0) } }
    }
}

struct WrapLayout: SwiftUI.Layout {
    var spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 600
        var x = 0.0, y = 0.0, row = 0.0
        for s in subviews {
            let z = s.sizeThatFits(.unspecified)
            if x + z.width > w && x > 0 { x = 0; y += row + 8; row = 0 }
            x += z.width + spacing; row = max(row, z.height)
        }
        return CGSize(width: w, height: y + row)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, row = 0.0
        for s in subviews {
            let z = s.sizeThatFits(.unspecified)
            if x + z.width > bounds.maxX && x > bounds.minX { x = bounds.minX; y += row + 8; row = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += z.width + spacing; row = max(row, z.height)
        }
    }
}
