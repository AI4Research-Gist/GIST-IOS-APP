import Foundation
import SwiftData

struct GistLaunchConfiguration {
  let initialTab: GistTab
  let initialSheet: GistSheetType?
  let seedProfile: GistSeedProfile?
  let initialRoute: GistLaunchRoute?
  let initialToastItemType: ResearchItemType?
  let autoOpenToastItem: Bool
  let listStartsSelecting: Bool
  let projectAutoToggleFirstTodo: Bool
  let preloadTabStacks: Bool
  let showsSwipeActionsPreview: Bool
  let directoryFocusSection: GistDirectoryFocusSection?

  static var current: GistLaunchConfiguration {
    let arguments = ProcessInfo.processInfo.arguments
    return GistLaunchConfiguration(
      initialTab: GistTab(argumentValue: arguments.value(after: "-GistInitialTab")) ?? .home,
      initialSheet: GistSheetType(argumentValue: arguments.value(after: "-GistInitialSheet")),
      seedProfile: GistSeedProfile(argumentValue: arguments.value(after: "-GistSeed")),
      initialRoute: GistLaunchRoute(argumentValue: arguments.value(after: "-GistInitialRoute")),
      initialToastItemType: ResearchItemType(argumentValue: arguments.value(after: "-GistInitialToast")),
      autoOpenToastItem: arguments.boolValue(for: "-GistAutoToastView"),
      listStartsSelecting: arguments.boolValue(for: "-GistListSelecting"),
      projectAutoToggleFirstTodo: arguments.boolValue(for: "-GistAutoToggleFirstTodo"),
      preloadTabStacks: arguments.boolValue(for: "-GistPreloadTabStacks"),
      showsSwipeActionsPreview: arguments.boolValue(for: "-GistPreviewSwipeActions"),
      directoryFocusSection: GistDirectoryFocusSection(argumentValue: arguments.value(after: "-GistDirectoryFocus"))
    )
  }
}

enum GistDirectoryFocusSection {
  case smartLists
  case projects
  case favorites
  case tags

  init?(argumentValue: String?) {
    switch argumentValue?.lowercased() {
    case "smartlists", "smart-lists":
      self = .smartLists
    case "projects", "project":
      self = .projects
    case "favorites", "favorite":
      self = .favorites
    case "tags", "tag":
      self = .tags
    default:
      return nil
    }
  }
}

enum GistSeedProfile: Equatable {
  case stage1Acceptance
  case stage2Debug

  init?(argumentValue: String?) {
    switch argumentValue?.lowercased() {
    case "stage1", "acceptance":
      self = .stage1Acceptance
    case "stage2", "debug":
      self = .stage2Debug
    default:
      return nil
    }
  }
}

enum GistLaunchRoute: Equatable {
  case libraryList(GistLibraryDimension)
  case itemDetail(ResearchItemType)
  case itemAIWorkspace(ResearchItemType)
  case competitionReview
  case projectDetail
  case projectAddItem
  case projectTodo

  init?(argumentValue: String?) {
    switch argumentValue?.lowercased() {
    case "list-unread":
      self = .libraryList(.unread)
    case "list-all":
      self = .libraryList(.all)
    case "list-today":
      self = .libraryList(.today)
    case "list-starred":
      self = .libraryList(.starred)
    case "list-interpreted":
      self = .libraryList(.interpreted)
    case "list-annotated":
      self = .libraryList(.annotated)
    case "detail-paper":
      self = .itemDetail(.paper)
    case "detail-article":
      self = .itemDetail(.article)
    case "detail-competition":
      self = .itemDetail(.competition)
    case "detail-voice":
      self = .itemDetail(.voice)
    case "detail-insight":
      self = .itemDetail(.insight)
    case "detail-paper-ai":
      self = .itemAIWorkspace(.paper)
    case "detail-article-ai":
      self = .itemAIWorkspace(.article)
    case "competition-review":
      self = .competitionReview
    case "project":
      self = .projectDetail
    case "project-add-item":
      self = .projectAddItem
    case "project-todo":
      self = .projectTodo
    default:
      return nil
    }
  }
}

struct GistLaunchSeedSnapshot {
  var projectID: UUID?
  var itemIDsByType: [ResearchItemType: UUID] = [:]
}

