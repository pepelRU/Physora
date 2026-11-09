import SwiftUI

struct SolvingProgressView: View {
    let phase: SolverViewModel.Phase
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var startedAt = Date()

    var body: some View {
        ZStack {
            PhysoraBackground()
            ScrollView {
                VStack(spacing: 26) {
                    Spacer(minLength: 24)
                    animatedMark
                        .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Physora решает задачу")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)
                            .multilineTextAlignment(.center)
                        Text("Структурированное решение · Дано · Формулы · Схемы · Ответ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    phaseList

                    TimelineView(.periodic(from: startedAt, by: 1)) { context in
                        ElapsedCaption(startedAt: startedAt, now: context.date)
                    }

                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(.physoraAccent)
                            .controlSize(.large)
                        Text("Ответ модели появляется только после полной проверки. Промежуточные статусы DeepSeek недоступны — этапы отражают реальную обработку в приложении.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }

                    Button {
                        onCancel()
                        dismiss()
                    } label: {
                        Text("Отменить")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 22)
            }
        }
        .interactiveDismissDisabled()
    }

    private var animatedMark: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let seconds = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle()
                    .fill(Color.physoraAccent.opacity(0.10))
                    .frame(width: 164, height: 164)
                    .blur(radius: 20)
                SolvingAtomMark(angle: seconds * 0.55)
                    .frame(width: 142, height: 142)
                BrandTile(size: 56)
            }
        }
        .frame(width: 180, height: 180)
        .accessibilityHidden(true)
    }

    private var phaseList: some View {
        VStack(spacing: 0) {
            ForEach(Array(SolverViewModel.Phase.allCases.enumerated()), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: 13) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(statusColor(for: item).opacity(item.rawValue <= phase.rawValue ? 0.16 : 0.07))
                                .frame(width: 32, height: 32)
                            if item.rawValue < phase.rawValue {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.physoraMint)
                            } else if item == phase {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(Color.physoraAccent)
                            } else {
                                Image(systemName: item.systemImage)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        if index < SolverViewModel.Phase.allCases.count - 1 {
                            Rectangle()
                                .fill(item.rawValue < phase.rawValue
                                      ? Color.physoraMint.opacity(0.34)
                                      : Color.physoraSeparator)
                                .frame(width: 1.5, height: 28)
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.subheadline.weight(item == phase ? .semibold : .regular))
                            .foregroundStyle(item.rawValue <= phase.rawValue ? Color.primary : Color.secondary.opacity(0.55))
                        if item == phase {
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 3)
            }
        }
        .padding(18)
        .background(Color.physoraSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.physoraStroke, lineWidth: 1)
        )
        .animation(.snappy(duration: 0.3), value: phase)
    }

    private func statusColor(for item: SolverViewModel.Phase) -> Color {
        if item.rawValue < phase.rawValue { return .physoraMint }
        if item == phase { return .physoraAccent }
        return .secondary
    }
}

private struct ElapsedCaption: View {
    let startedAt: Date
    let now: Date

    var body: some View {
        Text("Прошло \(max(0, Int(now.timeIntervalSince(startedAt)))) с")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.tertiary)
    }
}

private struct SolvingAtomMark: View {
    let angle: Double

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let rx = size.width * 0.44
            let ry = size.height * 0.16
            for (index, degrees) in [-31.0, 31.0, 89.0].enumerated() {
                let rotation = (degrees * .pi / 180) + angle * (index == 2 ? -0.35 : 0.35)
                let transform = CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: CGFloat(rotation))
                    .translatedBy(x: -center.x, y: -center.y)
                let rect = CGRect(
                    x: center.x - rx,
                    y: center.y - ry,
                    width: rx * 2,
                    height: ry * 2
                )
                let path = Path(ellipseIn: rect).applying(transform)
                context.stroke(
                    path,
                    with: .color(Color.physoraAccent.opacity(index == 0 ? 0.85 : 0.46)),
                    style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                )
                let local = CGPoint(
                    x: center.x + rx * CGFloat(cos(angle + Double(index) * 2.1)),
                    y: center.y + ry * CGFloat(sin(angle + Double(index) * 2.1))
                )
                let cosine = CGFloat(cos(rotation))
                let sine = CGFloat(sin(rotation))
                let electron = CGPoint(
                    x: center.x + (local.x - center.x) * cosine - (local.y - center.y) * sine,
                    y: center.y + (local.x - center.x) * sine + (local.y - center.y) * cosine
                )
                let electronRect = CGRect(x: electron.x - 4, y: electron.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: electronRect), with: .color(Color.physoraAccent))
            }
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14)),
                with: .color(Color.physoraAccent.opacity(0.36))
            )
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)),
                with: .color(.white)
            )
        }
        .accessibilityHidden(true)
    }
}
