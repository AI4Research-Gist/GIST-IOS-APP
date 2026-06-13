import SwiftUI

@MainActor
@Observable
final class GistTheme {
  let colors = GistThemeColors()
  let fonts = GistThemeFonts()
  let spacing = GistThemeSpacing()
  let radius = GistThemeRadius()
  let icons = GistThemeIcons()
}

struct GistThemeColors {
  let accentPrimary = Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)
  let accentSecondary = Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255)
  let accentTertiary = Color(red: 52 / 255, green: 211 / 255, blue: 153 / 255)

  let statusUnread = Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)
  let statusStarred = Color(red: 251 / 255, green: 191 / 255, blue: 36 / 255)
  let statusCompleted = Color(red: 156 / 255, green: 163 / 255, blue: 175 / 255)
  let statusWarning = Color(red: 248 / 255, green: 113 / 255, blue: 113 / 255)
  let statusAISummary = Color(red: 52 / 255, green: 211 / 255, blue: 153 / 255)
  let statusInProgress = Color(red: 167 / 255, green: 139 / 255, blue: 250 / 255)

  let textPrimary = Color(red: 249 / 255, green: 250 / 255, blue: 251 / 255)
  let textSecondary = Color(red: 209 / 255, green: 213 / 255, blue: 219 / 255)
  let textTertiary = Color(red: 107 / 255, green: 114 / 255, blue: 128 / 255)
  let textLink = Color(red: 96 / 255, green: 165 / 255, blue: 250 / 255)
  let textInverse = Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255)

  let bgPrimary = Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255)
  let bgSecondary = Color(red: 31 / 255, green: 41 / 255, blue: 55 / 255)
  let bgCard = Color(red: 55 / 255, green: 65 / 255, blue: 81 / 255)
  let bgSheet = Color(red: 31 / 255, green: 41 / 255, blue: 55 / 255)
  let bgInput = Color(red: 55 / 255, green: 65 / 255, blue: 81 / 255)
  let separator = Color(red: 75 / 255, green: 85 / 255, blue: 99 / 255)
  let borderLight = Color(red: 75 / 255, green: 85 / 255, blue: 99 / 255)
}

struct GistThemeFonts {
  let largeTitle = Font.largeTitle.bold()
  let title1 = Font.title.bold()
  let title2 = Font.title2.weight(.semibold)
  let title3 = Font.title3.weight(.medium)
  let headline = Font.headline.weight(.semibold)
  let body = Font.body
  let callout = Font.callout
  let subheadline = Font.subheadline
  let footnote = Font.footnote
  let caption1 = Font.caption.weight(.medium)
  let caption2 = Font.caption2
  let monospace = Font.body.monospaced()
}

struct GistThemeSpacing {
  let xs: CGFloat = 4
  let sm: CGFloat = 8
  let md: CGFloat = 12
  let lg: CGFloat = 16
  let xl: CGFloat = 20
  let xxl: CGFloat = 24
  let xxxl: CGFloat = 32
}

struct GistThemeRadius {
  let xs: CGFloat = 4
  let sm: CGFloat = 6
  let md: CGFloat = 10
  let lg: CGFloat = 14
  let xl: CGFloat = 20
  let full: CGFloat = 9999
}

struct GistThemeIcons {
  let home = "house"
  let homeSelected = "house.fill"
  let library = "books.vertical"
  let librarySelected = "books.vertical.fill"
  let explore = "sparkle.magnifyingglass"
  let add = "plus"
  let search = "magnifyingglass"
  let more = "ellipsis"
  let star = "star"
  let starSelected = "star.fill"
  let ai = "sparkles"
  let paper = "doc.text"
  let article = "newspaper"
  let competition = "trophy"
  let voice = "waveform"
  let insight = "lightbulb"
  let project = "folder"
  let tag = "tag"
}

struct GistCardModifier: ViewModifier {
  @Environment(GistTheme.self) private var theme

  func body(content: Content) -> some View {
    content
      .padding(theme.spacing.lg)
      .background(theme.colors.bgCard)
      .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
          .stroke(theme.colors.borderLight, lineWidth: 1)
      }
  }
}

extension View {
  func gistCard() -> some View {
    modifier(GistCardModifier())
  }
}