@MainActor
enum GistAcceptanceBootstrapper {
  static func prepareIfNeeded(
    configuration: GistLaunchConfiguration,
    modelContext: ModelContext
  ) throws -> GistLaunchSeedSnapshot {
    switch configuration.seedProfile {
    case .stage1Acceptance:
      try clearStore(modelContext: modelContext)
      return try makeStage1AcceptanceSnapshot(modelContext: modelContext)

    case .stage2Debug:
      try clearStore(modelContext: modelContext)
      return try makeStage2DebugSnapshot(modelContext: modelContext)

    case nil:
      return try ensureDebugSeedIfNeeded(modelContext: modelContext)
    }
  }

  private static func makeStage1AcceptanceSnapshot(
    modelContext: ModelContext
  ) throws -> GistLaunchSeedSnapshot {
    let project = Project(name: "Agentic Research Workflow")
    project.descriptionText = "围绕 AI 辅助科研、资料沉淀和项目推进的结构化实验。"
    project.researchBackground = "把论文、文章、竞赛、灵感和语音统一沉淀为可复用研究资料。"
    project.researchQuestionsJSON = encode(["如何让研究资料回流到项目推进中？"])
    project.todoItemsJSON = encode(["[ ] 补完竞赛截止时间", "[x] 整理第一批阅读卡片"])
    project.aiSummary = "项目关注研究资料的统一收纳、结构化阅读和可追踪推进。"
    project.sortOrder = 0

    let tagAttention = Tag(name: "注意力机制")
    let tagWorkflow = Tag(name: "科研工作流")

    let now = Date()
    project.aiSummaryDate = now.addingTimeInterval(-1_800)

    let paper = ResearchItem(
      title: "Sparse Attention Survey",
      itemType: .paper,
      createdAt: now.addingTimeInterval(-86_400 * 3),
      updatedAt: now.addingTimeInterval(-1_200),
      readingStatus: .unread,
      isStarred: true,
      aiInterpretationStatus: .completed
    )
    paper.summary = "系统梳理稀疏注意力、线性注意力和长上下文建模中的关键路线。"
    paper.sourceName = "arXiv"
    paper.sourceURL = "https://arxiv.org/abs/2401.00001"
    paper.authors = ["A. Researcher", "B. Engineer"]
    paper.publicationVenue = "arXiv"
    paper.publicationYear = 2024
    paper.doi = "10.1000/sparse-attention"
    paper.arxivID = "2401.00001"
    paper.researchQuestion = "高效注意力如何保持长上下文任务的表现？"
    paper.methodology = "Survey + benchmark comparison"
    paper.datasetInfo = "LongBench, NarrativeQA"
    paper.keyFindings = "稀疏和线性注意力在工程侧具备更稳定的吞吐收益。"
    paper.limitations = "部分结论依赖较新的推理框架。"
    paper.reusePoints = "适合作为阅读卡和项目背景综述。"
    paper.fullText = "阶段 1 使用验收种子数据占位正文。"
    paper.aiInterpretationResult = "已生成结构化阅读卡，可复用到后续项目设计。"
    paper.aiInterpretationDate = now.addingTimeInterval(-900)
    paper.lastOpenedAt = now.addingTimeInterval(-600)
    paper.readingProgress = 0.72
    paper.userNotes = "重点关注长上下文和推理成本之间的权衡。"
    paper.projects = [project]
    paper.tags = [tagAttention, tagWorkflow]

    let annotation = Annotation(selectedText: "稀疏注意力在长上下文中更具工程优势。")
    annotation.noteText = "作为项目背景材料保留。"
    annotation.researchItem = paper
    paper.annotations = [annotation]

    let article = ResearchItem(
      title: "从论文到产品：研究笔记工作流",
      itemType: .article,
      createdAt: now.addingTimeInterval(-86_400 * 2),
      updatedAt: now.addingTimeInterval(-1_800),
      readingStatus: .reading
    )
    article.summary = "讨论如何把阅读摘录、结构化卡片和项目推进串成一个闭环。"
    article.sourceName = "Engineering Blog"
    article.sourceURL = "https://example.com/research-workflow"
    article.lastOpenedAt = now.addingTimeInterval(-1_800)
    article.readingProgress = 0.35
    article.projects = [project]
    article.tags = [tagWorkflow]

    let competition = ResearchItem(
      title: "AI Product Demo Challenge",
      itemType: .competition,
      createdAt: now.addingTimeInterval(-86_400),
      updatedAt: now.addingTimeInterval(-300),
      readingStatus: .unread
    )
    competition.summary = "围绕 AI 辅助科研流程的产品演示竞赛。"
    competition.sourceName = "Competition Hub"
    competition.competitionDeadline = Calendar.current.date(byAdding: .day, value: 3, to: now)
    competition.competitionStage = .collecting
    competition.competitionSubmissionItems = ["演示视频", "项目文档", "答辩材料"]
    competition.competitionScoringPoints = ["完整闭环", "可执行性", "用户价值"]
    competition.projects = [project]

    let voice = ResearchItem(
      title: "导师讨论录音",
      itemType: .voice,
      createdAt: now.addingTimeInterval(-7_200),
      updatedAt: now.addingTimeInterval(-7_200),
      readingStatus: .completed
    )
    voice.summary = "讨论如何把 AI 解读从单点功能收束到研究流程中。"
    voice.sourceName = "本地录音"
    voice.voiceDuration = 532
    voice.voiceTranscript = "阶段 1 先把资料组织和项目容器跑通，再接 AI。"
    voice.projects = [project]

    let insight = ResearchItem(
      title: "软件开发是数字经济的基础设施",
      itemType: .insight,
      createdAt: now.addingTimeInterval(-300),
      updatedAt: now.addingTimeInterval(-300),
      readingStatus: .unread
    )
    insight.summary = "从代码编写、测试验证到文档维护，软件开发天然适合作为知识沉淀容器。"
    insight.sourceName = "本地灵感"
    insight.projects = [project]
    insight.tags = [tagWorkflow]

    let externalArticle = ResearchItem(
      title: "未归档外部文章",
      itemType: .article,
      createdAt: now.addingTimeInterval(-10_800),
      updatedAt: now.addingTimeInterval(-10_800),
      readingStatus: .unread
    )
    externalArticle.summary = "用于验收“从资料库选择”入口的未归档资料。"
    externalArticle.sourceName = "Newsletter"
    externalArticle.sourceURL = "https://example.com/unassigned-article"

    project.researchItems = [paper, article, competition, voice, insight]

    modelContext.insert(project)
    modelContext.insert(tagAttention)
    modelContext.insert(tagWorkflow)
    modelContext.insert(paper)
    modelContext.insert(article)
    modelContext.insert(competition)
    modelContext.insert(voice)
    modelContext.insert(insight)
    modelContext.insert(externalArticle)
    modelContext.insert(annotation)
    try modelContext.save()

    return GistLaunchSeedSnapshot(
      projectID: project.id,
      itemIDsByType: [
        .paper: paper.id,
        .article: article.id,
        .competition: competition.id,
        .voice: voice.id,
        .insight: insight.id,
      ]
    )
  }

