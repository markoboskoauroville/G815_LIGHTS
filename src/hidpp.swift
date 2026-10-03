// hidpp.swift — the wire to the G815: HID++ 2.0 over IOKit, no library.
//
// The keyboard answers on usage page 0xFF43, usage 0x0602 (20-byte reports, id 0x11).
// Every request is [0x11, 0xFF, featureIndex, function<<4 | swId, params...]; the reply
// echoes the first four bytes. An error comes back as [0x11, 0xFF, 0xFF, featureIndex, fn|sw, code].
//
// Feature INDEXES differ between firmwares, so they are always looked up through the
// root feature (index 0). OpenRGB hard-codes them (0x10, 0x0D, 0x08, 0x0F); that is one
// reason its colours did not land on this keyboard.

import Foundation
import IOKit.hid

let VID = 0x046D
let PID = 0xC33F
let SW_ID: UInt8 = 0x0B

struct HidppError: Error, CustomStringConvertible {
    let text: String
    var description: String { text }
}

final class G815 {
    private let manager: IOHIDManager
    private let device: IOHIDDevice
    private var inbox: [[UInt8]] = []
    private let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    private var featureIndex: [UInt16: UInt8] = [:]
    /// a report nobody asked for (the keyboard's own news: a profile reloaded, a key pressed on it)
    var onUnasked: (([UInt8]) -> Void)?

    init() throws {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let match: [String: Any] = [
            kIOHIDVendorIDKey: VID, kIOHIDProductIDKey: PID,
            kIOHIDDeviceUsagePageKey: 0xFF43, kIOHIDDeviceUsageKey: 0x0602,
        ]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let set = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>, let dev = set.first else {
            throw HidppError(text: "no G815 found (046d:c33f, usage page 0xFF43) — is the USB cable in?")
        }
        device = dev
        let r = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard r == kIOReturnSuccess else { throw HidppError(text: String(format: "could not open the G815 (0x%08x)", r)) }
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, buffer, 64, { ctx, _, _, _, _, report, length in
            let me = Unmanaged<G815>.fromOpaque(ctx!).takeUnretainedValue()
            me.inbox.append(Array(UnsafeBufferPointer(start: report, count: length)))
        }, ctx)
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }

    var serial: String {
        (IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey as CFString) as? String) ?? ""
    }

    /// One request, one reply. Throws on a HID++ error or no answer.
    @discardableResult
    func call(_ index: UInt8, _ function: UInt8, _ params: [UInt8] = [], timeout: Double = 0.5) throws -> [UInt8] {
        var msg = [UInt8](repeating: 0, count: 20)
        msg[0] = 0x11; msg[1] = 0xFF; msg[2] = index; msg[3] = (function << 4) | SW_ID
        for (i, b) in params.prefix(16).enumerated() { msg[4 + i] = b }
        while CFRunLoopRunInMode(.defaultMode, 0, true) == .handledSource {}   // late replies first
        for m in inbox where unasked(m) { onUnasked?(m) }
        inbox.removeAll()
        let r = IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0x11, msg, msg.count)
        guard r == kIOReturnSuccess else { throw HidppError(text: String(format: "write failed (0x%08x)", r)) }
        let until = Date().addingTimeInterval(timeout)
        while Date() < until {
            CFRunLoopRunInMode(.defaultMode, 0.01, true)
            while !inbox.isEmpty {
                let m = inbox.removeFirst()
                guard m.count >= 4, m[0] == 0x11 || m[0] == 0x10 else { continue }
                if unasked(m) { onUnasked?(m); continue }
                if m[2] == 0xFF && m.count >= 6 && m[3] == index && m[4] == msg[3] {
                    throw HidppError(text: String(format: "HID++ error %d on feature index 0x%02x function %d", m[5], index, function))
                }
                if m[2] == index && m[3] == msg[3] { return Array(m.dropFirst(4)) }
            }
        }
        throw HidppError(text: String(format: "no answer from feature index 0x%02x function %d", index, function))
    }

    /// Our replies carry SW_ID in the low nibble of the function byte (byte 4 of an error); anything else is
    /// the keyboard speaking on its own.
    private func unasked(_ m: [UInt8]) -> Bool {
        guard m.count >= 5, m[0] == 0x11 || m[0] == 0x10 else { return false }
        return (m[2] == 0xFF ? m[4] : m[3]) & 0x0F != SW_ID
    }

    /// The feature's index on this firmware, or nil when the keyboard does not have it.
    func index(of feature: UInt16) throws -> UInt8? {
        if let i = featureIndex[feature] { return i }
        let r = try call(0x00, 0, [UInt8(feature >> 8), UInt8(feature & 0xFF)])
        guard r[0] != 0 else { return nil }
        featureIndex[feature] = r[0]
        return r[0]
    }

    func need(_ feature: UInt16) throws -> UInt8 {
        guard let i = try index(of: feature) else {
            throw HidppError(text: String(format: "this G815 has no feature 0x%04x", feature))
        }
        return i
    }

    /// Every feature the firmware lists: (index, id, version).
    func features() throws -> [(UInt8, UInt16, UInt8)] {
        guard let fs = try index(of: 0x0001) else { return [] }
        let count = try call(fs, 0)[0]
        var out: [(UInt8, UInt16, UInt8)] = [(0, 0x0000, 0)]
        for i in 1...count {
            let r = try call(fs, 1, [i])
            out.append((i, UInt16(r[0]) << 8 | UInt16(r[1]), r[3]))
        }
        return out
    }
}

func hex(_ b: [UInt8]) -> String { b.map { String(format: "%02x", $0) }.joined(separator: " ") }
