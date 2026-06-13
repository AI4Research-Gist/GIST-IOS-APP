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

  init?(argumentValue: String?) {
    switch argumentValue?.lowercased() {
    case "stage1", "acceptance":
      self = .stage1Acceptance
    default:
      return nil
    }
  }
}

enum GistLaunchRoute: Equatable {
  case libraryList(GistLibraryDimension)
  case itemDetail(ResearchItemType)
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
    guard configuration.seedProfile == .stage1Acceptance else {
      return GistLaunchSeedSnapshot()
    }

    try clearStore(modelContext: modelContext)

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

  private static func clearStore(modelContext: ModelContext) throws {
    try deleteAll(Annotation.self, modelContext: modelContext)
    try deleteAll(CaptureInboxItem.self, modelContext: modelContext)
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