  private static func makeStage2DebugSnapshot(
    modelContext: ModelContext
  ) throws -> GistLaunchSeedSnapshot {
    let now = Date()

    let projectWorkflow = Project(name: "AI 研究资料闭环")
    projectWorkflow.descriptionText = "围绕论文阅读卡、项目聚合和科研产出中心的阶段 2 闭环验证。"
    projectWorkflow.researchBackground = "需要验证资料新增、结构化阅读卡、项目归属和科研产出中心之间的完整数据流。"
    projectWorkflow.researchQuestionsJSON = encode(["如何让单篇论文稳定回流到项目推进？", "AI mock 输出如何进入项目产出中心？"])
    projectWorkflow.todoItemsJSON = encode(["[ ] 为关键论文生成深度稿", "[ ] 补充项目级 AI 总结", "[x] 跑通结构化阅读卡链路"])
    projectWorkflow.aiSummary = "项目当前已覆盖资料新增、阅读卡、项目聚合和 mock 产出沉淀，下一步接服务端。"
    projectWorkflow.aiSummaryDate = now.addingTimeInterval(-2_400)
    projectWorkflow.sortOrder = 0

    let projectCompetition = Project(name: "竞赛申报工作流")
    projectCompetition.descriptionText = "聚焦比赛通知抽取、证据审查与材料清单沉淀。"
    projectCompetition.researchBackground = "需要把比赛通知从原始文本转成可追踪的 deadline / 材料 / 评分点。"
    projectCompetition.researchQuestionsJSON = encode(["哪些比赛节点需要进入首页提醒？"])
    projectCompetition.todoItemsJSON = encode(["[ ] 确认最终答辩时间", "[ ] 整理提交材料模板"])
    projectCompetition.aiSummary = "当前已具备比赛通知抽取的 mock 审查链路。"
    projectCompetition.aiSummaryDate = now.addingTimeInterval(-3_600)
    projectCompetition.sortOrder = 1

    let tagAgents = Tag(name: "Agents")
    let tagWorkflow = Tag(name: "Workflow")
    let tagCompetition = Tag(name: "Competition")

    let paperMain = ResearchItem(
      title: "AgentSense: Evaluating LLM Agents in Real Research Workflows",
      itemType: .paper,
      createdAt: now.addingTimeInterval(-86_400 * 4),
      updatedAt: now.addingTimeInterval(-1_000),
      readingStatus: .reading,
      isStarred: true,
      aiInterpretationStatus: .completed
    )
    paperMain.summary = "讨论如何在真实科研流程中衡量 Agent 的资料采集、理解和执行能力。"
    paperMain.sourceName = "arXiv"
    paperMain.sourceURL = "https://arxiv.org/abs/2601.12345"
    paperMain.authors = ["Lin", "Zhao", "Wu"]
    paperMain.publicationVenue = "AAAI 2026"
    paperMain.publicationYear = 2026
    paperMain.arxivID = "2601.12345"
    paperMain.doi = "10.1000/agentsense"
    paperMain.readingProgress = 0.84
    paperMain.lastOpenedAt = now.addingTimeInterval(-2_000)
    paperMain.userNotes = "可直接作为项目中“真实能力替换”阶段的 benchmark 参考。"
    paperMain.projects = [projectWorkflow]
    paperMain.tags = [tagAgents, tagWorkflow]
    paperMain.structuredCardResult = StructuredCardResult(
      researchQuestion: CardField(content: "如何系统评估 LLM Agent 在科研资料流中的有效性？", confidence: 0.95, sourceQuote: nil, isOriginal: true),
      methodology: CardField(content: "通过多任务工作流基准测试 Agent 的资料采集、归纳和执行表现。", confidence: 0.9, sourceQuote: nil, isOriginal: true),
      datasetInfo: CardField(content: "多阶段科研任务集 + 真实资料样例。", confidence: 0.8, sourceQuote: nil, isOriginal: true),
      keyFindings: CardField(content: "完整工作流约束比单题问答更能拉开 Agent 差距。", confidence: 0.88, sourceQuote: nil, isOriginal: true),
      limitations: CardField(content: "目前 benchmark 规模有限，仍偏向实验环境。", confidence: 0.82, sourceQuote: nil, isOriginal: true),
      reusePoints: CardField(content: "适合用作项目第二阶段 mock 到真实服务替换的评估标准。", confidence: 0.8, sourceQuote: nil, isOriginal: false)
    )
    paperMain.aiInterpretationResult = "已完成结构化阅读卡，并沉淀为项目可复用 benchmark 线索。"
    paperMain.aiInterpretationDate = now.addingTimeInterval(-1_800)

    let mainArtifact = StoredAIArtifact(
      kind: .paperDeepDive,
      sourceItemID: paperMain.id,
      sourceItemTitle: paperMain.title,
      title: "AgentSense 深度解读稿",
      createdAt: now.addingTimeInterval(-1_200),
      markdownContent: """
        # AgentSense 深度解读稿

        ## 一句话总结
        这篇论文最大的价值，是把 Agent 的能力评价从单点答案提升到科研工作流级别。
        """,
      paperArtifact: PaperResearchArtifact(
        metadata: ArtifactMetadata(conference: "AAAI 2026", arxiv: "2601.12345", code: "github.com/example/agentsense", domain: "LLM Agent", keywords: "agent, evaluation, workflow"),
        oneSentenceSummary: "把 Agent 评估从单点问答推进到真实科研工作流。",
        backgroundAndMotivation: BackgroundMotivation(fieldStatus: "Agent 评价仍缺 workflow 视角。", corePainPoint: "单题 benchmark 无法反映真实任务链表现。", solutionDirection: "用资料流和项目推进链路来约束评价。"),
        methodDetails: MethodDetails(overallFramework: "多阶段科研流程基准", keyDesign: "采集-理解-推进一体化", workflowBreakdown: "读入资料 -> 结构化 -> 形成项目动作"),
        experimentResults: ExperimentResults(datasets: "自建 workflow 任务集", metrics: "完成率 / 一致性 / 证据质量", baseline: "传统 QA 基准", methodResult: "workflow 任务上区分度更强", improvement: "更贴近真实研究场景"),
        ablation: ["去掉证据要求后，Agent 表现虚高。"],
        insights: ["很适合作为 Gist 后续阶段 3/4 的验收镜子。"],
        limitations: ["当前仍是 mock 和局部数据。"],
        relatedWork: ["Elicit", "OpenDevin", "Deep Research"],
        inspiration: ["可以反向指导 Gist 的服务端任务设计。"],
        rating: ArtifactRating(novelty: "8/10", experimentQuality: "7/10", writingQuality: "8/10", value: "9/10"),
        relatedPapers: ["OpenHands Benchmark", "Deep Research Agents"],
        notes: "项目页应聚合这类产出。"
      )
    )
    paperMain.storedArtifacts = [mainArtifact]

    let paperPending = ResearchItem(
      title: "Flash Retrieval for Long Research Context",
      itemType: .paper,
      createdAt: now.addingTimeInterval(-86_400 * 2),
      updatedAt: now.addingTimeInterval(-3_000),
      readingStatus: .unread
    )
    paperPending.summary = "关注长上下文检索在研究资料场景下的应用。"
    paperPending.sourceName = "arXiv"
    paperPending.publicationVenue = "ICLR 2026"
    paperPending.publicationYear = 2026
    paperPending.projects = [projectWorkflow]
    paperPending.tags = [tagWorkflow]

    let article = ResearchItem(
      title: "如何把阅读笔记回流到项目推进中",
      itemType: .article,
      createdAt: now.addingTimeInterval(-86_400),
      updatedAt: now.addingTimeInterval(-7_200),
      readingStatus: .reading
    )
    article.summary = "从阅读卡、项目归档到产出中心，构建研究资料的闭环。"
    article.sourceName = "Research Engineering Notes"
    article.sourceURL = "https://example.com/research-engineering-notes"
    article.readingProgress = 0.43
    article.lastOpenedAt = now.addingTimeInterval(-7_200)
    article.projects = [projectWorkflow]
    article.tags = [tagWorkflow]

    let competition = ResearchItem(
      title: "Agent Research Demo Challenge 2026",
      itemType: .competition,
      createdAt: now.addingTimeInterval(-40_000),
      updatedAt: now.addingTimeInterval(-1_500),
      readingStatus: .unread
    )
    competition.summary = "要求提交研究型 AI 工作流演示，强调证据、闭环与复用价值。"
    competition.sourceName = "Competition Hub"
    competition.competitionDeadline = Calendar.current.date(byAdding: .day, value: 5, to: now)
    competition.competitionStage = .collecting
    competition.competitionSubmissionItems = ["项目说明 PDF", "五分钟演示视频", "代码仓库链接"]
    competition.competitionScoringPoints = ["闭环完整性", "研究价值", "演示质量"]
    competition.competitionURL = "https://example.com/agent-demo-challenge"
    competition.projects = [projectCompetition]
    competition.tags = [tagCompetition]

    let voice = ResearchItem(
      title: "与导师讨论阶段 2 目标",
      itemType: .voice,
      createdAt: now.addingTimeInterval(-12_000),
      updatedAt: now.addingTimeInterval(-12_000),
      readingStatus: .completed
    )
    voice.summary = "先把数据闭环跑通，再切服务端替换。"
    voice.sourceName = "本地录音"
    voice.voiceDuration = 426
    voice.voiceTranscript = "阶段 2 不追求真实模型，先保证结构化字段、项目归属和竞赛流程都能落盘。"
    voice.projects = [projectWorkflow]

    let insight = ResearchItem(
      title: "科研工具真正的门槛是长期复用，而不是一次性总结",
      itemType: .insight,
      createdAt: now.addingTimeInterval(-1_600),
      updatedAt: now.addingTimeInterval(-1_600),
      readingStatus: .unread
    )
    insight.summary = "如果一条资料不能进入项目、产出或提醒系统，它就只是漂亮的临时结果。"
    insight.projects = [projectWorkflow]
    insight.tags = [tagWorkflow]

    let externalPaper = ResearchItem(
      title: "Unassigned Benchmark Notes",
      itemType: .paper,
      createdAt: now.addingTimeInterval(-32_000),
      updatedAt: now.addingTimeInterval(-32_000),
      readingStatus: .unread
    )
    externalPaper.summary = "专门留给“归入项目”链路验证的独立论文。"
    externalPaper.sourceName = "Workshop"

    let externalArticle = ResearchItem(
      title: "比赛通知草稿摘录",
      itemType: .article,
      createdAt: now.addingTimeInterval(-8_000),
      updatedAt: now.addingTimeInterval(-8_000),
      readingStatus: .unread
    )
    externalArticle.summary = "用于从资料库再次转入项目或触发竞赛提取。"
    externalArticle.sourceName = "Clipboard"

    projectWorkflow.researchItems = [paperMain, paperPending, article, voice, insight]
    projectCompetition.researchItems = [competition]

    modelContext.insert(projectWorkflow)
    modelContext.insert(projectCompetition)
    modelContext.insert(tagAgents)
    modelContext.insert(tagWorkflow)
    modelContext.insert(tagCompetition)
    modelContext.insert(paperMain)
    modelContext.insert(paperPending)
    modelContext.insert(article)
    modelContext.insert(competition)
    modelContext.insert(voice)
    modelContext.insert(insight)
    modelContext.insert(externalPaper)
    modelContext.insert(externalArticle)

    try modelContext.save()

    return GistLaunchSeedSnapshot(
      projectID: projectWorkflow.id,
      itemIDsByType: [
        .paper: paperMain.id,
        .article: article.id,
        .competition: competition.id,
        .voice: voice.id,
        .insight: insight.id,
      ]
    )
  }

