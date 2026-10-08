// Wire.swift — the one thread that owns the keyboard.
//
// IOKit delivers the G815's answers on the run loop of the thread that opened it, and G815.call() waits by
// spinning that same run loop. So every job runs on this one thread, in order, one at a time — the lesson
// of the Hammerspoon version, where two lines written close together lost one and every answer after it
// went to the wrong caller (LESSONS.md). A job that fails drops the device; the next job opens it again,
// which is how an unplugged keyboard comes back.

import Foundation

final class Wire: Thread {
    private var jobs: [(G815) throws -> Void] = []
    private let lock = NSCondition()
    private var kb: G815?
    var onError: ((String) -> Void)?
    /// the keyboard opened (first time, or back after a failure: a replug, a reset at boot)
    var onOpen: (() -> Void)?
    /// the keyboard spoke on its own; called on this thread
    var onUnasked: (([UInt8]) -> Void)?

    override init() {
        super.init()
        name = "g815.wire"
        start()
    }

    /// Run `job` on the wire thread with the open keyboard. Errors are reported, never thrown at the UI.
    func run(_ job: @escaping (G815) throws -> Void) {
        lock.lock(); jobs.append(job); lock.signal(); lock.unlock()
    }

    var queued: Int { lock.lock(); defer { lock.unlock() }; return jobs.count }

    /// nothing waiting and nothing running: the updater restarts the app only then, never inside a bank write
    private var running = false
    var idle: Bool { lock.lock(); defer { lock.unlock() }; return jobs.isEmpty && !running }

    /// RECHECK (Marko, 6.10.2026): the next job closes the keyboard and opens it again from nothing, as at a replug
    private var fresh = false
    /// T2 (8.10.2026): while Accessibility was switched on, writes failed (0xe00002e2) and the keyboard was reopened
    /// 422 times in 6 s. After a failure the next open waits until a second has passed.
    private var failedAt = Date.distantPast
    func reopen() { lock.lock(); fresh = true; lock.unlock() }

    override func main() {
        while true {
            lock.lock()
            // with the keyboard open, look at what it said every 20 ms (a G key must play at once, not at the next poll)
            while jobs.isEmpty {
                if let k = kb {
                    lock.unlock(); k.drain(); lock.lock()
                    if jobs.isEmpty { _ = lock.wait(until: Date().addingTimeInterval(0.02)) }
                } else {
                    lock.wait()
                }
            }
            let job = jobs.removeFirst()
            if fresh { fresh = false; kb = nil }
            running = true
            lock.unlock()
            defer { lock.lock(); running = false; lock.unlock() }
            do {
                if kb == nil {
                    let wait = 1 - Date().timeIntervalSince(failedAt)
                    if wait > 0 { Thread.sleep(forTimeInterval: wait) }
                    kb = try G815(); kb!.onUnasked = onUnasked; onOpen?()
                }
                try job(kb!)
            } catch {
                kb = nil
                failedAt = Date()
                onError?("\(error)")
            }
        }
    }
}
