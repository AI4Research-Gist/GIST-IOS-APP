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
        if let destination = toast.destination {
          Button(toastActionLabel(for: toast)) {
            handleToastAction(destination)
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

  @MainActor
  private func handleToastAction(_ destination: GistToastDestination) {
    switch destination {
    case .item(let itemID):
      router.navigateToItem(itemID)
    case .project(let projectID):
      router.navigateToProject(projectID)
    }
  }

  private func toastActionLabel(for toast: GistToast) -> String {
    if let actionLabel = toast.actionLabel {
      return actionLabel
    }

    return switch toast.destination {
    case .item:
      "查看"
    case .project:
      "看项目"
    case nil:
      "查看"
    }
  }
}
