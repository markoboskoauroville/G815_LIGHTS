// click.swift — a real mouse on the screen, for testing the window as his hand would.
//   click x y            drag x0 y0 x1 y1        (global screen points)
import CoreGraphics
import Foundation
let a = CommandLine.arguments.dropFirst().map { $0 }
func post(_ t: CGEventType, _ x: Double, _ y: Double) {
    CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left)!.post(tap: .cghidEventTap)
    usleep(30000)
}
let v = a.dropFirst().compactMap(Double.init)
switch a.first {
case "click": post(.mouseMoved, v[0], v[1]); post(.leftMouseDown, v[0], v[1]); post(.leftMouseUp, v[0], v[1])
case "drag":
    post(.mouseMoved, v[0], v[1]); post(.leftMouseDown, v[0], v[1])
    for i in 1...15 { let f = Double(i) / 15; post(.leftMouseDragged, v[0] + (v[2] - v[0]) * f, v[1] + (v[3] - v[1]) * f) }
    post(.leftMouseUp, v[2], v[3])
default: print("click x y | drag x0 y0 x1 y1")
}
