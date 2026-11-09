import Charts
import SwiftUI

struct PhysicsGraphView: View {
    let graph: PhysicsGraph
    @Environment(\.colorScheme) private var colorScheme

    private var seriesColors: [Color] {
        graph.series.enumerated().map { index, series in
            if !series.color.isEmpty {
                return RenderPalette.color(named: series.color, scheme: colorScheme)
            }
            let fallback: [Color] = [.physoraAccent, .physoraMint, .physoraAmber, .purple, .red]
            return fallback[index % fallback.count]
        }
    }

    private var seriesIDs: [String] {
        graph.series.indices.map { "series-\($0)" }
    }

    private var totalPoints: Int {
        graph.series.reduce(0) { $0 + $1.points.count }
    }

    private var showsPoints: Bool { totalPoints <= 80 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(Array(graph.series.enumerated()), id: \.offset) { index, series in
                    ForEach(Array(series.points.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("X", point.x),
                            y: .value("Y", point.y),
                            series: .value("Серия", seriesIDs[index])
                        )
                        .foregroundStyle(seriesColors[index])
                        .lineStyle(StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.linear)

                        if showsPoints {
                            PointMark(
                                x: .value("X", point.x),
                                y: .value("Y", point.y)
                            )
                            .foregroundStyle(seriesColors[index])
                            .symbolSize(20)
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    if graph.showGrid {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                            .foregroundStyle(Color.physoraSeparator.opacity(0.8))
                    }
                    AxisTick().foregroundStyle(Color.secondary)
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    if graph.showGrid {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
                            .foregroundStyle(Color.physoraSeparator.opacity(0.8))
                    }
                    AxisTick().foregroundStyle(Color.secondary)
                    AxisValueLabel()
                }
            }
            .chartXAxisLabel(graph.xLabel.isEmpty ? "x" : graph.xLabel)
            .chartYAxisLabel(graph.yLabel.isEmpty ? "y" : graph.yLabel)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.physoraSurfaceMuted.opacity(0.46))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(height: 235)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("График: \(graph.title). Ось X: \(graph.xLabel). Ось Y: \(graph.yLabel)")

            if !graph.series.isEmpty {
                HStack(spacing: 14) {
                    ForEach(Array(graph.series.enumerated()), id: \.offset) { index, series in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(seriesColors[index])
                                .frame(width: 8, height: 8)
                            Text(series.name.isEmpty ? "Серия \(index + 1)" : series.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
}
