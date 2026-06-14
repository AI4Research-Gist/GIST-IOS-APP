import SwiftUI
#if canImport(UIKit)
  import UIKit
#endif

@MainActor
struct NewItemSheet: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(GistToastCenter.self) private var toastCenter
  @Environment(ResearchItemRepository.self) private var repository
  @Environment(ProjectRepository.self) private var projectRepository
  let initialProjectID: UUID?
  @State private var selectedType: ResearchItemType?
  @State private var title = ""
  @State private var summary = ""
  @State private var sourceURL = ""
  @State private var sourceName = ""
  @State private var authors = ""
  @State private var publicationVenue = ""
  @State private var publicationYear = ""
  @State private var doi = ""
  @State private var arxivID = ""
  @State private var competitionSubmissionItems = ""
  @State private var competitionScoringPoints = ""
  @State private var rawCompetitionNotice = ""
  @State private var voiceDuration = ""
  @State private var projects: [Project] = []
  @State private var selectedProjectID: UUID?
  @State private var competitionDeadline = Date()
  @State private var hasCompetitionDeadline = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Group {
        if let selectedType {
          form(for: selectedType)
        } else {
          typeList
        }
      }
      .background(theme.colors.bgSheet)
      .navigationTitle(selectedType == nil ? "新增资料" : selectedType?.title ?? "新增")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(selectedType == nil ? "关闭" : "返回") {
            if selectedType == nil {
              sheetManager.dismiss()
            } else {
              self.selectedType = nil
            }
          }
        }
      }
    }
  }

  private var typeList: some View {
    List {
      typeRow(.paper, icon: theme.icons.paper, description: "通过 DOI / URL / arXiv 添加论文")
      typeRow(.article, icon: theme.icons.article, description: "粘贴链接保存网页文章")
      typeRow(.insight, icon: theme.icons.insight, description: "快速记录一闪而过的想法")
      typeRow(.competition, icon: theme.icons.competition, description: "记录比赛信息和截止时间")
      typeRow(.voice, icon: theme.icons.voice, description: "录制语音并保存为资料")
      Section("快速入口") {
        Button {
          createFromClipboard()
        } label: {
          Label("从剪贴板快速创建", systemImage: "doc.on.clipboard")
        }
      }
      if let errorMessage {
        Text(errorMessage)
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.statusWarning)
      }
    }
    .scrollContentBackground(.hidden)
  }

  private func typeRow(
    _ type: ResearchItemType,
    icon: String,
    description: String
  ) -> some View {
    Button {
      selectedType = type
    } label: {
      HStack(spacing: theme.spacing.md) {
        Image(systemName: icon)
          .foregroundStyle(theme.colors.accentPrimary)
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text(type.title)
            .font(theme.fonts.headline)
            .foregroundStyle(theme.colors.textPrimary)
          Text(description)
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.textSecondary)
        }
      }
    }
  }

  private func form(for type: ResearchItemType) -> some View {
    Form {
      Text("\(type.title)表单")
        .font(theme.fonts.title2)
        .foregroundStyle(theme.colors.textPrimary)

      Section("基础信息") {
        if type == .insight {
          TextField("写下你的想法", text: $summary, axis: .vertical)
        } else {
          TextField("标题", text: $title, axis: .vertical)
          TextField("摘要 / 备注", text: $summary, axis: .vertical)
        }
        if type == .paper || type == .article || type == .competition {
          TextField("URL / DOI / 来源", text: $sourceURL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        if type == .article {
          TextField("来源名称", text: $sourceName)
        }
      }

      Section("归属项目") {
        Picker("项目", selection: $selectedProjectID) {
          Text("不选择项目").tag(nil as UUID?)
          ForEach(projects, id: \.id) { project in
            Text(project.name).tag(project.id as UUID?)
          }
        }
      }

      if type == .paper {
        Section("论文信息") {
          TextField("作者，用逗号分隔", text: $authors)
          TextField("会议 / 期刊", text: $publicationVenue)
          TextField("发表年份", text: $publicationYear)
            .keyboardType(.numberPad)
          TextField("DOI", text: $doi)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          TextField("arXiv ID", text: $arxivID)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        Section("论文能力占位") {
          Button("获取信息") {}
          Text("真实 DOI / arXiv / URL 元数据补全在后续阶段接入。")
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.textSecondary)
        }
      }

      if type == .competition {
        Section("从比赛通知提取") {
          TextField("粘贴比赛通知 / 报名说明 / 截止时间文本", text: $rawCompetitionNotice, axis: .vertical)
          Button("AI 抽取并进入审查页") {
            let seedText = rawCompetitionNotice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              ? summary
              : rawCompetitionNotice
            sheetManager.present(
              .competitionReview(
                projectID: selectedProjectID,
                rawText: seedText,
                sourceURL: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sourceURL
              )
            )
          }
        }

        Section("竞赛节点") {
          Toggle("设置截止时间", isOn: $hasCompetitionDeadline)
          if hasCompetitionDeadline {
            DatePicker("截止时间", selection: $competitionDeadline)
          }
          TextField("提交材料，用逗号分隔", text: $competitionSubmissionItems, axis: .vertical)
          TextField("评分要点，用逗号分隔", text: $competitionScoringPoints, axis: .vertical)
        }
      }

      if type == .voice {
        Section("语音信息") {
          TextField("录音时长（秒，可选）", text: $voiceDuration)
            .keyboardType(.decimalPad)
        }
      }

      if let errorMessage {
        Text(errorMessage)
          .foregroundStyle(theme.colors.statusWarning)
      }

      Button("保存") {
        save(type)
      }
      .buttonStyle(.borderedProminent)
    }
    .scrollContentBackground(.hidden)
    .task {
      loadProjects()
    }
  }

  private func save(_ type: ResearchItemType) {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedURL = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedTitle.isEmpty || type == .insight && !trimmedSummary.isEmpty else {
      errorMessage = "请先填写标题或内容。"
      return
    }

    let item = ResearchItem(
      title: trimmedTitle.isEmpty ? String(trimmedSummary.prefix(30)) : trimmedTitle,
      itemType: type
    )
    item.summary = trimmedSummary.isEmpty ? nil : trimmedSummary
    item.sourceURL = trimmedURL.isEmpty ? nil : trimmedURL
    item.sourceName = sourceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? URL(string: trimmedURL)?.host()
      : sourceName.trimmingCharacters(in: .whitespacesAndNewlines)
    if type == .paper {
      item.authors = splitList(authors)
      item.publicationVenue = emptyToNil(publicationVenue)
      item.publicationYear = Int(publicationYear.trimmingCharacters(in: .whitespacesAndNewlines))
      item.doi = emptyToNil(doi)
      item.arxivID = emptyToNil(arxivID)
    }
    if type == .competition, hasCompetitionDeadline {
      item.competitionDeadline = competitionDeadline
      item.competitionStage = .collecting
      item.competitionURL = trimmedURL.isEmpty ? nil : trimmedURL
    }
    if type == .competition {
      item.competitionSubmissionItems = splitList(competitionSubmissionItems)
      item.competitionScoringPoints = splitList(competitionScoringPoints)
    }
    if type == .voice {
      item.voiceTranscript = trimmedSummary.isEmpty ? nil : trimmedSummary
      item.voiceDuration = TimeInterval(voiceDuration.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    if let selectedProjectID,
      let project = projectRepository.findByID(selectedProjectID)
    {
      item.projects = [project]
    }

    do {
      try repository.create(item)
      toastCenter.show(message: "已添加「\(item.title)」", itemID: item.id)
      sheetManager.dismiss()
    } catch {
      errorMessage = "保存失败：\(error.localizedDescription)"
    }
  }

  private func loadProjects() {
    do {
      projects = try projectRepository.fetchAll()
      if selectedProjectID == nil {
        selectedProjectID = initialProjectID
      }
    } catch {
      errorMessage = "项目列表读取失败：\(error.localizedDescription)"
    }
  }

  private func clipboardValue() -> String? {
    #if canImport(UIKit)
      let value = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines)
      return value?.isEmpty == false ? value : nil
    #else
      return nil
    #endif
  }

  private func createFromClipboard() {
    guard let value = clipboardValue() else {
      errorMessage = "剪贴板里没有可创建的文字或链接。"
      return
    }
    if URL(string: value)?.scheme != nil {
      sourceURL = value
      selectedType = .article
    } else {
      summary = value
      selectedType = .insight
    }
  }

  private func splitList(_ value: String) -> [String]? {
    let parts = value
      .split { $0 == "," || $0 == "，" || $0 == "\n" }
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    return parts.isEmpty ? nil : parts
  }

  private func emptyToNil(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}

@MainActor
struct CompetitionReviewSheet: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(GistToastCenter.self) private var toastCenter
  @Environment(ResearchItemRepository.self) private var repository
  @Environment(ProjectRepository.self) private var projectRepository
  @Environment(\.modelContext) private var modelContext

  let initialProjectID: UUID?
  let initialRawText: String
  let initialSourceURL: String?

  @State private var rawText: String
  @State private var sourceURL: String
  @State private var selectedProjectID: UUID?
  @State private var projects: [Project] = []
  @State private var extracted: CompetitionExtractionResult?
  @State private var extractionCache: CompetitionExtractionCache?
  @State private var isExtracting = false
  @State private var errorMessage: String?
  private let aiClient = AITaskClient.shared

  init(initialProjectID: UUID?, initialRawText: String, initialSourceURL: String?) {
    self.initialProjectID = initialProjectID
    self.initialRawText = initialRawText
    self.initialSourceURL = initialSourceURL
    _rawText = State(initialValue: initialRawText)
    _sourceURL = State(initialValue: initialSourceURL ?? "")
    _selectedProjectID = State(initialValue: initialProjectID)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: theme.spacing.xl) {
          VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("原始通知")
              .font(theme.fonts.headline)
              .foregroundStyle(theme.colors.textPrimary)
            TextField("粘贴比赛通知", text: $rawText, axis: .vertical)
            TextField("官网链接（可选）", text: $sourceURL)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
            Picker("归属项目", selection: $selectedProjectID) {
              Text("不选择项目").tag(nil as UUID?)
              ForEach(projects, id: \.id) { project in
                Text(project.name).tag(project.id as UUID?)
              }
            }
            Button(isExtracting ? "抽取中..." : "开始抽取") {
              extract()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExtracting || rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
          .gistCard()

          if let extracted {
            competitionReviewCard(extracted)
            Button("保存为竞赛资料") {
              saveCompetition(from: extracted)
            }
            .buttonStyle(.borderedProminent)
          }

          if let errorMessage {
            Text(errorMessage)
              .font(theme.fonts.footnote)
              .foregroundStyle(theme.colors.statusWarning)
          }
        }
        .padding(theme.spacing.lg)
      }
      .background(theme.colors.bgSheet)
      .navigationTitle("竞赛审查")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("关闭") {
            sheetManager.dismiss()
          }
        }
      }
      .task {
        loadProjects()
      }
    }
  }

  private func loadProjects() {
    do {
      projects = try projectRepository.fetchAll()
      if selectedProjectID == nil {
        selectedProjectID = initialProjectID
      }
    } catch {
      errorMessage = "项目列表读取失败：\(error.localizedDescription)"
    }
  }

  private func extract() {
    let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedText.isEmpty else {
      errorMessage = "请先粘贴比赛通知。"
      return
    }

    isExtracting = true
    errorMessage = nil

    Task { @MainActor in
      defer { isExtracting = false }
      do {
        let result = try await aiClient.extractCompetition(
          rawText: trimmedText,
          sourceURL: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sourceURL
        )
        extracted = result
        let cache = extractionCache ?? CompetitionExtractionCache()
        cache.competitionName = result.competitionName
        cache.sourceURL = result.officialURL ?? emptyToNil(sourceURL)
        cache.rawInputPreview = String(trimmedText.prefix(200))
        cache.extractedJSON = encodeJSONString(result)
        cache.overallConfidence = result.overallConfidence
        cache.updatedAt = Date()
        if extractionCache == nil {
          modelContext.insert(cache)
        }
        extractionCache = cache
        try? modelContext.save()
      } catch {
        errorMessage = "抽取失败：\(error.localizedDescription)"
      }
    }
  }

  private func saveCompetition(from result: CompetitionExtractionResult) {
    let item = ResearchItem(
      title: result.competitionName ?? "未命名竞赛",
      itemType: .competition
    )
    item.summary = result.eligibility?.description ?? "由 mock 竞赛抽取任务生成"
    item.sourceURL = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : sourceURL
    item.sourceName = "Competition Review"
    item.competitionStage = .collecting
    item.competitionURL = result.officialURL ?? item.sourceURL
    item.competitionSubmissionItems = result.submissionRequirements?.map(\.item)
    item.competitionScoringPoints = result.scoringCriteria?.map {
      if let weight = $0.weight, !weight.isEmpty {
        return "\($0.criterion)（\(weight)）"
      }
      return $0.criterion
    }
    if let firstDeadline = result.deadlines?.first {
      item.competitionDeadline = ISO8601DateFormatter().date(from: firstDeadline.date)
    }

    if let selectedProjectID,
      let project = projectRepository.findByID(selectedProjectID)
    {
      item.projects = [project]
    }

    do {
      try repository.create(item)
      extractionCache?.competitionItemID = item.id
      extractionCache?.reviewStatusRaw = "confirmed"
      extractionCache?.reviewedAt = Date()
      extractionCache?.updatedAt = Date()
      try? modelContext.save()
      if let projectID = selectedProjectID {
        toastCenter.show(
          message: "已保存竞赛「\(item.title)」并加入项目",
          projectID: projectID,
          actionLabel: "看项目"
        )
      } else {
        toastCenter.show(message: "已保存竞赛「\(item.title)」", itemID: item.id)
      }
      sheetManager.dismiss()
    } catch {
      errorMessage = "保存失败：\(error.localizedDescription)"
    }
  }

  private func competitionReviewCard(_ result: CompetitionExtractionResult) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.lg) {
      Text(result.competitionName ?? "未命名竞赛")
        .font(theme.fonts.title3)
        .foregroundStyle(theme.colors.textPrimary)

      if let deadlines = result.deadlines, !deadlines.isEmpty {
        reviewSection("截止时间") {
          ForEach(Array(deadlines.enumerated()), id: \.offset) { _, deadline in
            reviewEvidenceRow(
              title: deadline.name,
              value: formatDate(deadline.date),
              confidence: deadline.confidence,
              evidence: deadline.evidence
            )
          }
        }
      }

      if let items = result.submissionRequirements, !items.isEmpty {
        reviewSection("提交材料") {
          ForEach(Array(items.enumerated()), id: \.offset) { _, requirement in
            reviewEvidenceRow(
              title: requirement.item,
              value: requirement.format ?? (requirement.required == true ? "必交" : "待确认"),
              confidence: requirement.confidence,
              evidence: requirement.evidence
            )
          }
        }
      }

      if let criteria = result.scoringCriteria, !criteria.isEmpty {
        reviewSection("评分要点") {
          ForEach(Array(criteria.enumerated()), id: \.offset) { _, criterion in
            reviewEvidenceRow(
              title: criterion.criterion,
              value: criterion.weight ?? "未给出权重",
              confidence: criterion.confidence,
              evidence: criterion.evidence
            )
          }
        }
      }

      if let uncertainFields = result.uncertainFields, !uncertainFields.isEmpty {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text("待人工确认")
            .font(theme.fonts.footnote.weight(.semibold))
            .foregroundStyle(theme.colors.statusWarning)
          Text(uncertainFields.joined(separator: " · "))
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.textSecondary)
        }
      }
    }
    .gistCard()
  }

  private func reviewSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(title)
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      content()
    }
  }

  private func reviewEvidenceRow(
    title: String,
    value: String,
    confidence: Double,
    evidence: String?
  ) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.xs) {
      HStack(alignment: .firstTextBaseline) {
        Text(title)
          .font(theme.fonts.footnote.weight(.semibold))
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        Text(value)
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.textSecondary)
      }
      ProgressView(value: confidence)
        .tint(confidence < 0.5 ? theme.colors.statusWarning : theme.colors.accentPrimary)
      if let evidence, !evidence.isEmpty {
        Text("依据：\(evidence)")
          .font(theme.fonts.caption2)
          .foregroundStyle(theme.colors.textTertiary)
      }
    }
  }

  private func formatDate(_ isoString: String) -> String {
    if let date = ISO8601DateFormatter().date(from: isoString) {
      return date.formatted(.dateTime.month().day().hour().minute())
    }
    return isoString
  }

  private func emptyToNil(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
