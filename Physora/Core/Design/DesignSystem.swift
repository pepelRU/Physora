import SwiftUI
import UIKit

// MARK: - Monochrome palette

extension Color {
    static let physoraAccent = Color(uiColor: .label)
    static let physoraAccentDeep = Color(uiColor: .secondaryLabel)
    static let physoraBackground = Color(uiColor: .systemGroupedBackground)
    static let physoraSurface = Color(uiColor: .secondarySystemGroupedBackground)
    static let physoraSurfaceMuted = Color(uiColor: .tertiarySystemGroupedBackground)
    static let physoraStroke = Color(uiColor: .separator).opacity(0.72)
    static let physoraSeparator = Color(uiColor: .separator)
    static let physoraMint = Color(uiColor: .secondaryLabel)
    static let physoraAmber = Color(uiColor: .secondaryLabel)

    static var physoraAccentSoft: Color { physoraAccent.opacity(0.09) }
}

// MARK: - Backgrounds and surfaces

struct PhysoraBackground: View {
    var body: some View {
        Color.physoraBackground
            .ignoresSafeArea()
    }
}

private struct PhysoraCardModifier: ViewModifier {
    var padding: CGFloat
    var cornerRadius: CGFloat
    var elevated: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.physoraSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.physoraStroke, lineWidth: 1)
            )
    }
}

extension View {
    func physoraCard(
        padding: CGFloat = 18,
        cornerRadius: CGFloat = 24,
        elevated: Bool = false
    ) -> some View {
        modifier(PhysoraCardModifier(padding: padding, cornerRadius: cornerRadius, elevated: elevated))
    }

    func physoraSectionTitle() -> some View {
        font(.headline)
            .fontDesign(.rounded)
            .foregroundStyle(.primary)
    }
}

// MARK: - Small reusable components

struct IconBadge: View {
    let systemImage: String
    var tint: Color = .physoraAccent
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.40, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(tint.opacity(0.16), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}

struct CapsuleTag: View {
    let text: String
    var systemImage: String?
    var tint: Color = .physoraAccent

    var body: some View {
        HStack(spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.11), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.13), lineWidth: 1))
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityElement(children: .combine)
    }
}

struct PhysoraSectionHeader: View {
    let title: String
    var subtitle: String?
    var systemImage: String?
    var trailing: AnyView?

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        trailing: AnyView? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.physoraAccent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .fontDesign(.rounded)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                trailing
            }
        }
    }
}

struct PressableScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct PhysoraPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let fill = colorScheme == .dark ? Color.white : Color.black
        let foreground = colorScheme == .dark ? Color.black : Color.white
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .padding(.horizontal, 16)
            .background(fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.32)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct SmallIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var tint: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(Color.physoraSurfaceMuted, in: Circle())
        }
        .buttonStyle(PressableScaleButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Logo

struct AtomMark: View {
    var size: CGFloat = 44
    var showsGlow: Bool = true
    var tint: Color = .primary

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let rx = canvasSize.width * 0.365
            let ry = canvasSize.height * 0.135
            let lineWidth = max(1.2, canvasSize.width * 0.030)

            if showsGlow {
                let glowRect = CGRect(
                    x: center.x - canvasSize.width * 0.22,
                    y: center.y - canvasSize.height * 0.22,
                    width: canvasSize.width * 0.44,
                    height: canvasSize.height * 0.44
                )
                context.fill(Path(ellipseIn: glowRect), with: .color(tint.opacity(0.08)))
            }

            let rotations: [Double] = [-31, 31, 89]
            let opacities: [Double] = [0.95, 0.72, 0.48]
            for (index, degrees) in rotations.enumerated() {
                let ellipseRect = CGRect(
                    x: center.x - rx,
                    y: center.y - ry,
                    width: rx * 2,
                    height: ry * 2
                )
                let rotation = degrees * .pi / 180
                let transform = CGAffineTransform(translationX: center.x, y: center.y)
                    .rotated(by: CGFloat(rotation))
                    .translatedBy(x: -center.x, y: -center.y)
                let path = Path(ellipseIn: ellipseRect).applying(transform)
                context.stroke(
                    path,
                    with: .color(tint.opacity(opacities[index])),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

                let t = index == 0 ? 0.28 : (index == 1 ? 2.90 : 1.42)
                let local = CGPoint(
                    x: center.x + rx * CGFloat(cos(t)),
                    y: center.y + ry * CGFloat(sin(t))
                )
                let cosine = CGFloat(cos(rotation))
                let sine = CGFloat(sin(rotation))
                let electron = CGPoint(
                    x: center.x + (local.x - center.x) * cosine - (local.y - center.y) * sine,
                    y: center.y + (local.x - center.x) * sine + (local.y - center.y) * cosine
                )
                let radius = max(1.6, canvasSize.width * 0.036)
                let rect = CGRect(
                    x: electron.x - radius,
                    y: electron.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(tint))
            }

            let nucleusOuter = CGRect(
                x: center.x - canvasSize.width * 0.075,
                y: center.y - canvasSize.width * 0.075,
                width: canvasSize.width * 0.15,
                height: canvasSize.width * 0.15
            )
            context.fill(Path(ellipseIn: nucleusOuter), with: .color(tint.opacity(0.32)))
            let nucleusInner = nucleusOuter.insetBy(dx: canvasSize.width * 0.035, dy: canvasSize.width * 0.035)
            context.fill(Path(ellipseIn: nucleusInner), with: .color(tint))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct BrandTile: View {
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(Color.primary)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.8)
                )
            AtomMark(
                size: size * 0.76,
                showsGlow: false,
                tint: Color(uiColor: .systemBackground)
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct BrandLockup: View {
    var markSize: CGFloat = 44
    var showsTagline: Bool = false

    var body: some View {
        HStack(spacing: 11) {
            BrandTile(size: markSize)
            VStack(alignment: .leading, spacing: 1) {
                Text("Physora")
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .tracking(-0.2)
                if showsTagline {
                    Text("ФИЗИКА · ЯСНО")
                        .font(.system(size: 8.5, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Physora")
    }
}

// MARK: - Native glass controls

struct GlassStatusPill: View {
    let title: String
    let systemImage: String
    var tint: Color = .physoraAccent
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { label }
                    .buttonStyle(.plain)
            } else {
                label
            }
        }
    }

    private var label: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .glassEffect(.regular.tint(tint.opacity(0.10)), in: Capsule())
    }
}

// MARK: - Utilities

@MainActor
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
