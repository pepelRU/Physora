import SwiftData
import SwiftUI

struct QuickAccessCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(13)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
        }
        .buttonStyle(PressableScaleButtonStyle())
    }
}

struct RecentSolutionCard: View {
    let problem: SolvedProblem

    var body: some View {
        NavigationLink(value: SolutionRoute(id: problem.id)) {
            HStack(alignment: .top, spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.physoraAccent.opacity(0.10))
                        .frame(width: 42, height: 42)
                    Image(systemName: "function")
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.physoraAccent)
                }
                VStack(alignment: .leading, spacing: 7) {
                    Text(problem.prompt)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(problem.answerSummary)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.physoraAccent)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if !problem.topic.isEmpty {
                            Text(problem.topic)
                                .lineLimit(1)
                        }
                        if !problem.topic.isEmpty {
                            Circle().fill(Color.physoraSeparator).frame(width: 2.5, height: 2.5)
                        }
                        Text(problem.createdAt.physoraShortDate)
                        Spacer(minLength: 0)
                        if problem.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.physoraAmber)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.quaternary)
                    .padding(.top, 14)
            }
            .padding(15)
            .background(Color.physoraSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
        }
        .buttonStyle(PressableScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(problem.prompt). Ответ: \(problem.answerSummary)")
    }
}

struct ConnectedPill: View {
    let modelTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.physoraMint)
                .frame(width: 7, height: 7)
                .shadow(color: Color.physoraMint.opacity(0.55), radius: 4)
            Text("DeepSeek подключён")
                .font(.caption.weight(.semibold))
            Text("·")
                .foregroundStyle(.tertiary)
            Text(modelTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            Button("Настроить", action: action)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.physoraAccent)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .glassEffect(.regular.tint(Color.physoraMint.opacity(0.07)), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
