import SwiftUI

@MainActor
struct ExploreRootView: View {
  @Environment(GistTheme.self) private var theme
  @Environment(ResearchItemRepository.self) private var repository
  @Environment(GistToastCenter.self) private var toastCenter
  @State private var addedRecommendationKeys: Set<String> = []
  @State private var errorMessage: String?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.xxl) {
        Text("探索需要一些上下文")
          .font(theme.fonts.title2)
          .foregroundStyle(theme.colors.textPrimary)
        Text("添加论文、文章和项目后，这里会成为主动发现引擎。阶段 1 只保留最终入口骨架。")
          .font(theme.fonts.body)
          .foregroundStyle(theme.colors.textSecondary)
          .gistCard()
        recommendationSection(
          title: "相似论文推荐",
          reason: "因为你关注了注意力机制和长上下文阅读",
          recommendations: similarRecommendations
        )
        recommendationSection(
          title: "竞赛发现",
          reason: "基于你的研究项目，可能适合关注这些节点",
          recommendations: competitionRecommendations
        )
        if let errorMessage {
          Text(errorMessage)
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.statusWarning)
        }
      }
      .padding(theme.spacing.lg)
    }
    .background(theme.colors.bgPrimary)
    .navigationTitle("探索")
  }

  private func recommendationSection(
    title: String,
    reason: String,
    recommendations: [ResearchItem]
  ) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text(title)
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      Text(reason)
        .font(theme.fonts.footnote)
        .foregroundStyle(theme.colors.textTertiary)
      ForEach(recommendations) { recommendation in
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          Text(recommendation.title)
            .font(theme.fonts.body)
            .foregroundStyle(theme.colors.textPrimary)
          Text(recommendation.summary ?? recommendation.title)
            .font(theme.fonts.callout)
            .foregroundStyle(theme.colors.textSecondary)
            .lineLimit(2)
          HStack {
            Text(recommendation.sourceName ?? recommendation.itemType.title)
              .font(theme.fonts.footnote)
              .foregroundStyle(theme.colors.textTertiary)
            Spacer()
            Button(isAdded(recommendation) ? "已添加" : "添加到资料库") {
              addToLibrary(recommendation)
            }
            .disabled(isAdded(recommendation))
          }
        }
        .padding(.vertical, theme.spacing.sm)
      }
    }
    .gistCard()
  }

  private func addToLibrary(_ recommendation: ResearchItem) {
    let item = ResearchItem(title: recommendation.title, itemType: recommendation.itemType)
    item.summary = recommendation.summary
    item.sourceName = recommendation.sourceName
    item.sourceURL = recommendation.sourceURL
    if recommendation.itemType.rawValue == ResearchItemType.competition.rawValue {
      item.competitionStage = .collecting
    }
    do {
      try repository.create(item)
      addedRecommendationKeys.insert(recommendationKey(for: recommendation))
      toastCenter.show(message: "已添加「\(item.title)」", itemID: item.id)
      errorMessage = nil
    } catch {
      errorMessage = "添加推荐失败：\(error.localizedDescription)"
    }
  }

  private func isAdded(_ recommendation: ResearchItem) -> Bool {
    addedRecommendationKeys.contains(recommendationKey(for: recommendation))
  }

  private func recommendationKey(for recommendation: ResearchItem) -> String {
    "\(recommendation.itemType.rawValue)::\(recommendation.title)"
  }

  private var similarRecommendations: [ResearchItem] {
    let paper = ResearchItem(title: "Sparse Attention Survey", itemType: .paper)
    paper.summary = "梳理稀疏注意力、线性注意力和高效 Transformer 的代表性方法。"
    paper.sourceName = "arXiv"

    let article = ResearchItem(title: "Efficient Transformer Primer", itemType: .article)
    article.summary = "面向工程实现的高效 Transformer 阅读材料。"
    article.sourceName = "Blog"

    return [paper, article]
  }

  private var competitionRecommendations: [ResearchItem] {
    let competition = ResearchItem(title: "Research Demo Challenge", itemType: .competition)
    competition.summary = "围绕 AI 辅助科研流程的原型展示竞赛。"
    competition.sourceName = "Competition"
    return [competition]
  }
}
