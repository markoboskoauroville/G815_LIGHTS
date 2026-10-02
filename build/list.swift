import Foundation
import IOKit.hid
let m = IOHIDManagerCreate(kCFAllocatorDefault, 0)
IOHIDManagerSetDeviceMatching(m, [kIOHIDVendorIDKey: 0x046D] as CFDictionary)
IOHIDManagerOpen(m, 0)
for d in (IOHIDManagerCopyDevices(m) as? Set<IOHIDDevice>) ?? [] {
  func p(_ k: String) -> Any { IOHIDDeviceGetProperty(d, k as CFString) ?? "-" }
  print(p(kIOHIDProductKey), p(kIOHIDProductIDKey), String(format:"page 0x%04x usage 0x%04x", (p(kIOHIDPrimaryUsagePageKey) as? Int) ?? -1, (p(kIOHIDPrimaryUsageKey) as? Int) ?? -1), p("DeviceUsagePairs"))
}
