import Foundation
import SwiftUI

// MARK: - Palette shared by diagrams and charts

enum RenderPalette {
    static func color(named name: String?, scheme: ColorScheme) -> Color {
        let key = (name ?? "primary").lowercased()
        let primary = scheme == .dark ? Color.white : Color.black
        let secondary = primary.opacity(0.55)
        switch key {
        case "primary", "accent", "red", "orange", "amber":
            return primary
        case "secondary", "gray", "grey", "muted":
            return secondary
        case "cyan", "green", "mint", "blue", "purple", "yellow":
            return primary.opacity(0.70)
        case "white":
            return primary
        default:
            return primary
        }
    }
}

// MARK: - Diagram canvas

struct DiagramView: View {
    let diagram: DiagramSpec
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            draw(diagram: diagram, context: &context, size: size)
        }
        .aspectRatio(
            diagram.designSize.width / max(diagram.designSize.height, 1),
            contentMode: .fit
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Чертёж: \(diagram.title)")
    }

    private func draw(diagram: DiagramSpec, context: inout GraphicsContext, size: CGSize) {
        let design = diagram.designSize
        let inset: CGFloat = 10
        let usableWidth = max(size.width - inset * 2, 1)
        let usableHeight = max(size.height - inset * 2, 1)
        let scale = min(usableWidth / design.width, usableHeight / design.height)
        let origin = CGPoint(
            x: (size.width - design.width * scale) / 2,
            y: (size.height - design.height * scale) / 2
        )

        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: origin.x + CGFloat(x) * scale, y: origin.y + CGFloat(y) * scale)
        }

        if diagram.showGrid {
            drawGrid(context: &context, design: design, point: point, scale: scale)
        }

        for element in diagram.elements {
            drawElement(
                element,
                context: &context,
                point: point,
                scale: scale
            )
        }
    }

    private func drawGrid(
        context: inout GraphicsContext,
        design: CGSize,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat
    ) {
        let step: Double = 20
        var x = 0.0
        while x <= design.width {
            var path = Path()
            path.move(to: point(x, 0))
            path.addLine(to: point(x, design.height))
            context.stroke(
                path,
                with: .color(Color.physoraSeparator.opacity(0.5)),
                style: StrokeStyle(lineWidth: max(0.5, scale * 0.6), dash: [2, 5])
            )
            x += step
        }
        var y = 0.0
        while y <= design.height {
            var path = Path()
            path.move(to: point(0, y))
            path.addLine(to: point(design.width, y))
            context.stroke(
                path,
                with: .color(Color.physoraSeparator.opacity(0.5)),
                style: StrokeStyle(lineWidth: max(0.5, scale * 0.6), dash: [2, 5])
            )
            y += step
        }
    }

    private func drawElement(
        _ element: DiagramElement,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat
    ) {
        let color = RenderPalette.color(named: element.color, scheme: colorScheme)
        let lineWidth = max(1, CGFloat(element.strokeWidth ?? 2) * scale)
        let stroke = StrokeStyle(
            lineWidth: lineWidth,
            lineCap: .round,
            lineJoin: .round,
            dash: element.dashed == true ? [7 * scale, 5 * scale] : []
        )

        switch element.type {
        case "line", "dashedLine":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            var path = Path()
            path.move(to: point(start.x, start.y))
            path.addLine(to: point(end.x, end.y))
            if element.type == "dashedLine" {
                context.stroke(path, with: .color(color), style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round,
                    dash: [6 * scale, 4 * scale]
                ))
            } else {
                context.stroke(path, with: .color(color), style: stroke)
            }
            if let label = element.label, !label.isEmpty {
                drawLabel(
                    label,
                    at: midpoint(start, end),
                    color: color,
                    context: &context,
                    point: point,
                    scale: scale,
                    offset: CGSize(width: 0, height: -14)
                )
            }
        case "arrow", "axis":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            let p1 = point(start.x, start.y)
            let p2 = point(end.x, end.y)
            drawArrow(from: p1, to: p2, color: color, width: lineWidth, context: &context)
            if let label = element.label, !label.isEmpty {
                drawLabel(
                    label,
                    at: midpoint(start, end),
                    color: color,
                    context: &context,
                    point: point,
                    scale: scale,
                    offset: CGSize(width: 0, height: -16)
                )
            }
        case "circle":
            guard let cx = element.cx, let cy = element.cy else { return }
            let radius = max(2, element.r ?? 12)
            let diameter = CGFloat(radius * 2) * scale
            let corner = point(cx - radius, cy - radius)
            let rect = CGRect(
                x: corner.x,
                y: corner.y,
                width: diameter,
                height: diameter
            )
            if element.filled == true {
                context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.12)))
            }
            context.stroke(Path(ellipseIn: rect), with: .color(color), style: stroke)
        case "dot":
            let cx = element.cx ?? element.x ?? 0
            let cy = element.cy ?? element.y ?? 0
            let radius = max(1.5, element.r ?? 3.2)
            let p = point(cx, cy)
            let screenRadius = CGFloat(radius) * scale
            let rect = CGRect(
                x: p.x - screenRadius,
                y: p.y - screenRadius,
                width: screenRadius * 2,
                height: screenRadius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(color))
        case "rectangle", "roundedRectangle":
            guard let x = element.x, let y = element.y,
                  let width = element.width, let height = element.height else { return }
            let corner = point(x, y)
            let rect = CGRect(
                x: corner.x,
                y: corner.y,
                width: CGFloat(width) * scale,
                height: CGFloat(height) * scale
            )
            let shape = element.type == "roundedRectangle"
                ? RoundedRectangle(cornerRadius: 8 * scale, style: .continuous).path(in: rect)
                : Path(rect)
            if element.filled == true {
                context.fill(shape, with: .color(color.opacity(0.10)))
            }
            context.stroke(shape, with: .color(color), style: stroke)
        case "polygon", "polyline", "curve":
            guard let points = element.points, points.count >= 2 else { return }
            let path: Path
            if element.type == "curve" {
                path = smoothPath(points: points, point: point)
            } else {
                var built = Path()
                built.move(to: point(points[0].x, points[0].y))
                for item in points.dropFirst() {
                    built.addLine(to: point(item.x, item.y))
                }
                if element.type == "polygon" { built.closeSubpath() }
                path = built
            }
            if element.type == "polygon", element.filled == true {
                context.fill(path, with: .color(color.opacity(0.10)))
            }
            context.stroke(path, with: .color(color), style: stroke)

        case "arc":
            guard let cx = element.cx, let cy = element.cy else { return }
            let radius = element.r ?? 30
            let start = Angle(degrees: element.startAngle ?? 0)
            let end = Angle(degrees: element.endAngle ?? 90)
            var path = Path()
            path.addArc(
                center: point(cx, cy),
                radius: CGFloat(radius) * scale,
                startAngle: start,
                endAngle: end,
                clockwise: false
            )
            context.stroke(path, with: .color(color), style: stroke)
        case "angle":
            guard let cx = element.cx, let cy = element.cy else { return }
            let radius = element.r ?? 30
            let start = Angle(degrees: element.startAngle ?? 0)
            let end = Angle(degrees: element.endAngle ?? 45)
            var path = Path()
            path.addArc(
                center: point(cx, cy),
                radius: CGFloat(radius) * scale,
                startAngle: start,
                endAngle: end,
                clockwise: false
            )
            context.stroke(path, with: .color(color), style: stroke)
            if let text = element.label ?? element.text, !text.isEmpty {
                let midAngle = ((element.startAngle ?? 0) + (element.endAngle ?? 45)) / 2 * .pi / 180
                drawLabel(
                    text,
                    at: DiagramPoint(
                        x: cx + cos(midAngle) * (radius + 14),
                        y: cy + sin(midAngle) * (radius + 14)
                    ),
                    color: color,
                    context: &context,
                    point: point,
                    scale: scale
                )
            }
        case "label":
            guard let x = element.x, let y = element.y else { return }
            let text = element.text ?? element.label ?? ""
            guard !text.isEmpty else { return }
            drawLabel(
                text,
                at: DiagramPoint(x: x, y: y),
                color: color,
                context: &context,
                point: point,
                scale: scale
            )
        case "spring":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawSpring(from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth)
        case "resistor":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawResistor(from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth)
        case "battery":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawBattery(from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth)
        case "capacitor":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawCapacitor(from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth)
        case "lamp":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawCircleComponent(
                "×", from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth
            )
        case "ammeter":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawCircleComponent(
                "A", from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth
            )
        case "voltmeter":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawCircleComponent(
                "V", from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth
            )
        case "switch":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawSwitch(from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth)
        case "inductor":
            guard let start = element.startPoint, let end = element.endPoint else { return }
            drawInductor(from: start, to: end, context: &context, point: point, scale: scale, color: color, width: lineWidth)
        case "ground":
            guard let start = element.startPoint else { return }
            drawGround(at: start, context: &context, point: point, scale: scale, color: color, width: lineWidth)
        default:
            return
        }
    }

    // MARK: Primitive helpers

    private func drawArrow(
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        width: CGFloat,
        context: inout GraphicsContext
    ) {
        var line = Path()
        line.move(to: start)
        line.addLine(to: end)
        context.stroke(
            line,
            with: .color(color),
            style: StrokeStyle(lineWidth: width, lineCap: .round)
        )

        let angle = atan2(Double(end.y - start.y), Double(end.x - start.x))
        let headLength = Double(max(width * 4.2, 8))
        let headAngle = Double.pi / 7
        let p1 = CGPoint(
            x: end.x - CGFloat(headLength * cos(angle - headAngle)),
            y: end.y - CGFloat(headLength * sin(angle - headAngle))
        )
        let p2 = CGPoint(
            x: end.x - CGFloat(headLength * cos(angle + headAngle)),
            y: end.y - CGFloat(headLength * sin(angle + headAngle))
        )
        var head = Path()
        head.move(to: end)
        head.addLine(to: p1)
        head.addLine(to: p2)
        head.closeSubpath()
        context.fill(head, with: .color(color))
    }

    private func drawLabel(
        _ text: String,
        at designPoint: DiagramPoint,
        color: Color,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        offset: CGSize = .zero
    ) {
        let fontSize = min(max(10, 13 * scale), 17)
        let resolved = context.resolve(
            Text(text)
                .font(.system(size: fontSize, weight: .medium, design: .rounded))
                .foregroundColor(color)
        )
        let measured = resolved.measure(in: CGSize(width: 260, height: 60))
        let center = point(designPoint.x, designPoint.y)
        let drawPoint = CGPoint(x: center.x + offset.width, y: center.y + offset.height)
        let backgroundRect = CGRect(
            x: drawPoint.x - measured.width / 2 - 3,
            y: drawPoint.y - measured.height / 2 - 1,
            width: measured.width + 6,
            height: measured.height + 2
        )
        let background = RoundedRectangle(cornerRadius: 4, style: .continuous)
            .path(in: backgroundRect)
        context.fill(
            background,
            with: .color(Color.physoraSurface.opacity(colorScheme == .dark ? 0.78 : 0.82))
        )
        context.draw(resolved, at: drawPoint, anchor: .center)
    }

    private func midpoint(_ a: DiagramPoint, _ b: DiagramPoint) -> DiagramPoint {
        DiagramPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private func smoothPath(
        points: [DiagramPoint],
        point: (Double, Double) -> CGPoint
    ) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: point(first.x, first.y))
        if points.count == 2 {
            path.addLine(to: point(points[1].x, points[1].y))
            return path
        }
        for index in 1..<points.count {
            let previous = point(points[index - 1].x, points[index - 1].y)
            let current = point(points[index].x, points[index].y)
            let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previous)
        }
        if let last = points.last {
            path.addLine(to: point(last.x, last.y))
        }
        return path
    }

    private func unitVector(from start: DiagramPoint, to end: DiagramPoint) -> (dx: Double, dy: Double, length: Double) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        return (dx / length, dy / length, length)
    }

    private func drawSpring(
        from start: DiagramPoint,
        to end: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let vector = unitVector(from: start, to: end)
        let perpendicular = (-vector.dy, vector.dx)
        let lead = min(18, vector.length * 0.18)
        let coilStart = DiagramPoint(
            x: start.x + vector.dx * lead,
            y: start.y + vector.dy * lead
        )
        let coilEnd = DiagramPoint(
            x: end.x - vector.dx * lead,
            y: end.y - vector.dy * lead
        )
        var path = Path()
        path.move(to: point(start.x, start.y))
        path.addLine(to: point(coilStart.x, coilStart.y))
        let segments = 8
        let amplitude = 8.0
        for index in 0...segments {
            let t = Double(index) / Double(segments)
            let offset = (index == 0 || index == segments) ? 0 : (index % 2 == 0 ? amplitude : -amplitude)
            let x = coilStart.x + (coilEnd.x - coilStart.x) * t + perpendicular.0 * offset
            let y = coilStart.y + (coilEnd.y - coilStart.y) * t + perpendicular.1 * offset
            path.addLine(to: point(x, y))
        }
        path.addLine(to: point(end.x, end.y))
        context.stroke(path, with: .color(color), style: StrokeStyle(
            lineWidth: width,
            lineCap: .round,
            lineJoin: .round
        ))
    }

    private func drawResistor(
        from start: DiagramPoint,
        to end: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let vector = unitVector(from: start, to: end)
        let perpendicular = (-vector.dy, vector.dx)
        let centerX = (start.x + end.x) / 2
        let centerY = (start.y + end.y) / 2
        let half = min(24, vector.length * 0.28)
        let coilStart = DiagramPoint(
            x: centerX - vector.dx * half,
            y: centerY - vector.dy * half
        )
        let coilEnd = DiagramPoint(
            x: centerX + vector.dx * half,
            y: centerY + vector.dy * half
        )
        var path = Path()
        path.move(to: point(start.x, start.y))
        path.addLine(to: point(coilStart.x, coilStart.y))
        let segments = 6
        for index in 0...segments {
            let t = Double(index) / Double(segments)
            let offset = (index == 0 || index == segments) ? 0 : (index % 2 == 0 ? 7.0 : -7.0)
            let x = coilStart.x + (coilEnd.x - coilStart.x) * t + perpendicular.0 * offset
            let y = coilStart.y + (coilEnd.y - coilStart.y) * t + perpendicular.1 * offset
            path.addLine(to: point(x, y))
        }
        path.addLine(to: point(end.x, end.y))
        context.stroke(path, with: .color(color), style: StrokeStyle(
            lineWidth: width,
            lineCap: .round,
            lineJoin: .round
        ))
    }

    private func drawBattery(
        from start: DiagramPoint,
        to end: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let vector = unitVector(from: start, to: end)
        let perpendicular = (-vector.dy, vector.dx)
        let cx = (start.x + end.x) / 2
        let cy = (start.y + end.y) / 2
        let gap = 4.0
        let longHalf = 11.0
        let shortHalf = 6.0

        var leads = Path()
        leads.move(to: point(start.x, start.y))
        leads.addLine(to: point(cx - vector.dx * gap, cy - vector.dy * gap))
        leads.move(to: point(cx + vector.dx * gap, cy + vector.dy * gap))
        leads.addLine(to: point(end.x, end.y))
        context.stroke(leads, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))

        let longCenter = (cx - vector.dx * gap, cy - vector.dy * gap)
        let shortCenter = (cx + vector.dx * gap, cy + vector.dy * gap)
        var plates = Path()
        plates.move(to: point(
            longCenter.0 - perpendicular.0 * longHalf,
            longCenter.1 - perpendicular.1 * longHalf
        ))
        plates.addLine(to: point(
            longCenter.0 + perpendicular.0 * longHalf,
            longCenter.1 + perpendicular.1 * longHalf
        ))
        plates.move(to: point(
            shortCenter.0 - perpendicular.0 * shortHalf,
            shortCenter.1 - perpendicular.1 * shortHalf
        ))
        plates.addLine(to: point(
            shortCenter.0 + perpendicular.0 * shortHalf,
            shortCenter.1 + perpendicular.1 * shortHalf
        ))
        context.stroke(plates, with: .color(color), style: StrokeStyle(lineWidth: width * 1.15, lineCap: .round))
    }

    private func drawCapacitor(
        from start: DiagramPoint,
        to end: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let vector = unitVector(from: start, to: end)
        let perpendicular = (-vector.dy, vector.dx)
        let cx = (start.x + end.x) / 2
        let cy = (start.y + end.y) / 2
        let gap = 3.5
        let half = 11.0
        var leads = Path()
        leads.move(to: point(start.x, start.y))
        leads.addLine(to: point(cx - vector.dx * gap, cy - vector.dy * gap))
        leads.move(to: point(cx + vector.dx * gap, cy + vector.dy * gap))
        leads.addLine(to: point(end.x, end.y))
        context.stroke(leads, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))

        var plates = Path()
        for sign in [-1.0, 1.0] {
            let px = cx + vector.dx * gap * sign
            let py = cy + vector.dy * gap * sign
            plates.move(to: point(px - perpendicular.0 * half, py - perpendicular.1 * half))
            plates.addLine(to: point(px + perpendicular.0 * half, py + perpendicular.1 * half))
        }
        context.stroke(plates, with: .color(color), style: StrokeStyle(lineWidth: width * 1.1, lineCap: .round))
    }

    private func drawCircleComponent(
        _ symbol: String,
        from start: DiagramPoint,
        to end: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let vector = unitVector(from: start, to: end)
        let cx = (start.x + end.x) / 2
        let cy = (start.y + end.y) / 2
        let radius = 12.0
        var leads = Path()
        leads.move(to: point(start.x, start.y))
        leads.addLine(to: point(cx - vector.dx * radius, cy - vector.dy * radius))
        leads.move(to: point(cx + vector.dx * radius, cy + vector.dy * radius))
        leads.addLine(to: point(end.x, end.y))
        context.stroke(leads, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))

        let center = point(cx, cy)
        let screenRadius = CGFloat(radius) * scale
        let rect = CGRect(
            x: center.x - screenRadius,
            y: center.y - screenRadius,
            width: screenRadius * 2,
            height: screenRadius * 2
        )
        context.stroke(Path(ellipseIn: rect), with: .color(color), style: StrokeStyle(lineWidth: width))
        drawCenteredSymbol(symbol, at: center, size: 12 * scale, color: color, context: &context)
    }

    private func drawSwitch(
        from start: DiagramPoint,
        to end: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let vector = unitVector(from: start, to: end)
        let perpendicular = (-vector.dy, vector.dx)
        let first = DiagramPoint(
            x: start.x + vector.dx * vector.length * 0.35,
            y: start.y + vector.dy * vector.length * 0.35
        )
        let second = DiagramPoint(
            x: start.x + vector.dx * vector.length * 0.72,
            y: start.y + vector.dy * vector.length * 0.72
        )
        var path = Path()
        path.move(to: point(start.x, start.y))
        path.addLine(to: point(first.x, first.y))
        path.addLine(to: point(
            second.x + perpendicular.0 * 10,
            second.y + perpendicular.1 * 10
        ))
        path.move(to: point(second.x, second.y))
        path.addLine(to: point(end.x, end.y))
        context.stroke(path, with: .color(color), style: StrokeStyle(
            lineWidth: width,
            lineCap: .round,
            lineJoin: .round
        ))
        let p = point(second.x, second.y)
        context.fill(Path(ellipseIn: CGRect(x: p.x - 1.8, y: p.y - 1.8, width: 3.6, height: 3.6)), with: .color(color))
        let p2 = point(first.x, first.y)
        context.fill(Path(ellipseIn: CGRect(x: p2.x - 1.8, y: p2.y - 1.8, width: 3.6, height: 3.6)), with: .color(color))
    }

    private func drawInductor(
        from start: DiagramPoint,
        to end: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let vector = unitVector(from: start, to: end)
        let perpendicular = (-vector.dy, vector.dx)
        let lead = min(14, vector.length * 0.2)
        let begin = DiagramPoint(x: start.x + vector.dx * lead, y: start.y + vector.dy * lead)
        let finish = DiagramPoint(x: end.x - vector.dx * lead, y: end.y - vector.dy * lead)
        var path = Path()
        path.move(to: point(start.x, start.y))
        path.addLine(to: point(begin.x, begin.y))
        let samples = 36
        for index in 0...samples {
            let t = Double(index) / Double(samples)
            let wave = sin(t * .pi * 6) * 5
            let x = begin.x + (finish.x - begin.x) * t + perpendicular.0 * wave
            let y = begin.y + (finish.y - begin.y) * t + perpendicular.1 * wave
            path.addLine(to: point(x, y))
        }
        path.addLine(to: point(end.x, end.y))
        context.stroke(path, with: .color(color), style: StrokeStyle(
            lineWidth: width,
            lineCap: .round,
            lineJoin: .round
        ))
    }

    private func drawGround(
        at origin: DiagramPoint,
        context: inout GraphicsContext,
        point: (Double, Double) -> CGPoint,
        scale: CGFloat,
        color: Color,
        width: CGFloat
    ) {
        let start = point(origin.x, origin.y)
        var path = Path()
        path.move(to: start)
        path.addLine(to: CGPoint(x: start.x, y: start.y + 9 * scale))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))

        for (index, halfWidth) in [14.0, 9.0, 4.0].enumerated() {
            var line = Path()
            let y = start.y + CGFloat(11 + Double(index) * 5) * scale
            line.move(to: CGPoint(x: start.x - CGFloat(halfWidth) * scale, y: y))
            line.addLine(to: CGPoint(x: start.x + CGFloat(halfWidth) * scale, y: y))
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
    }

    private func drawCenteredSymbol(
        _ symbol: String,
        at point: CGPoint,
        size: CGFloat,
        color: Color,
        context: inout GraphicsContext
    ) {
        context.draw(
            Text(symbol)
                .font(.system(size: max(8, size), weight: .semibold, design: .rounded))
                .foregroundColor(color),
            at: point,
            anchor: .center
        )
    }
}

// MARK: - Convenience accessors

private extension DiagramElement {
    var startPoint: DiagramPoint? {
        guard let x1, let y1, let x2, let y2 else { return nil }
        return DiagramPoint(x: x1, y: y1)
    }

    var endPoint: DiagramPoint? {
        guard let x1, let y1, let x2, let y2 else { return nil }
        return DiagramPoint(x: x2, y: y2)
    }
}