  private static func ensureDebugSeedIfNeeded(
    modelContext: ModelContext
  ) throws -> GistLaunchSeedSnapshot {
    let itemCount = try modelContext.fetchCount(FetchDescriptor<ResearchItem>())
    if itemCount == 0 {
      return try makeStage2DebugSnapshot(modelContext: modelContext)
    }

    let items = try modelContext.fetch(FetchDescriptor<ResearchItem>())
    let project = try modelContext.fetch(FetchDescriptor<Project>()).sorted {
      $0.updatedAt > $1.updatedAt
    }.first

    var itemIDsByType: [ResearchItemType: UUID] = [:]
    for type in ResearchItemType.allCases {
      if let item = items.first(where: { $0.itemTypeRaw == type.rawValue }) {
        itemIDsByType[type] = item.id
      }
    }

    return GistLaunchSeedSnapshot(projectID: project?.id, itemIDsByType: itemIDsByType)
  }

  private static func clearStore(modelContext: ModelContext) throws {
    try deleteAll(Annotation.self, modelContext: modelContext)
    try deleteAll(CaptureInboxItem.self, modelContext: modelContext)
    try deleteAll(CompetitionExtractionCache.self, modelContext: modelContext)
    try deleteAll(PaperResearchArtifactCache.self, modelContext: modelContext)
    try deleteAll(ResearchItem.self, modelContext: modelContext)
    try deleteAll(Project.self, modelContext: modelContext)
    try deleteAll(Tag.self, modelContext: modelContext)
    try modelContext.save()
  }

