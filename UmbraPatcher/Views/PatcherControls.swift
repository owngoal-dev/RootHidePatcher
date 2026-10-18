import SwiftUI

/// What the one control on the main screen does next.
enum MainAction: Equatable {
  case choose, convert, converting, export, retry
}

/// A place an exported package can go.
struct ExportRoute: Identifiable {
  let id: String
  let title: String
  let symbol: String
  let go: () -> Void
}

/// The main screen's one control, drawn as the package itself. Choosing and
/// converting happen on the one tile; on Export it divides, like a cell, into
/// a tile for each place the package can go.
struct PackageTile: View {
  let action: MainAction
  /// Where an exported package can go; empty until there is one.
  let routes: [ExportRoute]
  /// Export was tapped: the tile has divided into `routes`.
  let isSplit: Bool
  let perform: () -> Void
  @ScaledMetric private var side: CGFloat
  @State private var travel: CGFloat = 0

  private let gap: CGFloat = 16

  init(
    action: MainAction, routes: [ExportRoute], isSplit: Bool, side: CGFloat,
    perform: @escaping () -> Void
  ) {
    self.action = action
    self.routes = routes
    self.isSplit = isSplit
    self.perform = perform
    _side = ScaledMetric(wrappedValue: side, relativeTo: .headline)
  }

  var body: some View {
    ZStack {
      // A faint glow in the state's colour, behind the surface.
      Capsule()
        .fill(tint.opacity(0.11))
        .frame(width: (isSplit ? rowWidth : side) * 1.2, height: side * 1.2)
        .blur(radius: side * 0.28)
        .accessibilityHidden(true)
      if action == .export && !routes.isEmpty {
        ForEach(Array(routes.enumerated()), id: \.element.id) { index, route in
          cell(index, route)
        }
      } else {
        single
      }
    }
    .frame(width: max(side, isSplit ? rowWidth : side), height: side)
    .animation(.easeInOut(duration: 0.3), value: action)
  }

  // MARK: One tile

  private var single: some View {
    let shape = RoundedRectangle(cornerRadius: side * 0.22, style: .continuous)
    return Button(action: perform) {
      VStack(spacing: 14) {
        Image(systemName: symbol)
          .font(.system(size: side * 0.17, weight: .light))
          .foregroundColor(tint)
          .frame(height: side * 0.22)
        Text(title)
          .font(.headline)
          .foregroundColor(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .padding(20)
      .frame(width: side, height: side)
      .contentShape(Rectangle())
    }
    .buttonStyle(TilePressStyle(shape: shape))
    .background(surface(shape, shadowed: true))
    .overlay(shape.strokeBorder(tint.opacity(action == .choose ? 0.12 : 0.35), lineWidth: 0.5))
    .overlay(progress(shape))
    .disabled(action == .converting)
    .accessibilityLabel(Text(title))
  }

  // MARK: Divided tiles

  /// Each daughter tile starts as the whole tile, stacked under the first,
  /// then shrinks and moves to its place in the row.
  private func cell(_ index: Int, _ route: ExportRoute) -> some View {
    let count = CGFloat(routes.count)
    let size = isSplit ? cellSide : side
    let offset = isSplit ? (CGFloat(index) - (count - 1) / 2) * (cellSide + gap) : 0
    let shape = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
    return Button(action: isSplit ? route.go : perform) {
      ZStack {
        // The old label leaves at once; the new ones arrive as the tiles
        // settle, so two labels never cross.
        exportFace
          .opacity(isSplit || index != 0 ? 0 : 1)
          .animation(.easeOut(duration: 0.12).delay(isSplit ? 0 : 0.3), value: isSplit)
        routeFace(route)
          .opacity(isSplit ? 1 : 0)
          .animation(.easeOut(duration: 0.22).delay(isSplit ? 0.22 : 0), value: isSplit)
      }
      .frame(width: size, height: size)
      .contentShape(Rectangle())
    }
    .buttonStyle(TilePressStyle(shape: shape))
    // Stacked, only the top tile casts a shadow, so the pile reads as one.
    .background(surface(shape, shadowed: isSplit || index == 0))
    .overlay(shape.strokeBorder(tint.opacity(0.35), lineWidth: 0.5))
    .offset(x: offset)
    .zIndex(Double(routes.count - index))
    .accessibilityHidden(!isSplit && index != 0)
    .accessibilityLabel(isSplit ? Text(verbatim: route.title) : Text(title))
  }

  private var exportFace: some View {
    VStack(spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: side * 0.17, weight: .light))
        .foregroundColor(tint)
        .frame(height: side * 0.22)
      Text(title).font(.headline).foregroundColor(.primary)
    }
  }

