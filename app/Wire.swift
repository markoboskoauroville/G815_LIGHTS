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

    override func main() {
        while true {
            lock.lock()
            while jobs.isEmpty { lock.wait() }
            let job = jobs.removeFirst()
            lock.unlock()
            do {
                if kb == nil { kb = try G815() }
                try job(kb!)
            } catch {
                kb = nil
                onError?("\(error)")
            }
        }
    }
}
