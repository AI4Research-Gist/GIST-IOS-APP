import SwiftUI

struct GistToastOverlayView: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistNavigationRouter.self) private var router
  @Environment(GistToastCenter.self) private var toastCenter

  var body: some View {
    if let toast = toastCenter.current {
      HStack(spacing: theme.spacing.md) {
        Text(toast.message)
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.textPrimary)
          .lineLimit(2)
        Spacer(minLength: theme.spacing.sm)
        if let itemID = toast.itemID {
          Button("查看") {
            router.navigateToItem(itemID)
            toastCenter.dismiss()
          }
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.textLink)
        }
        Button {
          toastCenter.dismiss()
        } label: {
          Image(systemName: "xmark")
            .font(theme.fonts.caption1)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.colors.textTertiary)
      }
      .padding(theme.spacing.md)
      .background(theme.colors.bgCard)
      .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
          .stroke(theme.colors.borderLight, lineWidth: 1)
      }
      .padding(theme.spacing.lg)
      .transition(.move(edge: .top).combined(with: .opacity))
      .accessibilityElement(children: .combine)
      .accessibilityLabel(toast.message)
    }
  }
}