  private func routeFace(_ route: ExportRoute) -> some View {
    VStack(spacing: 10) {
      Image(systemName: route.symbol)
        .font(.system(size: cellSide * 0.2, weight: .light))
        .foregroundColor(PatcherStyle.accent)
        .frame(height: cellSide * 0.26)
      Text(verbatim: route.title)
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
    .padding(10)
  }

  /// Daughters are smaller than the parent, and all fit the row.
  private var cellSide: CGFloat {
    let count = CGFloat(max(routes.count, 1))
    return min(side * 0.66, (side * 1.6 - gap * (count - 1)) / count)
  }

  private var rowWidth: CGFloat {
    let count = CGFloat(max(routes.count, 1))
    return cellSide * count + gap * (count - 1)
  }

  // MARK: Shared

  private func surface(_ shape: RoundedRectangle, shadowed: Bool) -> some View {
    shape
      .fill(PatcherStyle.card)
      .shadow(color: .black.opacity(shadowed ? 0.05 : 0), radius: 1, x: 0, y: 1)
      .shadow(color: .black.opacity(shadowed ? 0.08 : 0), radius: 22, x: 0, y: 12)
  }

  /// While converting, a short stroke travels the tile's edge.
  @ViewBuilder private func progress(_ shape: RoundedRectangle) -> some View {
    if action == .converting {
      let radius = side * 0.22
      let perimeter = 4 * (side - 2 * radius) + 2 * .pi * radius
      shape
        .stroke(
          tint,
          style: StrokeStyle(
            lineWidth: 2.5, lineCap: .round,
            dash: [perimeter * 0.18, perimeter * 0.82], dashPhase: travel)
        )
        .padding(1.25)
        .onAppear {
          travel = 0
          withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
            travel = -perimeter
          }
        }
        .accessibilityHidden(true)
    }
  }

  private var tint: Color {
    switch action {
    case .export: return PatcherStyle.success
    case .retry: return PatcherStyle.failure
    default: return PatcherStyle.accent
    }
  }

  private var symbol: String {
    switch action {
    case .choose, .converting: return "shippingbox"
    case .convert: return "arrow.triangle.2.circlepath"
    case .export: return "checkmark.circle"
    case .retry: return "exclamationmark.triangle"
    }
  }

  private var title: LocalizedStringKey {
    switch action {
    case .choose: return "Select Package"
    case .convert: return "Convert"
    case .converting: return "Converting…"
    case .export: return "Export"
    case .retry: return "Retry"
    }
  }
}

/// Pressing a tile sinks it slightly, as a physical key would.
private struct TilePressStyle: ButtonStyle {
  let shape: RoundedRectangle

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(shape.fill(Color.primary.opacity(configuration.isPressed ? 0.03 : 0)))
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// MARK: - Drawer

/// Everything besides the tile. Closed, a small pill at the foot of the
/// screen; open, the same shape grown into a floating card of options.
struct OptionsDrawer: View {
  @ObservedObject var session: ConversionSession
  @Binding var isOpen: Bool
  /// The card's height, known while it waits below the screen.
  @Binding var cardHeight: CGFloat
  let chooseAnother: () -> Void
  let showLog: () -> Void
  let showAbout: () -> Void
  @Namespace private var selection
  // Keep the displacement until the settling animation takes over. A
  // GestureState displacement would reset as soon as the finger lifts.
  @State private var drag: CGFloat = 0
  @GestureState private var isDragging = false
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  static let spring = Animation.spring(response: 0.42, dampingFraction: 0.84)

  /// The home indicator's inset and the card's shadow, beyond its height.
  private let travelMargin: CGFloat = 100

  var body: some View {
    ZStack(alignment: .bottom) {
      // The card is always there: closed, it waits just below the screen, so
      // opening and closing are one movement and nothing is built mid-way.
      card()
        .background(
          GeometryReader { proxy in
            Color.clear
              .onAppear { cardHeight = proxy.size.height }
              .onChange(of: proxy.size.height) { cardHeight = $0 }
          }
        )
        .offset(y: (isOpen ? 0 : cardHeight + travelMargin) + resistedDrag)
        .allowsHitTesting(isOpen)
        .accessibilityHidden(!isOpen)
      pill
        .opacity(isOpen ? 0 : 1)
        .allowsHitTesting(!isOpen)
        .accessibilityHidden(isOpen)
    }
    .onChange(of: isDragging) { active in
      // Cancellation does not call onEnded; return to the current resting state.
      if !active && drag != 0 { setOpen(isOpen) }
    }
  }

  private var resistedDrag: CGFloat { drag > 0 ? drag : drag * 0.15 }

  private var drawerDrag: some Gesture {
    // Measure against the screen so moving the card does not move the gesture's origin.
    DragGesture(minimumDistance: 10, coordinateSpace: .global)
      .updating($isDragging) { _, active, _ in active = true }
      .onChanged { value in
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { drag = value.translation.height }
      }
      .onEnded { value in
        let travel = value.predictedEndTranslation.height
        let open = isOpen
          ? !(value.translation.height > 90 || travel > 220)
          : travel < -40
        setOpen(open)
      }
  }

  // MARK: Closed

