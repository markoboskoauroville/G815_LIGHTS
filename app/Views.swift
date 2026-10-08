// Views.swift — the window. The CAMERA language (MANTRA_MANIFEST modules/language-camera.md): words, not
// boxes; green = on, grey = off, amber = armed/chosen. The drawing is the keyboard as it is in the room
// (Marko, 2.10.2026: "my keyboard is black, so keys should be black with lights on ... memory buttons are
// yellow"): black caps on a black body, each legend in its key's own colour, clear and with no glow ("you
// don't need to really to use glow. Should be clear", v2); M1 M2 M3 MR yellow, the
// active bank bright. The key's colour is content, so a chosen key is shown by an amber ring only.

import SwiftUI

let VERSION = 18
/// v14: the app updates itself from GitHub (Update.swift); the version number still opens the page.
/// where the version number top right takes him (v13, 8.10.2026: "clickable so it takes me to GitHub to download the
/// latest version"): the newest release, which .github/workflows/build.yml publishes from every push to main
let LATEST = URL(string: "https://github.com/markoboskoauroville/G815_LIGHTS/releases/latest")!

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
/// how a click or drag on the board chooses keys: PAINT (drag across keys), LASSO (a box), SINGLE (one key only)
enum SelectMode { case paint, lasso, single }

struct Board: View {
    @ObservedObject var store: Store
    @Binding var sel: Set<String>
    /// LASSO (Marko, 6.10.2026: "add a selection method with the lasso"), then v11: "I mean by lasso is a square
    /// selection ... it needs to draw squares only". A drag draws a rectangle from where it started to where the pointer
    /// is; every key whose centre is inside is chosen. Shift adds to the choice, Option takes away, plain replaces it.
    /// SINGLE (Marko, 8.10.2026: "I can select only one key at the time for modifications"): the key under the
    /// pointer is the only one chosen; a drag moves the choice from key to key.
    var mode = SelectMode.paint
    /// v15: MR in the drawing opens the macros; its colour says what the recorder is doing
    var mrColor = Color.bankYellow.opacity(0.32)
    var onMR: () -> Void = {}
    var onChosen: () -> Void
    @State private var adding = true
    @State private var lastId: String?
    @State private var boxFrom: CGPoint?
    @State private var boxTo: CGPoint = .zero

