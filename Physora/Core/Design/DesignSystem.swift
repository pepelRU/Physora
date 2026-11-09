import SwiftUI
import UIKit

// MARK: - Brand palette

extension Color {
    static let physoraAccent = Color(red: 56 / 255, green: 169 / 255, blue: 255 / 255)
    static let physoraAccentDeep = Color(red: 22 / 255, green: 122 / 255, blue: 214 / 255)
    static let physoraBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.027, green: 0.043, blue: 0.075, alpha: 1)
            : UIColor(red: 0.956, green: 0.973, blue: 0.992, alpha: 1)
    })
    static let physoraSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.067, green: 0.094, blue: 0.135, alpha: 1)
            : UIColor.white
    })
    static let physoraSurfaceMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.094, green: 0.129, blue: 0.180, alpha: 1)
            : UIColor(red: 0.925, green: 0.949, blue: 0.976, alpha: 1)
    })
    static let physoraStroke = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.09)
            : UIColor(red: 0.071, green: 0.125, blue: 0.192, alpha: 0.08)
    })
    static let physoraSeparator = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor(red: 0.071, green: 0.125, blue: 0.192, alpha: 0.10)
    })
    static let physoraMint = Color(red: 0.29, green: 0.83, blue: 0.66)
    static let physoraAmber = Color(red: 0.98, green: 0.66, blue: 0.28)

    static var physoraAccentSoft: Color { physoraAccent.opacity(0.12) }

    static var physoraAccentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.33, green: 0.80, blue: 1.0), physoraAccent, physoraAccentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Backgrounds and surfaces

struct PhysoraBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.physoraBackground
            RadialGradient(
                colors: [Color.physoraAccent.opacity(colorScheme == .dark ? 0.16 : 0.11), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 520
            )
            LinearGradient(
                colors: [.clear, Color.physoraAccent.opacity(colorScheme == .dark ? 0.035 : 0.05)],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

private struct PhysoraCardModifier: ViewModifier {
    var padding: CGFloat
    var cornerRadius: CGFloat
    var elevated: Bool
    @Environment(\.colorScheme) private var colorScheme

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
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(elevated ? 0.28 : 0.16)
                    : Color(red: 0.08, green: 0.20, blue: 0.34).opacity(elevated ? 0.09 : 0.045),
                radius: elevated ? 22 : 14,
                x: 0,
                y: elevated ? 10 : 6
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
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.11), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.13), lineWidth: 1))
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
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
                context.fill(Path(ellipseIn: glowRect), with: .color(Color.physoraAccent.opacity(0.16)))
            }

            let rotations: [Double] = [-31, 31, 89]
            let opacities: [Double] = [0.95, 0.80, 0.58]
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
                    with: .color(Color.physoraAccent.opacity(opacities[index])),
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
                context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.74, green: 0.93, blue: 1)))
            }

            let nucleusOuter = CGRect(
                x: center.x - canvasSize.width * 0.075,
                y: center.y - canvasSize.width * 0.075,
                width: canvasSize.width * 0.15,
                height: canvasSize.width * 0.15
            )
            context.fill(Path(ellipseIn: nucleusOuter), with: .color(Color.physoraAccent.opacity(0.38)))
            let nucleusInner = nucleusOuter.insetBy(dx: canvasSize.width * 0.035, dy: canvasSize.width * 0.035)
            context.fill(Path(ellipseIn: nucleusInner), with: .color(Color.white))
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
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.11, blue: 0.20),
                            Color(red: 0.02, green: 0.05, blue: 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                )
            AtomMark(size: size * 0.76, showsGlow: true)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.physoraAccent.opacity(0.25), radius: 10, y: 5)
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
