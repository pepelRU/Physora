import CoreGraphics
import Foundation

// MARK: - Programmatic diagrams

/// A diagram is represented as graphics primitives, never as a text
/// description or an image supplied by the model. The app renders it with
/// SwiftUI Canvas and Core Graphics.
struct DiagramSpec: Codable, Hashable, Sendable {
    var title: String
    var kind: String
    var width: Double
    var height: Double
    var showGrid: Bool
    var elements: [DiagramElement]

    init(
        title: String,
        kind: String = "generic",
        width: Double = 360,
        height: Double = 240,
        showGrid: Bool = false,
        elements: [DiagramElement] = []
    ) {
        self.title = title
        self.kind = kind
        self.width = width
        self.height = height
        self.showGrid = showGrid
        self.elements = elements
    }

    enum CodingKeys: String, CodingKey {
        case title, kind, width, height, showGrid, elements
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = c.value(String.self, forKey: .title, default: "Схема")
        kind = c.value(String.self, forKey: .kind, default: "generic")
        width = c.value(Double.self, forKey: .width, default: 360)
        height = c.value(Double.self, forKey: .height, default: 240)
        showGrid = c.value(Bool.self, forKey: .showGrid, default: false)
        if let wrapped = try? c.decode([DiagramElementProxy].self, forKey: .elements) {
            elements = wrapped.compactMap(\.element)
        } else {
            elements = []
        }
    }

    var designSize: CGSize {
        CGSize(
            width: min(max(width, 120), 1200),
            height: min(max(height, 90), 900)
        )
    }
}

private struct DiagramElementProxy: Decodable {
    let element: DiagramElement?

    init(from decoder: Decoder) throws {
        element = try? DiagramElement(from: decoder)
    }
}

/// A deliberately permissive primitive record. The prompt asks the model for a
/// small vocabulary of shapes; unexpected properties are ignored and unknown
/// element types are skipped by the renderer instead of breaking a solution.
struct DiagramElement: Codable, Hashable, Sendable {
    var type: String
    var x1: Double?
    var y1: Double?
    var x2: Double?
    var y2: Double?
    var x: Double?
    var y: Double?
    var cx: Double?
    var cy: Double?
    var r: Double?
    var width: Double?
    var height: Double?
    var points: [DiagramPoint]?
    var text: String?
    var label: String?
    var color: String?
    var dashed: Bool?
    var filled: Bool?
    var strokeWidth: Double?
    var startAngle: Double?
    var endAngle: Double?
    var rotation: Double?

    static let supportedTypes: Set<String> = [
        "line", "arrow", "dashedLine", "circle", "dot", "rectangle", "roundedRectangle",
        "polygon", "polyline", "curve", "arc", "angle", "spring", "resistor",
        "battery", "capacitor", "lamp", "switch", "ammeter", "voltmeter",
        "inductor", "ground", "label", "axis"
    ]

    var isSupported: Bool {
        Self.supportedTypes.contains(type)
    }
}

struct DiagramPoint: Codable, Hashable, Sendable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        x = try c.decodeFlexibleDouble(forKey: .x)
        y = try c.decodeFlexibleDouble(forKey: .y)
    }
}

// MARK: - Graphs

struct PhysicsGraph: Codable, Hashable, Sendable {
    var title: String
    var xLabel: String
    var yLabel: String
    var series: [GraphSeries]
    var showGrid: Bool

    init(
        title: String,
        xLabel: String,
        yLabel: String,
        series: [GraphSeries] = [],
        showGrid: Bool = true
    ) {
        self.title = title
        self.xLabel = xLabel
        self.yLabel = yLabel
        self.series = series
        self.showGrid = showGrid
    }

    enum CodingKeys: String, CodingKey {
        case title, xLabel, yLabel, series, showGrid
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = c.value(String.self, forKey: .title, default: "График")
        xLabel = c.value(String.self, forKey: .xLabel, default: "")
        yLabel = c.value(String.self, forKey: .yLabel, default: "")
        showGrid = c.value(Bool.self, forKey: .showGrid, default: true)
        if let wrapped = try? c.decode([GraphSeriesProxy].self, forKey: .series) {
            series = wrapped.compactMap(\.series).filter { $0.points.count >= 2 }
        } else {
            series = []
        }
    }

    var hasEnoughPoints: Bool {
        series.contains(where: { $0.points.count >= 1 }) && !series.isEmpty
    }
}

private struct GraphSeriesProxy: Decodable {
    let series: GraphSeries?

    init(from decoder: Decoder) throws {
        series = try? GraphSeries(from: decoder)
    }
}

struct GraphSeries: Codable, Hashable, Sendable {
    var name: String
    var color: String
    var points: [GraphPoint]

    init(name: String, color: String = "accent", points: [GraphPoint] = []) {
        self.name = name
        self.color = color
        self.points = points
    }

    enum CodingKeys: String, CodingKey {
        case name, color, points
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.value(String.self, forKey: .name, default: "Зависимость")
        color = c.value(String.self, forKey: .color, default: "accent")
        if let wrapped = try? c.decode([GraphPointProxy].self, forKey: .points) {
            points = wrapped.compactMap(\.point)
        } else {
            points = []
        }
    }
}

private struct GraphPointProxy: Decodable {
    let point: GraphPoint?

    init(from decoder: Decoder) throws {
        point = try? GraphPoint(from: decoder)
    }
}

struct GraphPoint: Codable, Hashable, Sendable {
    var x: Double
    var y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        x = try c.decodeFlexibleDouble(forKey: .x)
        y = try c.decodeFlexibleDouble(forKey: .y)
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key) {
            let normalized = value
                .replacingOccurrences(of: ",", with: ".")
                .replacingOccurrences(of: " ", with: "")
            if let double = Double(normalized) { return double }
        }
        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Ожидалось число"
        )
    }

    func value<Value: Decodable>(_ type: Value.Type, forKey key: Key, default defaultValue: Value) -> Value {
        do {
            return try decodeIfPresent(type, forKey: key) ?? defaultValue
        } catch {
            return defaultValue
        }
    }
}
