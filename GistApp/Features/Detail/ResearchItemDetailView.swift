import SwiftUI

@MainActor
struct ResearchItemDetailView: View {
  @Environment(GistTheme.self) private var theme
  @Environment(ResearchItemRepository.self) private var repository
  @Environment(ProjectRepository.self) private var projectRepository
  @Environment(GistNavigationRouter.self) private var router
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(GistToastCenter.self) private var toastCenter
  @Environment(GistDataChangeCenter.self) private var dataChangeCenter
  let itemID: UUID
  @State private var item: ResearchItem?
  @State private var didMarkOpened = false

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
        structuredCardSection
        aiInterpretationSection
        typeSpecificSection
        projectAndTagsSection
        section(title: "用户笔记", message: item?.userNotes ?? "暂无个人笔记。")
      }
      .padding(theme.spacing.lg)
    }
    .background(theme.colors.bgPrimary)
    .navigationTitle("详情")
    .task(id: dataChangeCenter.revision) {
      item = repository.findByID(itemID)
      if let item, !didMarkOpened {
        item.lastOpenedAt = Date()
        try? repository.update(item)
        didMarkOpened = true
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
          if let item {
            projectAssignmentMenu(for: item)
          }
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
    let fields = structuredCardFields(from: item)
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

  private var structuredCardSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      HStack {
        Text("结构化阅读卡")
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        Button("AI 填充") {
          sheetManager.present(.aiInterpretation(itemID: itemID))
        }
        .font(theme.fonts.footnote)
        .foregroundStyle(theme.colors.textLink)
      }
      Text(structuredCardText)
        .font(theme.fonts.callout)
        .foregroundStyle(theme.colors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .gistCard()
  }

  private var aiInterpretationSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      HStack {
        Text("AI 解读")
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        Button("打开工作台") {
          sheetManager.present(.aiInterpretation(itemID: itemID))
        }
        .font(theme.fonts.footnote)
        .foregroundStyle(theme.colors.textLink)
      }
      Text(aiText)
        .font(theme.fonts.callout)
        .foregroundStyle(theme.colors.textSecondary)
      if let latestArtifact = item?.storedArtifacts.first {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("最新深度稿：\(latestArtifact.title)")
            .font(theme.fonts.footnote.weight(.semibold))
            .foregroundStyle(theme.colors.textPrimary)
          Text(latestArtifact.paperArtifact.oneSentenceSummary ?? "已沉淀到项目科研产出中心。")
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.textSecondary)
          Button("前往关联项目") {
            if let projectID = item?.projects?.first?.id {
              router.navigateToProject(projectID)
            }
          }
          .font(theme.fonts.caption1)
          .foregroundStyle(theme.colors.textLink)
        }
        .padding(.top, theme.spacing.xs)
      }
    }
    .gistCard()
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
            Button {
              router.navigateToProject(project.id)
            } label: {
              Label(project.name, systemImage: theme.icons.project)
                .font(theme.fonts.callout)
                .foregroundStyle(theme.colors.textSecondary)
            }
            .buttonStyle(.plain)
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

  @ViewBuilder
  private func projectAssignmentMenu(for item: ResearchItem) -> some View {
    let projects = (try? projectRepository.fetchAll()) ?? []
    if projects.isEmpty {
      Button("新建项目") {
        sheetManager.present(.editProject(projectID: nil))
      }
    } else {
      Menu("移至项目") {
        ForEach(projects, id: \.id) { project in
          let alreadyAssigned = item.projects?.contains(where: { $0.id == project.id }) ?? false
          Button(alreadyAssigned ? "\(project.name) · 已归属" : project.name) {
            guard !alreadyAssigned else { return }
            assign(item: item, to: project)
          }
        }
      }
    }
  }

  private func assign(item: ResearchItem, to project: Project) {
    var projects = item.projects ?? []
    guard !projects.contains(where: { $0.id == project.id }) else { return }
    projects.append(project)
    item.projects = projects
    try? repository.update(item)
    toastCenter.show(message: "已归入项目「\(project.name)」", projectID: project.id)
    self.item = item
  }

  private func structuredCardFields(from item: ResearchItem) -> [(String, String?)] {
    let decodedCard = item.structuredCardResult
    return [
      ("研究问题", decodedCard?.researchQuestion?.content ?? item.researchQuestion),
      ("方法", decodedCard?.methodology?.content ?? item.methodology),
      ("数据集", decodedCard?.datasetInfo?.content ?? item.datasetInfo),
      ("关键发现", decodedCard?.keyFindings?.content ?? item.keyFindings),
      ("局限性", decodedCard?.limitations?.content ?? item.limitations),
      ("可复用点", decodedCard?.reusePoints?.content ?? item.reusePoints),
    ]
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

@MainActor
struct AIInterpretationWorkspace: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(GistNavigationRouter.self) private var router
  @Environment(ResearchItemRepository.self) private var repository
  @Environment(ProjectRepository.self) private var projectRepository
  @Environment(GistToastCenter.self) private var toastCenter
  @Environment(\.modelContext) private var modelContext
  let itemID: UUID

  @State private var item: ResearchItem?
  @State private var statusMessage = "可生成结构化阅读卡与深度解读稿。"
  @State private var isGeneratingCard = false
  @State private var isGeneratingArtifact = false
  @State private var generatedArtifact: StoredAIArtifact?
  @State private var artifactCache: PaperResearchArtifactCache?
  @State private var availableProjects: [Project] = []
  @State private var selectedProjectID: UUID?
  private let aiClient = AITaskClient.shared

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
          Text(item?.title ?? "AI 工作台")
            .font(theme.fonts.title2)
            .foregroundStyle(theme.colors.textPrimary)

          VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("结构化阅读卡")
              .font(theme.fonts.headline)
              .foregroundStyle(theme.colors.textPrimary)
            Text(item?.structuredCardResult == nil ? "当前还没有结构化阅读卡。" : "已有阅读卡，可再次用 mock AI 补齐字段。")
              .font(theme.fonts.callout)
              .foregroundStyle(theme.colors.textSecondary)
            Button(isGeneratingCard ? "生成中..." : "生成结构化阅读卡") {
              generateStructuredCard()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGeneratingCard || item == nil)
          }
          .gistCard()

          VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("论文深度稿")
              .font(theme.fonts.headline)
              .foregroundStyle(theme.colors.textPrimary)
            Text("对重要论文生成一份可进入项目页“科研产出中心”的深度解读稿。")
              .font(theme.fonts.callout)
              .foregroundStyle(theme.colors.textSecondary)

            if item?.itemType == .paper {
              projectBindingSection
            }

            Button(isGeneratingArtifact ? "生成中..." : "生成深度解读稿") {
              generateArtifact()
            }
            .buttonStyle(.borderedProminent)
            .disabled(
              isGeneratingArtifact || item == nil || item?.itemType != .paper || selectedProjectID == nil
            )

            if item?.itemType != .paper {
              Text("当前只有论文类型支持深度稿生成。")
                .font(theme.fonts.caption2)
                .foregroundStyle(theme.colors.textTertiary)
            } else if selectedProjectID == nil {
              Text("请先为这篇论文选择归属项目，再生成深度稿。")
                .font(theme.fonts.caption2)
                .foregroundStyle(theme.colors.statusWarning)
            }

            if let generatedArtifact {
              VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text(generatedArtifact.title)
                  .font(theme.fonts.footnote.weight(.semibold))
                  .foregroundStyle(theme.colors.textPrimary)
                Text(generatedArtifact.paperArtifact.oneSentenceSummary ?? generatedArtifact.title)
                  .font(theme.fonts.footnote)
                  .foregroundStyle(theme.colors.textSecondary)
                if let projectID = item?.projects?.first?.id {
                  Button("前往项目科研产出中心") {
                    sheetManager.dismiss()
                    router.navigateToProject(projectID)
                  }
                  .font(theme.fonts.caption1)
                  .foregroundStyle(theme.colors.textLink)
                }
              }
            }
          }
          .gistCard()

          Text(statusMessage)
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.textTertiary)
        }
        .padding(theme.spacing.lg)
      }
      .background(theme.colors.bgSheet)
      .navigationTitle("AI 工作台")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("关闭") {
            sheetManager.dismiss()
          }
        }
      }
      .task {
        loadContext()
      }
    }
  }

  private var projectBindingSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("产出归属项目")
        .font(theme.fonts.footnote.weight(.semibold))
        .foregroundStyle(theme.colors.textPrimary)

      if availableProjects.isEmpty {
        Text("当前还没有可选项目，请先回到资料详情或资料库创建项目。")
          .font(theme.fonts.caption2)
          .foregroundStyle(theme.colors.textTertiary)
      } else {
        Picker("项目", selection: $selectedProjectID) {
          Text("请选择项目").tag(nil as UUID?)
          ForEach(availableProjects, id: \.id) { project in
            Text(project.name).tag(project.id as UUID?)
          }
        }

        Button("保存项目归属") {
          assignSelectedProjectIfNeeded(showToast: true)
        }
        .font(theme.fonts.caption1)
        .foregroundStyle(theme.colors.textLink)
        .disabled(selectedProjectID == nil)
      }
    }
  }

  private func loadContext() {
    item = repository.findByID(itemID)
    availableProjects = (try? projectRepository.fetchAll()) ?? []
    if selectedProjectID == nil {
      selectedProjectID = item?.projects?.first?.id
    }
  }

  private func generateStructuredCard() {
    guard let item else { return }
    isGeneratingCard = true
    statusMessage = "正在用 mock AITask 生成结构化阅读卡..."

    Task { @MainActor in
      defer { isGeneratingCard = false }
      do {
        let result = try await aiClient.generateStructuredCard(for: item)
        item.structuredCardResult = result
        item.researchQuestion = result.researchQuestion?.content
        item.methodology = result.methodology?.content
        item.datasetInfo = result.datasetInfo?.content
        item.keyFindings = result.keyFindings?.content
        item.limitations = result.limitations?.content
        item.reusePoints = result.reusePoints?.content
        item.aiInterpretationStatus = .completed
        item.aiInterpretationDate = Date()
        item.aiInterpretationResult = "已由 mock AITask 生成结构化阅读卡，可用于项目聚合与后续深度稿。"
        try repository.update(item)
        self.item = repository.findByID(itemID)
        statusMessage = "结构化阅读卡已写入本地数据。"
      } catch {
        statusMessage = "生成失败：\(error.localizedDescription)"
      }
    }
  }

  private func generateArtifact() {
    guard let item else { return }
    guard item.itemType == .paper else {
      statusMessage = "当前只有论文类型支持深度稿生成。"
      return
    }
    guard selectedProjectID != nil else {
      statusMessage = "请先为这篇论文选择归属项目，再生成深度稿。"
      return
    }

    assignSelectedProjectIfNeeded(showToast: false)
    guard let refreshedItem = repository.findByID(itemID) else {
      statusMessage = "未找到论文资料。"
      return
    }

    isGeneratingArtifact = true
    statusMessage = "正在生成论文深度稿，并准备写入项目科研产出中心..."

    Task { @MainActor in
      defer { isGeneratingArtifact = false }
      do {
        let envelope = try await aiClient.generatePaperArtifact(for: refreshedItem)
        let artifact = StoredAIArtifact(
          kind: .paperDeepDive,
          sourceItemID: refreshedItem.id,
          sourceItemTitle: refreshedItem.title,
          title: envelope.title,
          createdAt: Date(),
          markdownContent: envelope.markdownContent,
          paperArtifact: envelope.structuredJSON
        )
        refreshedItem.appendStoredArtifact(artifact)
        refreshedItem.aiInterpretationStatus = .completed
        refreshedItem.aiInterpretationResult = envelope.structuredJSON.oneSentenceSummary ?? "已生成论文深度稿。"
        refreshedItem.aiInterpretationDate = Date()
        let cache = artifactCache ?? PaperResearchArtifactCache()
        cache.sourceItemID = refreshedItem.id
        cache.projectID = selectedProjectID ?? refreshedItem.projects?.first?.id
        cache.title = envelope.title
        cache.artifactTypeRaw = envelope.artifactType
        cache.markdownContent = envelope.markdownContent
        cache.structuredJSON = encodeJSONString(envelope.structuredJSON)
        cache.statusRaw = "draft"
        cache.generatedAt = Date()
        cache.updatedAt = Date()
        if artifactCache == nil {
          modelContext.insert(cache)
        }
        artifactCache = cache
        try repository.update(refreshedItem)
        try? modelContext.save()
        generatedArtifact = artifact
        self.item = repository.findByID(itemID)
        statusMessage = "深度稿已保存，可在项目页科研产出中心查看。"
      } catch {
        statusMessage = "生成失败：\(error.localizedDescription)"
      }
    }
  }

  private func assignSelectedProjectIfNeeded(showToast: Bool) {
    guard let selectedProjectID, let item else { return }
    guard let project = projectRepository.findByID(selectedProjectID) else {
      statusMessage = "未找到所选项目。"
      return
    }

    var projects = item.projects ?? []
    if projects.contains(where: { $0.id == project.id }) {
      if showToast {
        statusMessage = "这篇论文已归入项目「\(project.name)」。"
      }
      return
    }

    projects.append(project)
    item.projects = projects

    do {
      try repository.update(item)
      self.item = repository.findByID(itemID)
      statusMessage = "已将论文归入项目「\(project.name)」，可继续生成深度稿。"
      if showToast {
        toastCenter.show(message: "已归入项目「\(project.name)」", projectID: project.id)
      }
    } catch {
      statusMessage = "保存项目归属失败：\(error.localizedDescription)"
    }
  }
}
