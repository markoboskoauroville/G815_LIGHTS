// MacroViews.swift — the macro editor (v15, Marko 8.10.2026: "Let's build macro editor and macro recorder for this
// keyboard now"). MR in the drawing (or MACROS in the KEYS row) shows it in place of the colours: the macros on the
// left, the key chosen on the drawing in the middle (put a macro on it in this bank, or take it away), the chosen
// macro's steps on the right: RECORD, PLAY, a wait or a text to add, every step to change, move or delete.

import SwiftUI

struct MacroPanel: View {
    @ObservedObject var store: Store
    @ObservedObject var macros: Macros
    /// the one key chosen on the drawing, if any
    let chosen: String?
    @State private var pick: String?

    private func label(_ t: String) -> some View { Text(t).font(mono(10, .semibold)).tracking(1.6).foregroundColor(.dimSand) }
    private let red = Color(hex: "FF3B30")

    private var picked: Macro? { store.s.macros.first { $0.uid == pick } }

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            list.frame(width: 250, alignment: .leading)
            key.frame(width: 230, alignment: .leading)
            steps
        }
        .onAppear { if pick == nil { pick = chosen.flatMap { macros.macro(for: $0)?.uid } ?? store.s.macros.first?.uid } }
        .onChange(of: chosen) { _, id in if let id, let m = macros.macro(for: id) { pick = m.uid } }
    }

    // ------------------------------------------------------------ the macros
    private var list: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { label("MACROS"); Spacer(); Word(text: "+", state: .sand, size: 16) { pick = macros.add() }.help("a new, empty macro") }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(store.s.macros) { m in
                        Text(m.name.isEmpty ? "(no name)" : m.name).font(mono(12)).foregroundColor(pick == m.uid ? .amber : .sand)
                            .lineLimit(1).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                            .onTapGesture { pick = m.uid }
                    }
                }
            }
            .frame(height: 170)
            if !macros.trusted {
                Text("ACCESSIBILITY IS OFF: no macro can play, and only G1–G5 can start one. Switch G815 Lights on.")
                    .font(mono(11, .regular)).foregroundColor(red).fixedSize(horizontal: false, vertical: true)
                Word(text: "OPEN SETTINGS", state: .amber, size: 11) { macros.askPermission() }
            }
            Text(macros.rec == .waitTrigger ? "MR: press the key that will play it" : "On the keyboard: MR, the key, type, MR.")
                .font(mono(11, .regular)).foregroundColor(.dimSand).fixedSize(horizontal: false, vertical: true)
            if !macros.last.isEmpty {
                Text(macros.last).font(mono(11, .regular)).foregroundColor(.sand).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // ------------------------------------------------------------ the key chosen on the drawing
    private var key: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("KEY IN M\(store.s.active)")
            if let id = chosen {
                Text(macros.name(id)).font(mono(15)).foregroundColor(.sand)
                if !macros.canTrigger(id) {
                    Text("cannot play a macro (CTRL SHIFT ALT ⌘, the media keys and ☼ stay what they are)")
                        .font(mono(11, .regular)).foregroundColor(.dimSand).fixedSize(horizontal: false, vertical: true)
                } else {
                    let now = macros.macro(for: id)
                    Text(now.map { "plays " + $0.name } ?? "no macro").font(mono(12, .regular)).foregroundColor(now == nil ? .dimSand : .on)
                    if let p = picked, now?.uid != p.uid {
                        Word(text: "PUT \(p.name.isEmpty ? "IT" : p.name) HERE", state: .amber, size: 12) { macros.assign(p.uid, to: id) }
                    }
                    if now != nil { Word(text: "TAKE IT AWAY", state: .off, size: 12) { macros.assign(nil, to: id) } }
                    if !KeyCodes.gKeys.contains(id) {
                        Text("this key no longer types in M\(store.s.active) while it has a macro")
                            .font(mono(10, .regular)).foregroundColor(.dimSand).fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Text("click one key on the drawing").font(mono(12, .regular)).foregroundColor(.dimSand)
            }
        }
    }

    // ------------------------------------------------------------ the chosen macro's steps
    @ViewBuilder private var steps: some View {
        if let m = picked {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    label("NAME")
                    TextField("no name", text: Binding(get: { m.name }, set: { v in macros.update(m.uid) { $0.name = v } }))
                        .textFieldStyle(.plain).font(mono(13, .regular)).foregroundColor(.sand).frame(width: 200).padding(4)
                        .background(RoundedRectangle(cornerRadius: 4).stroke(Color.dead))
                    let recording = macros.rec == .recording(nil) && macros.into == m.uid
                    Word(text: recording ? "STOP" : "RECORD", state: recording ? red : (macros.rec == .idle ? .amber : .dead)) {
                        if recording { macros.stop() } else { macros.recordInto(m.uid) }
                    }.help("records what you type (it replaces the steps); STOP, or MR, ends it")
                    Toggle(isOn: $macros.keepDelays) { Text("DELAYS").font(mono(11, .regular)).foregroundColor(.sand) }.toggleStyle(.checkbox)
                        .help("keep the time between keys as recorded")
                    Word(text: "PLAY", state: .on) { macros.run(m) }.help("plays it now, into the app in front")
                    Spacer()
                    Word(text: "DELETE", state: red) { macros.delete(m.uid); pick = store.s.macros.first?.uid }
                }
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(m.steps.enumerated()), id: \.element.uid) { j, s in row(m, j, s) }
                    }
                }
                .frame(height: 190)
                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.dead.opacity(0.6)))
                HStack(spacing: 6) {
                    if let id = chosen, let code = KeyCodes.code(forKey: id) {
                        Word(text: "+ KEY \(macros.name(id))", state: .sand, size: 12) {
                            macros.update(m.uid) { $0.steps += [.key(code, true), .key(code, false)] }
                        }.help("a press of the key chosen on the drawing")
                    }
                    Word(text: "+ WAIT", state: .sand, size: 12) { macros.update(m.uid) { $0.steps.append(.wait(100)) } }
                    Word(text: "+ TEXT", state: .sand, size: 12) { macros.update(m.uid) { $0.steps.append(.typed("")) } }
                    Spacer()
                    let keys = m.steps.filter { $0.kind == "key" && $0.down }.count
                    let ms = m.steps.filter { $0.kind == "wait" }.reduce(0) { $0 + $1.ms }
                    Text("\(keys) keys · \(ms) ms").font(mono(11, .regular)).foregroundColor(.dimSand)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                label("STEPS")
                Text("no macro chosen: + makes one, or MR on the keyboard records one").font(mono(12, .regular)).foregroundColor(.dimSand)
            }
        }
    }

    private func change(_ m: Macro, _ s: MacroStep, _ f: @escaping (inout MacroStep) -> Void) {
        macros.update(m.uid) { mm in
            if let i = mm.steps.firstIndex(where: { $0.uid == s.uid }) { f(&mm.steps[i]) }
        }
    }

    private func move(_ m: Macro, _ s: MacroStep, _ by: Int) {
        macros.update(m.uid) { mm in
            guard let i = mm.steps.firstIndex(where: { $0.uid == s.uid }), mm.steps.indices.contains(i + by) else { return }
            mm.steps.swapAt(i, i + by)
        }
    }

    private func row(_ m: Macro, _ j: Int, _ s: MacroStep) -> some View {
        HStack(spacing: 8) {
            Text("\(j + 1)").font(mono(10, .regular)).foregroundColor(.dimSand).frame(width: 34, alignment: .trailing)
            switch s.kind {
            case "wait":
                NumField(label: "WAIT ms", value: Binding(get: { s.ms }, set: { v in change(m, s) { $0.ms = max(0, min(60_000, v)) } }),
                         range: 0...60_000) {}
            case "text":
                Text("TEXT").font(mono(10, .regular)).foregroundColor(.dimSand)
                TextField("what it types", text: Binding(get: { s.text }, set: { v in change(m, s) { $0.text = v } }))
                    .textFieldStyle(.plain).font(mono(12, .regular)).foregroundColor(.sand).frame(width: 260).padding(3)
                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.dead))
            default:
                Text((s.down ? "↓ " : "↑ ") + macros.codeName(s.code)).font(mono(12, .regular)).foregroundColor(s.down ? .sand : .dimSand)
            }
            Spacer(minLength: 0)
            Word(text: "↑", state: .off, size: 11) { move(m, s, -1) }
            Word(text: "↓", state: .off, size: 11) { move(m, s, 1) }
            Word(text: "×", state: .off, size: 12) { macros.update(m.uid) { $0.steps.removeAll { $0.uid == s.uid } } }
        }
        .padding(.horizontal, 4)
    }
}
