//
//  GoogleLogoMark.swift
//  MotoLog
//

import SwiftUI

/// Google's official multi-color "G" logo, traced from Google's own 48x48
/// SVG path data (brand guidelines require the mark itself stay unaltered,
/// even when the surrounding button is custom-styled).
struct GoogleLogoMark: View {
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 48
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }

            var red = Path()
            red.move(to: pt(24, 9.5))
            red.addCurve(to: pt(33.14, 12.72), control1: pt(27.54, 9.5), control2: pt(30.66, 10.72))
            red.addLine(to: pt(39.98, 5.88))
            red.addCurve(to: pt(24, 0), control1: pt(35.84, 2.39), control2: pt(30.22, 0))
            red.addCurve(to: pt(2.56, 13.22), control1: pt(14.62, 0), control2: pt(6.51, 5.38))
            red.addLine(to: pt(10.54, 19.41))
            red.addCurve(to: pt(24, 9.5), control1: pt(12.43, 13.72), control2: pt(17.74, 9.5))
            red.closeSubpath()
            context.fill(red, with: .color(Color(red: 0.918, green: 0.263, blue: 0.208)))

            var blue = Path()
            blue.move(to: pt(46.98, 24.55))
            blue.addCurve(to: pt(46.60, 20.00), control1: pt(46.98, 22.98), control2: pt(46.83, 21.46))
            blue.addLine(to: pt(24, 20.00))
            blue.addLine(to: pt(24, 29.02))
            blue.addLine(to: pt(36.94, 29.02))
            blue.addCurve(to: pt(32.16, 36.20), control1: pt(36.36, 31.98), control2: pt(34.68, 34.50))
            blue.addLine(to: pt(39.89, 42.20))
            blue.addCurve(to: pt(46.98, 24.55), control1: pt(44.40, 38.02), control2: pt(46.98, 31.84))
            blue.closeSubpath()
            context.fill(blue, with: .color(Color(red: 0.259, green: 0.522, blue: 0.957)))

            var yellow = Path()
            yellow.move(to: pt(10.53, 28.59))
            yellow.addCurve(to: pt(9.77, 24.00), control1: pt(10.05, 27.14), control2: pt(9.77, 25.60))
            yellow.addCurve(to: pt(10.53, 19.41), control1: pt(9.77, 22.40), control2: pt(10.04, 20.86))
            yellow.addLine(to: pt(2.55, 13.22))
            yellow.addCurve(to: pt(0, 24), control1: pt(0.92, 16.46), control2: pt(0, 20.12))
            yellow.addCurve(to: pt(2.56, 34.78), control1: pt(0, 27.88), control2: pt(0.92, 31.54))
            yellow.addLine(to: pt(10.53, 28.59))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(Color(red: 0.984, green: 0.737, blue: 0.020)))

            var green = Path()
            green.move(to: pt(24, 48))
            green.addCurve(to: pt(39.89, 42.19), control1: pt(30.48, 48), control2: pt(35.93, 45.87))
            green.addLine(to: pt(32.16, 36.19))
            green.addCurve(to: pt(24.00, 38.49), control1: pt(30.01, 37.64), control2: pt(27.24, 38.49))
            green.addCurve(to: pt(10.54, 28.58), control1: pt(17.74, 38.49), control2: pt(12.43, 34.27))
            green.addLine(to: pt(2.56, 34.77))
            green.addCurve(to: pt(24, 48), control1: pt(6.51, 42.62), control2: pt(14.62, 48))
            green.closeSubpath()
            context.fill(green, with: .color(Color(red: 0.204, green: 0.659, blue: 0.325)))
        }
    }
}

#Preview {
    GoogleLogoMark()
        .frame(width: 48, height: 48)
}
