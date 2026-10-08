// Update.swift — the app keeps itself up to date (Marko, 8.10.2026: "even if it's possible that this app auto
// updates when a new version is detected"; of the ways offered he chose: rebuild on this Mac).
//
// Not a download: GitHub can only sign ad hoc, and an ad hoc app loses Input Monitoring (LESSONS 6). So the app
// looks in the repo it was built from (build/G815 Lights.app sits in it): two minutes after start, every 6 hours and
// when the window is opened (at most once a minute):
// `git fetch origin main`; if VERSION there is higher than its own, and the repo is on main with nothing changed,
// `git pull --ff-only` and ./build.sh, signed "Mantra Apps" as always. The new build waits until the window is
// closed and the keyboard has no job running, then launchd starts it (kickstart of the login agent). A click on the
// amber note top right restarts at once, and the window comes back. Everything goes into ~/.g815/log.txt.

import AppKit

@MainActor
final class Updater: ObservableObject {
    static let label = "community.auroville.g815lights"
    /// after a restart the new copy shows its window when the old one had it open
    nonisolated static let showFlag = Store.dir.appendingPathComponent("show-after-update")

    /// what the top right says beside the version; empty: nothing new
    @Published var note = ""
    /// the version built and waiting for a restart, 0: none
    @Published var ready = 0

    private let repo: URL?
    private let wireIdle: () -> Bool
    private let windowOpen: () -> Bool
    private var busy = false
    private var failed = 0
    private var lastCheck = Date.distantPast
    private var timers: [Timer] = []

    init(wireIdle: @escaping () -> Bool, windowOpen: @escaping () -> Bool) {
        self.wireIdle = wireIdle; self.windowOpen = windowOpen
        let r = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
        let fm = FileManager.default
        repo = fm.fileExists(atPath: r.appendingPathComponent(".git").path) && fm.fileExists(atPath: r.appendingPathComponent("build.sh").path) ? r : nil
        Store.log(repo.map { "update: watching \($0.path), v\(VERSION)" } ?? "update: not built in a repo, no updates")
    }

    func start() {
        guard repo != nil else { return }
        timers.append(Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in MainActor.assumeIsolated { self?.check() } })
        timers.append(Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.check() } })
        timers.append(Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let me = self, me.ready > 0, !me.windowOpen() else { return }
                me.restart()
            }
        })
    }

    /// the click on the note: restart into a version that is ready, else show GitHub
    func act() { if ready > 0 { restart() } else { NSWorkspace.shared.open(LATEST) } }

    func check() {
        guard let repo, !busy, ready == 0, Date().timeIntervalSince(lastCheck) > 60 else { return }
        busy = true; lastCheck = Date()
        let failed = failed
        DispatchQueue.global().async {
            let (note, ready, fail) = Updater.update(repo, failed: failed)
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    self.busy = false
                    if let note { self.note = note }
                    if ready > 0 { self.ready = ready }
                    if fail > 0 { self.failed = fail }
                }
            }
        }
    }

    /// the work, off the main thread: (note to show or nil, version built, version that did not build)
    nonisolated private static func update(_ repo: URL, failed: Int) -> (String?, Int, Int) {
        guard sh(repo, "git", "fetch", "--quiet", "origin", "main").0 == 0 else { Store.log("update: git fetch failed"); return (nil, 0, 0) }
        let src = sh(repo, "git", "show", "origin/main:app/Views.swift").1
        guard let line = src.split(separator: "\n").first(where: { $0.hasPrefix("let VERSION = ") }),
              let v = Int(line.dropFirst("let VERSION = ".count).trimmingCharacters(in: .whitespaces)) else {
            Store.log("update: no VERSION in origin/main"); return (nil, 0, 0)
        }
        guard v > VERSION else { return (nil, 0, 0) }
        if v == failed { return (nil, 0, 0) }
        let branch = sh(repo, "git", "rev-parse", "--abbrev-ref", "HEAD").1.trimmingCharacters(in: .whitespacesAndNewlines)
        let changed = sh(repo, "git", "status", "--porcelain").1.trimmingCharacters(in: .whitespacesAndNewlines)
        guard branch == "main", changed.isEmpty else {
            Store.log("update: v\(v) on GitHub, but the repo is on \(branch)\(changed.isEmpty ? "" : " with changes"); not updating")
            return ("v\(v) ON GITHUB · REPO NOT ON A CLEAN MAIN", 0, 0)
        }
        Store.log("update: v\(VERSION) → v\(v): pull and build")
        let pull = sh(repo, "git", "pull", "--ff-only", "--quiet", "origin", "main")
        guard pull.0 == 0 else { Store.log("update: git pull failed: \(pull.1)"); return ("v\(v) DID NOT PULL · SEE LOG", 0, v) }
        let build = sh(repo, "/bin/sh", "./build.sh")
        guard build.0 == 0 else { Store.log("update: build failed: \(build.1)"); return ("v\(v) DID NOT BUILD · SEE LOG", 0, v) }
        Store.log("update: v\(v) built, restarting when the window is closed")
        return ("v\(v) READY · RESTART", v, 0)
    }

    /// run a command in the repo; (exit status, stdout and stderr). launchd's PATH is short, so it is given here.
    nonisolated private static func sh(_ dir: URL, _ cmd: String, _ args: String...) -> (Int32, String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: cmd.hasPrefix("/") ? cmd : "/usr/bin/" + cmd)
        p.arguments = args
        p.currentDirectoryURL = dir
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
        p.environment = env
        let out = Pipe(); p.standardOutput = out; p.standardError = out
        do { try p.run() } catch { return (-1, "\(error)") }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    /// into the new build: never inside a keyboard job. As the login agent, launchd kills this copy and starts the
    /// new one; opened by hand, the new one is opened (in the background) two seconds after this one quits.
    func restart() {
        guard ready > 0 else { return }
        guard wireIdle() else {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in MainActor.assumeIsolated { self?.restart() } }
            return
        }
        if windowOpen() { try? Data().write(to: Updater.showFlag) }
        Store.log("update: restarting into v\(ready)")
        let p = Process()
        if ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] == Updater.label {
            p.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            p.arguments = ["kickstart", "-k", "gui/\(getuid())/\(Updater.label)"]
            try? p.run()
        } else {
            p.executableURL = URL(fileURLWithPath: "/bin/sh")
            p.arguments = ["-c", "sleep 2; open -g \"$0\" --args --background", Bundle.main.bundlePath]
            try? p.run()
            NSApp.terminate(nil)
        }
    }

    /// true once after a restart from an open window
    nonisolated static func takeShowFlag() -> Bool {
        (try? FileManager.default.removeItem(at: showFlag)) != nil
    }
}
