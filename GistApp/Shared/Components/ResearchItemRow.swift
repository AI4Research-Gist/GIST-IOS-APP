import SwiftUI

struct ResearchItemRow: View {
  @Environment(GistTheme.self) private var theme
  let item: ResearchItem

  var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.md) {
      Image(systemName: iconName)
        .foregroundStyle(iconColor)
        .frame(width: theme.spacing.xl)

      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        HStack(alignment: .firstTextBaseline) {
          Text(item.title.isEmpty ? "未命名资料" : item.title)
            .font(theme.fonts.headline)
            .foregroundStyle(theme.colors.textPrimary)
            .lineLimit(1)
          Spacer()
          if item.isStarred {
            Image(systemName: theme.icons.starSelected)
              .foregroundStyle(theme.colors.statusStarred)
          }
        }

        if let summary = item.summary, !summary.isEmpty {
          Text(summary)
            .font(theme.fonts.callout)
            .foregroundStyle(theme.colors.textSecondary)
            .lineLimit(2)
        }

        Text(metaText)
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.textTertiary)
          .lineLimit(1)

        if let project = item.projects?.first {
          Text(project.name)
            .font(theme.fonts.caption2)
            .foregroundStyle(theme.colors.accentSecondary)
            .lineLimit(1)
        }
      }
    }
    .padding(.vertical, theme.spacing.sm)
  }

  private var iconName: String {
    switch item.itemType {
    case .paper:
      theme.icons.paper
    case .article:
      theme.icons.article
    case .competition:
      theme.icons.competition
    case .voice:
      theme.icons.voice
    case .insight:
      theme.icons.insight
    }
  }

  private var iconColor: Color {
    switch item.itemType {
    case .competition:
      theme.colors.statusWarning
    case .insight:
      theme.colors.statusStarred
    case .voice:
      theme.colors.accentSecondary
    case .paper, .article:
      theme.colors.accentPrimary
    }
  }

  private var metaText: String {
    let source = item.sourceName ?? item.sourceURL ?? item.itemType.title
    return "\(source) · \(item.createdAt.formatted(.relative(presentation: .named)))"
  }
}