  private static func deleteAll<T: PersistentModel>(
    _ type: T.Type,
    modelContext: ModelContext
  ) throws {
    let items = try modelContext.fetch(FetchDescriptor<T>())
    for item in items {
      modelContext.delete(item)
    }
  }

  private static func encode(_ values: [String]) -> String? {
    guard let data = try? JSONEncoder().encode(values) else { return nil }
    return String(data: data, encoding: .utf8)
  }
}

extension Array where Element == String {
  func value(after key: String) -> String? {
    guard let index = firstIndex(of: key) else { return nil }
    let valueIndex = self.index(after: index)
    guard indices.contains(valueIndex) else { return nil }
    return self[valueIndex]
  }

  func boolValue(for key: String) -> Bool {
    guard let rawValue = value(after: key) else {
      return contains(key)
    }
    if rawValue.hasPrefix("-") {
      return contains(key)
    }
    return ["1", "true", "yes", "on"].contains(rawValue.lowercased())
  }
}

extension GistTab {
  init?(argumentValue: String?) {
    switch argumentValue?.lowercased() {
    case "home":
      self = .home
    case "library":
      self = .library
    case "explore":
      self = .explore
    default:
      return nil
    }
  }
}

extension GistSheetType {
  init?(argumentValue: String?) {
    switch argumentValue?.lowercased() {
    case "newitem", "new-item":
      self = .newItem(projectID: nil)
    default:
      return nil
    }
  }
}

extension ResearchItemType {
  init?(argumentValue: String?) {
    guard let argumentValue else { return nil }
    self.init(rawValue: argumentValue.lowercased())
  }
}