    /// the selection box, from the corner the drag started at to the pointer, whichever way it was dragged
    private var box: CGRect? {
        guard let a = boxFrom else { return nil }
        return CGRect(x: min(a.x, boxTo.x), y: min(a.y, boxTo.y), width: abs(boxTo.x - a.x), height: abs(boxTo.y - a.y))
    }

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
                if let r = box {
                    Path { p in p.addRect(r) }
                        .fill(Color.amber.opacity(0.12))
                    Path { p in p.addRect(r) }
                        .stroke(Color.amber, style: StrokeStyle(lineWidth: 1.5, lineJoin: .miter, dash: [6, 4]))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { g in
                    if mode == .lasso {
                        if boxFrom == nil { boxFrom = g.startLocation }
                        boxTo = g.location
                        return
                    }
                    let p = CGPoint(x: (g.location.x - pad) / u, y: (g.location.y - pad) / u)
                    if g.translation == .zero, let b = store.layout.banks.first(where: { p.x >= $0.x && p.x < $0.x + 1 && p.y >= $0.y && p.y < $0.y + 1 }) {
                        if b.i > 0 { store.choose(b.i) } else { onMR() }
                        return
                    }
                    guard let k = store.layout.keys.first(where: { p.x >= $0.x && p.x < $0.x + $0.w && p.y >= $0.y && p.y < $0.y + $0.h }) else { return }
                    if mode == .single {
                        if sel != [k.id] { sel = [k.id] }
                        return
                    }
                    if g.translation == .zero || lastId == nil { adding = !sel.contains(k.id) }
                    if k.id != lastId {
                        if adding { sel.insert(k.id) } else { sel.remove(k.id) }
                        lastId = k.id
                    }
                }
                .onEnded { _ in
                    if mode == .lasso {
                        defer { boxFrom = nil }
                        guard let r = box, r.width > 2 || r.height > 2 else { return }
                        let inside = Set(store.layout.keys.filter { k in
                            r.contains(CGPoint(x: pad + (k.x + k.w / 2) * u, y: pad + (k.y + k.h / 2) * u))
                        }.map(\.id))
                        let mods = NSEvent.modifierFlags
                        if mods.contains(.option) { sel.subtract(inside) }
                        else if mods.contains(.shift) { sel.formUnion(inside) }
                        else { sel = inside }
                        onChosen(); return
                    }
                    lastId = nil; onChosen()
                })
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
            // a key that plays a macro in this bank: a small sand dot in its corner
            if store.bank.macros[k.id] != nil {
                Circle().fill(Color.sand).frame(width: 5, height: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(5)
            }
        }
        .frame(width: k.w * u - 4, height: k.h * u - 4)
    }

    private func bankCap(_ b: BankCap, _ u: Double) -> some View {
        let active = b.i == store.s.active
        let col = b.i == 0 ? mrColor : Color.bankYellow.opacity(active ? 1 : 0.32)
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

/// Small squares, one per brightness level the keys really show (MEASURED 8.10.2026): the keyboard's OFF 12 25 50 100
/// (Store.brightSteps), a key's own OFF 18 30 45 60 80 100 (Store.keySteps). The one in force is outlined; a click picks it (Marko, 8.10.2026: "make small squares swatches
/// so user can jump directly to brightness level").
struct LevelSquares: View {
    let value: Int
    var steps = Store.brightSteps
    let pick: (Int) -> Void
    var body: some View {
        let level = Store.level(value, steps)
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { i in
                let v = steps[i]
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.amber.opacity(i == 0 ? 0.06 : 0.2 + 0.8 * Double(v) / 100))
                        .frame(width: 26, height: 26)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(i == level ? Color.sand : Color.dead, lineWidth: i == level ? 2 : 1))
                    Text(i == 0 ? "OFF" : "\(v)").font(mono(10, .regular)).foregroundColor(i == level ? .sand : .dimSand)
                }
                .contentShape(Rectangle())
                .onTapGesture { pick(v) }
                .help(i == 0 ? "off" : "brightness \(v)%")
            }
        }
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
    @ObservedObject var updater: Updater
    @ObservedObject var macros: Macros
    /// v15: MR opens the macros in place of the colours
    @State private var macroView = false
    @State private var modeBefore = SelectMode.paint
    @State private var sel = Set<String>()
    @State private var hsv = HSV(h: 0, s: 0, v: 1)
    @State private var keyB = 100
    @State private var keyBd = 100.0
    @State private var renaming: String?
    @State private var renameText = ""
    @State private var renameAuto = false
    @State private var dropOn: String?
    @State private var dragging: String?
    @State private var dragShift = CGSize.zero
    @State private var chipFrames: [String: CGRect] = [:]
    @State private var hexText = "FFFFFF"
    @State private var r = 255
    @State private var g = 255
    @State private var b = 255
    @State private var mode = SelectMode.paint

    private func label(_ t: String) -> some View { Text(t).font(mono(10, .semibold)).tracking(1.6).foregroundColor(.dimSand) }

    /// the rename pop-up: an empty name leaves only the swatch; AUTOMATIC NAME says the colour in words
    private func renamer(_ p: Preset) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            label("PRESET NAME")
            TextField("no name: only the swatch", text: $renameText).textFieldStyle(.plain).font(mono(13, .regular))
                .foregroundColor(.sand).frame(width: 260).padding(5)
                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.dead))
                .onSubmit { store.renamePreset(p.uid, name: renameText, auto: renameAuto); renaming = nil }
            // ticked: the automatic name is added to his name in the same box, still his to edit; unticked: taken away
            Toggle(isOn: Binding(get: { renameAuto }, set: { on in
                let a = Preset.autoName(c: p.c, b: p.b)
                var t = renameText.trimmingCharacters(in: .whitespaces)
                if on, !t.uppercased().hasSuffix(a) { t = t.isEmpty ? a : t + " " + a }
                if !on, t.uppercased().hasSuffix(a) { t = String(t.dropLast(a.count)).trimmingCharacters(in: .whitespaces) }
                renameText = t; renameAuto = on
            })) {
                Text("AUTOMATIC NAME  " + Preset.autoName(c: p.c, b: p.b)).font(mono(11, .regular)).foregroundColor(.sand)
            }.toggleStyle(.checkbox)
            HStack {
                Word(text: "DELETE", state: Color(hex: "FF3B30")) { store.deletePreset(p.uid); renaming = nil }
                Spacer()
                Word(text: "OK", state: .on) { store.renamePreset(p.uid, name: renameText, auto: renameAuto); renaming = nil }
            }
        }
        .padding(14).background(Color.ground).preferredColorScheme(.dark)
    }

    private func syncFields() { let c = hsv.rgb; r = c.0; g = c.1; b = c.2; hexText = hsv.hex.uppercased() }

    private func push(_ final: Bool = true) {
        syncFields()
        store.set(sel, c: hsv.hex, b: keyB)
    }

    /// MACROS on: one key at a time (the key a macro goes on); off: the selection mode he had
    private func toggleMacros() {
        macroView.toggle()
        if macroView {
            modeBefore = mode; mode = .single
            if sel.count > 1 { sel = [] }
            macros.askPermission()
        } else {
            mode = modeBefore
        }
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
                Word(text: store.checking ? "CHECKING…" : "RECHECK KEYBOARD", state: .amber) { store.recheck() }
                if !updater.note.isEmpty { Word(text: updater.note, state: .amber, size: 11) { updater.act() } }
                Link(destination: LATEST) { Text("v\(VERSION)").font(mono(11, .regular)).foregroundColor(.dimSand) }
                    .buttonStyle(.plain).focusable(false).help("download the latest version from GitHub")
            }

            HStack(spacing: 4) {
                label("BANK").padding(.trailing, 6)
                ForEach(1...3, id: \.self) { i in Word(text: "M\(i)", state: store.s.active == i ? .on : .off, size: 15) { store.choose(i) } }
                Text("in the keyboard: " + (store.bankNote[store.s.active] ?? "as it was"))
                    .font(mono(11, .regular)).foregroundColor(.dimSand).padding(.leading, 10)
                if let b = store.cameFrom {
                    Word(text: "BACK TO M\(b)", state: .amber) { store.backToCameFrom() }.padding(.leading, 10)
                }
                Spacer()
                Toggle(isOn: Binding(get: { store.s.locked }, set: { store.setLocked($0) })) {
                    Text("LOCK M\(store.s.active): M keys on the keyboard do nothing").font(mono(11, .regular)).foregroundColor(.sand)
                }.toggleStyle(.checkbox)
            }
            Board(store: store, sel: $sel, mode: mode,
                  mrColor: macros.rec != .idle ? Color(hex: "FF3B30") : Color.bankYellow.opacity(macroView ? 1 : 0.32),
                  onMR: toggleMacros, onChosen: pickFromSelection)
                .aspectRatio(store.layout.w / store.layout.h, contentMode: .fit)
            HStack(spacing: 4) {
                label("KEYS").padding(.trailing, 6)
                // SINGLE: ALL and SAME COLOUR would choose many keys, so they are dead while it is on
                Word(text: "ALL", state: mode == .single ? .dead : .off) {
                    guard mode != .single else { return }
                    sel = Set(store.layout.keys.map(\.id)); pickFromSelection()
                }
                Word(text: "NONE") { sel = [] }
                Word(text: "LASSO", state: mode == .lasso ? .on : .off) { mode = mode == .lasso ? .paint : .lasso }
                Word(text: "SINGLE", state: mode == .single ? .on : .off) {
                    mode = mode == .single ? .paint : .single
                    if mode == .single, sel.count > 1 { sel = [] }
                }
                Word(text: "MACROS", state: macroView ? .on : .off) { toggleMacros() }
                Word(text: "SAME COLOUR", state: mode == .single ? .dead : .off) {
                    guard mode != .single, let f = sel.first else { return }
                    let k = store.key(f)
                    for c in store.layout.keys where store.key(c.id) == k { sel.insert(c.id) }
                }
                Text(mode == .single ? (sel.isEmpty ? "click one key" : "\(store.layout.keys.first { sel.contains($0.id) }?.l ?? "") chosen · one key at a time")
                     : mode == .lasso ? (sel.isEmpty ? "drag a box around keys · shift adds · option takes away" : "\(sel.count) chosen · shift adds · option takes away")
                     : (sel.isEmpty ? "click or drag across keys" : "\(sel.count) chosen")).font(mono(11, .regular)).foregroundColor(.dimSand).padding(.leading, 8)
            }
            if macroView {
                MacroPanel(store: store, macros: macros, chosen: sel.count == 1 ? sel.first : nil)
            } else {
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
                    // v18: the same five squares as the keyboard's (Marko, 8.10.2026: "I want to control for each individual
                    // key brightness with the same swatches ... replacing the key brightness slider")
                    LevelSquares(value: keyB, steps: Store.keySteps) { keyB = $0; keyBd = Double($0); push() }
                }
                VStack(alignment: .leading, spacing: 10) {
                    label("PRESETS")
                    // Marko, 3.10.2026: drag to put them in any order; double click (name or swatch) to rename;
                    // the "+" at the end of the row keeps the colour now chosen
                    WrapLayout(spacing: 14) {
                        ForEach(store.s.presets) { p in
                            PresetChip(p: p, dropping: dropOn == p.uid)
                                .onTapGesture(count: 2) { renaming = p.uid; renameText = p.shown; renameAuto = p.auto }
                                .onTapGesture { hsv = HSV(hex: p.c); keyB = p.b; keyBd = Double(p.b); push() }
                                .offset(dragging == p.uid ? dragShift : .zero)
                                .opacity(dragging == p.uid ? 0.75 : 1)
                                .zIndex(dragging == p.uid ? 1 : 0)
                                .background(GeometryReader { g in
                                    Color.clear.preference(key: ChipFrames.self, value: [p.uid: g.frame(in: .named("presets"))])
                                })
                                .gesture(DragGesture(minimumDistance: 5, coordinateSpace: .named("presets"))
                                    .onChanged { g in
                                        dragging = p.uid; dragShift = g.translation
                                        dropOn = chipFrames.first { $0.key != p.uid && $0.value.contains(g.location) }?.key
                                    }
                                    .onEnded { _ in
                                        if let t = dropOn { store.movePreset(p.uid, before: t) }
                                        dragging = nil; dropOn = nil; dragShift = .zero
                                    })
                                .popover(isPresented: Binding(get: { renaming == p.uid }, set: { if !$0 { renaming = nil } })) {
                                    renamer(p)
                                }
                        }
                        Word(text: "+", state: .sand, size: 16) { store.addPreset(c: hsv.hex, b: keyB) }
                            .help("keep the colour now chosen as a preset")
                    }
                    .coordinateSpace(name: "presets")
                    .onPreferenceChange(ChipFrames.self) { chipFrames = $0 }
                    label("KEYBOARD BRIGHTNESS").padding(.top, 10)
                    // v18: one small square per level the keys really show; a click jumps to it (LevelSquares)
                    LevelSquares(value: store.brightness) { store.setBrightness($0) }
                }
            }
            }
        }
        // the RECHECK report floats over the board, so the window's layout never grows (inline, it blanked the window)
        .overlay(alignment: .topTrailing) {
            if !store.report.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RECHECK").font(mono(11, .semibold)).tracking(1.6).foregroundColor(.dimSand)
                    VStack(alignment: .leading, spacing: 6) {
                        Group {
                            ForEach(store.report) { l in
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Circle().fill(l.ok == nil ? Color.off : (l.ok! ? Color.on : Color(hex: "FF3B30"))).frame(width: 7, height: 7)
                                    Text(l.text).font(mono(12, .regular)).foregroundColor(.sand).fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                    HStack { Spacer(); Word(text: "CLOSE", state: .sand) { store.report = [] } }
                }
                .padding(14).frame(width: 620)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.ground))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.amber.opacity(0.6)))
                .shadow(color: .black.opacity(0.6), radius: 20)
                .padding(.top, 34)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .background(Color.ground)
        .preferredColorScheme(.dark)
        .onChange(of: store.s.active) { _, _ in pickFromSelection() }
    }
}

struct ChipFrames: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) { value.merge(nextValue()) { $1 } }
}

/// one preset: its swatch, and its name when it has one; amber edge while another is dragged onto it
struct PresetChip: View {
    let p: Preset
    var dropping = false
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: KeyLight(c: p.c, b: p.b).sentHex)).frame(width: 14, height: 14)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.15)))
            if !p.shown.isEmpty {
                Text(p.shown + (!p.auto && p.b < 100 ? " \(p.b)%" : "")).font(mono(12)).foregroundColor(.off)
            }
        }
        .padding(.horizontal, 4).padding(.vertical, 3)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(dropping ? Color.amber : .clear, lineWidth: 1.5))
        .contentShape(Rectangle())
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