  private var pill: some View {
    Button {
      setOpen(true)
    } label: {
      HStack(spacing: 6) {
        Text(session.mode.title)
        Image(systemName: "chevron.up").font(.caption2.weight(.bold))
      }
      .font(.footnote.weight(.semibold))
      .foregroundColor(.secondary)
      .padding(.horizontal, 16)
      .frame(minHeight: 36)
      .background(
        Capsule()
          .fill(PatcherStyle.card)
          .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
      )
      .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .highPriorityGesture(drawerDrag)
    // A short pull upward reads as the start of opening.
    .offset(y: min(max(drag * 0.25, -10), 0))
    .padding(.bottom, 12)
    .accessibilityLabel(Text("Conversion Method"))
    .accessibilityValue(Text(session.mode.title))
    .accessibilityHint(Text("Shows the options."))
  }

  // MARK: Open

  private func card() -> some View {
    VStack(spacing: 0) {
      grabber
      Group {
        if verticalSizeClass == .compact {
          // A phone on its side: options and actions side by side, to keep it low.
          HStack(alignment: .center, spacing: 20) {
            modes()
            separator.frame(width: 1).padding(.vertical, 6)
            actions.frame(width: 252)
          }
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: 700)
        } else {
          VStack(spacing: 18) {
            modes()
            separator.frame(height: 1).padding(.horizontal, 10)
            actions
          }
          .frame(maxWidth: 420)
        }
      }
      .padding(.horizontal, 10)
      .padding(.bottom, verticalSizeClass == .compact ? 14 : 20)
    }
    .background(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .fill(PatcherStyle.card)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .shadow(color: .black.opacity(0.12), radius: 30, x: 0, y: 14)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.5)
    )
    .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    // Drags starting on a row or an action belong to the panel; taps still
    // reach the buttons when the drag's minimum distance is not met.
    .highPriorityGesture(drawerDrag)
    .padding(.horizontal, 12)
    .padding(.bottom, 8)
    .accessibilityAction(.escape) { setOpen(false) }
  }

  /// Only a hint that the card can be pulled away; the whole card is the handle.
  private var grabber: some View {
    Capsule()
      .fill(Color.primary.opacity(0.14))
      .frame(width: 32, height: 4)
      .padding(.top, 8)
      .padding(.bottom, 10)
      .accessibilityHidden(true)
  }

  private var separator: some View {
    Rectangle().fill(Color.primary.opacity(0.06)).accessibilityHidden(true)
  }

  /// One row per mode; the selection is a soft plate that slides between them.
  private func modes() -> some View {
    VStack(spacing: 2) {
      ForEach(ConversionMode.allCases) { mode in
        let selected = session.mode == mode
        Button {
          guard !selected else { return }
          UISelectionFeedbackGenerator().selectionChanged()
          withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) { session.mode = mode }
        } label: {
          HStack {
            Text(mode.title)
              .font(.body)
              .foregroundColor(selected ? PatcherStyle.accent : .primary)
            Spacer(minLength: 8)
            Image(systemName: "checkmark.circle.fill")
              .font(.title3)
              .foregroundColor(PatcherStyle.accent)
              .opacity(selected ? 1 : 0)
              .scaleEffect(selected ? 1 : 0.6)
              .accessibilityHidden(true)
          }
          .padding(.horizontal, 12)
          .frame(minHeight: 50)
          .background {
            if selected {
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PatcherStyle.accent.opacity(0.1))
                .matchedGeometryEffect(id: "plate", in: selection)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(session.isConverting)
        .opacity(session.isConverting ? 0.5 : 1)
        .accessibilityAddTraits(selected ? .isSelected : [])
      }
    }
  }

  /// The ways out of the drawer, as a row of round controls. All three are
  /// always there, so the row never shifts; one that cannot be used is dimmed.
  private var actions: some View {
    HStack(alignment: .top, spacing: 0) {
      ActionChip(
        title: "File", label: "Choose Another File", symbol: "doc.badge.plus",
        action: chooseAnother
      )
      .disabled(session.isConverting)
      ActionChip(title: "Log", label: "Conversion Log", symbol: "text.alignleft", action: showLog)
        .disabled(session.result == nil)
      ActionChip(title: "About", label: "About Patcher", symbol: "info", action: showAbout)
    }
  }

  private func setOpen(_ open: Bool) {
    withAnimation(Self.spring) {
      isOpen = open
      drag = 0
    }
  }
}

/// A round control with a one-word name under it; `label` is the full name
/// VoiceOver reads.
private struct ActionChip: View {
  let title: LocalizedStringKey
  let label: LocalizedStringKey
  let symbol: String
  let action: () -> Void
  @Environment(\.isEnabled) private var isEnabled

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Image(systemName: symbol)
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(isEnabled ? PatcherStyle.accent : Color(uiColor: .tertiaryLabel))
          .frame(width: 50, height: 50)
          .background(Circle().fill(PatcherStyle.well))
        Text(title)
          .font(.caption)
          .foregroundColor(isEnabled ? .secondary : Color(uiColor: .tertiaryLabel))
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
    }
    .buttonStyle(ChipPressStyle())
    .accessibilityLabel(Text(label))
  }
}

private struct ChipPressStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.92 : 1)
      .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
  }
}
