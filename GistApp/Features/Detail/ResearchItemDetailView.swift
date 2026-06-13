import SwiftUI

@MainActor
struct ResearchItemDetailView: View {
  @Environment(GistTheme.self) private var theme
  @Environment(ResearchItemRepository.self) private var repository
  @Environment(GistSheetManager.self) private var sheetManager
  let itemID: UUID
  @State private var item: ResearchItem?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.spacing.xxl) {
        Text(item?.title ?? "资料详情")
          .font(theme.fonts.largeTitle)
          .foregroundStyle(theme.colors.textPrimary)
        Text(summaryText)
          .font(theme.fonts.body)
          .foregroundStyle(theme.colors.textSecondary)
        metadataSection
        section(title: "正文阅读", message: item?.fullText ?? "暂无正文。阶段 1 保留正文入口。")
        section(title: "结构化阅读卡", message: structuredCardText)
        section(title: "AI 解读", message: aiText)
        typeSpecificSection
        projectAndTagsSection
        section(title: "用户笔记", message: item?.userNotes ?? "暂无个人笔记。")
      }
      .padding(theme.spacing.lg)
    }
    .background(theme.colors.bgPrimary)
    .navigationTitle("详情")
    .task {
      item = repository.findByID(itemID)
      if let item {
        item.lastOpenedAt = Date()
        try? repository.update(item)
      }
    }
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          toggleStar()
        } label: {
          Image(systemName: item?.isStarred == true ? theme.icons.starSelected : theme.icons.star)
        }
        Menu {
          Button("移至项目") {}
          Button("修改标签") {}
          Button("触发 AI 解读") {
            sheetManager.present(.aiInterpretation(itemID: itemID))
          }
          Button("复制链接") {}
          Button("删除", role: .destructive) {}
        } label: {
          Image(systemName: theme.icons.more)
        }
      }
    }
  }

  private var summaryText: String {
    guard let item else { return "未找到这条资料。" }
    return item.summary ?? "\(item.itemType.title) · \(item.sourceName ?? item.sourceURL ?? "本地资料")"
  }

  private var structuredCardText: String {
    guard let item else { return "未找到结构化信息。" }
    let fields = [
      ("研究问题", item.researchQuestion),
      ("方法", item.methodology),
      ("数据集", item.datasetInfo),
      ("关键发现", item.keyFindings),
      ("局限性", item.limitations),
      ("可复用点", item.reusePoints),
    ]
    let filled = fields.compactMap { pair -> String? in
      let (title, value) = pair
      guard let value, !value.isEmpty else { return nil }
      return "\(title)：\(value)"
    }
    return filled.isEmpty ? "结构化阅读卡默认展开，等待手动填写或 mock AI 填充。" : filled.joined(separator: "\n")
  }

  private var aiText: String {
    item?.aiInterpretationResult ?? "未解读。AI 解读入口保留在正文和结构化阅读卡之后。"
  }

  @ViewBuilder
  private var metadataSection: some View {
    if let item {
      VStack(alignment: .leading, spacing: theme.spacing.sm) {
        infoRow("类型", item.itemType.title)
        infoRow("来源", item.sourceName ?? item.sourceURL ?? "本地资料")
        infoRow("阅读状态", item.readingStatusRaw)
        infoRow("添加时间", item.createdAt.formatted(.dateTime.month().day().hour().minute()))
        if let progress = item.readingProgress {
          infoRow("阅读进度", "\(Int(progress * 100))%")
        }
      }
      .gistCard()
    }
  }

  @ViewBuilder
  private var typeSpecificSection: some View {
    if let item {
      switch item.itemType {
      case .paper:
        paperSection(item)
      case .article:
        articleSection(item)
      case .competition:
        competitionSection(item)
      case .voice:
        voiceSection(item)
      case .insight:
        insightSection(item)
      }
    }
  }

  @ViewBuilder
  private var projectAndTagsSection: some View {
    if let item {
      VStack(alignment: .leading, spacing: theme.spacing.sm) {
        Text("项目与标签")
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
        if let projects = item.projects, !projects.isEmpty {
          ForEach(projects, id: \.id) { project in
            Label(project.name, systemImage: theme.icons.project)
              .font(theme.fonts.callout)
              .foregroundStyle(theme.colors.textSecondary)
          }
        } else {
          Text("尚未归入项目。")
            .font(theme.fonts.callout)
            .foregroundStyle(theme.colors.textSecondary)
        }
        if let tags = item.tags, !tags.isEmpty {
          Text(tags.map(\.name).joined(separator: " · "))
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.accentPrimary)
        }
      }
      .gistCard()
    }
  }

  private func toggleStar() {
    guard let item else { return }
    item.isStarred.toggle()
    try? repository.update(item)
    self.item = item
  }

  private func section(title: String, message: String) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(title)
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      Text(message)
        .font(theme.fonts.callout)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .gistCard()
  }

  private func paperSection(_ item: ResearchItem) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("论文信息")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      infoRow("作者", item.authors?.joined(separator: ", ") ?? "未填写")
      infoRow("会议/期刊", item.publicationVenue ?? "未填写")
      infoRow("年份", item.publicationYear.map(String.init) ?? "未填写")
      infoRow("DOI", item.doi ?? "未填写")
      infoRow("arXiv", item.arxivID ?? "未填写")
    }
    .gistCard()
  }

  private func articleSection(_ item: ResearchItem) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("文章来源")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      infoRow("站点", item.sourceName ?? "未填写")
      infoRow("链接", item.sourceURL ?? "未填写")
    }
    .gistCard()
  }

  private func competitionSection(_ item: ResearchItem) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("竞赛节点")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      infoRow("截止时间", item.competitionDeadline?.formatted(.dateTime.month().day().hour().minute()) ?? "未设置")
      infoRow("阶段", item.competitionStageRaw ?? "未设置")
      infoRow("提交材料", item.competitionSubmissionItems?.joined(separator: "、") ?? "未填写")
      infoRow("评分要点", item.competitionScoringPoints?.joined(separator: "、") ?? "未填写")
    }
    .gistCard()
  }

  private func voiceSection(_ item: ResearchItem) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("语音记录")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      infoRow("时长", item.voiceDuration.map { "\($0) 秒" } ?? "未记录")
      Text(item.voiceTranscript ?? "暂无转写文本。")
        .font(theme.fonts.callout)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .gistCard()
  }

  private func insightSection(_ item: ResearchItem) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("灵感内容")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      Text(item.summary ?? item.title)
        .font(theme.fonts.callout)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .gistCard()
  }

  private func infoRow(_ title: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(theme.fonts.footnote)
        .foregroundStyle(theme.colors.textTertiary)
      Spacer()
      Text(value)
        .font(theme.fonts.footnote)
        .foregroundStyle(theme.colors.textSecondary)
        .multilineTextAlignment(.trailing)
    }
  }
}
