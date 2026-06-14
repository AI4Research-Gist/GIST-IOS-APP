import Foundation
import SwiftData

@MainActor
@Observable
final class GistDataChangeCenter {
  private(set) var revision: Int = 0

  func markChanged() {
    revision &+= 1
  }
}

@MainActor
@Observable
final class ResearchItemRepository {
  private let modelContext: ModelContext
  private let dataChangeCenter: GistDataChangeCenter

  init(modelContext: ModelContext, dataChangeCenter: GistDataChangeCenter) {
    self.modelContext = modelContext
    self.dataChangeCenter = dataChangeCenter
  }

  func create(_ item: ResearchItem) throws {
    modelContext.insert(item)
    try modelContext.save()
    dataChangeCenter.markChanged()
  }

  func update(_ item: ResearchItem) throws {
    item.updatedAt = Date()
    try modelContext.save()
    dataChangeCenter.markChanged()
  }

  func delete(_ item: ResearchItem) throws {
    modelContext.delete(item)
    try modelContext.save()
    dataChangeCenter.markChanged()
  }

  func findByID(_ id: UUID) -> ResearchItem? {
    var descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? modelContext.fetch(descriptor).first
  }

  func fetchAll(limit: Int? = nil) throws -> [ResearchItem] {
    var descriptor = FetchDescriptor<ResearchItem>(
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    if let limit {
      descriptor.fetchLimit = limit
    }
    return try modelContext.fetch(descriptor)
  }

  func fetchUnread(limit: Int? = nil) throws -> [ResearchItem] {
    var descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.readingStatusRaw == "unread" },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    if let limit {
      descriptor.fetchLimit = limit
    }
    return try modelContext.fetch(descriptor)
  }

  func fetchToday() throws -> [ResearchItem] {
    let startOfToday = Calendar.current.startOfDay(for: Date())
    let descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.createdAt >= startOfToday },
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor)
  }

  func fetchStarred() throws -> [ResearchItem] {
    let descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.isStarred },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor)
  }

  func fetchInterpreted() throws -> [ResearchItem] {
    let descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.aiInterpretationStatusRaw == "completed" },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor)
  }

  func fetchAnnotated() throws -> [ResearchItem] {
    try fetchAll().filter { !($0.annotations?.isEmpty ?? true) }
  }

  func fetchRecentlyOpened(limit: Int = 5) throws -> [ResearchItem] {
    var descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.lastOpenedAt != nil },
      sortBy: [SortDescriptor(\.lastOpenedAt, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    return try modelContext.fetch(descriptor)
  }

  func fetchPendingAIInterpretation(limit: Int = 5) throws -> [ResearchItem] {
    var descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.aiInterpretationStatusRaw == "none" },
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    return try modelContext.fetch(descriptor)
  }

  func fetchWithUpcomingDeadlines(withinDays: Int = 7) throws -> [ResearchItem] {
    let now = Date()
    let upperBound = Calendar.current.date(byAdding: .day, value: withinDays, to: now) ?? now
    let descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.itemTypeRaw == "competition" },
      sortBy: [SortDescriptor(\.competitionDeadline, order: .forward)]
    )
    return try modelContext.fetch(descriptor).filter { item in
      guard let deadline = item.competitionDeadline else { return false }
      return deadline >= now && deadline <= upperBound
    }
  }

  func fetchInsights(limit: Int = 5) throws -> [ResearchItem] {
    var descriptor = FetchDescriptor<ResearchItem>(
      predicate: #Predicate { $0.itemTypeRaw == "insight" },
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    return try modelContext.fetch(descriptor)
  }

  func fetchByProject(_ projectID: UUID) throws -> [ResearchItem] {
    // SwiftData multi-to-many predicates remain limited; filter in memory per stage 0 contract.
    try fetchAll().filter { item in
      item.projects?.contains(where: { $0.id == projectID }) ?? false
    }
  }

  func fetchByTag(_ tagID: UUID) throws -> [ResearchItem] {
    // SwiftData multi-to-many predicates remain limited; filter in memory per stage 0 contract.
    try fetchAll().filter { item in
      item.tags?.contains(where: { $0.id == tagID }) ?? false
    }
  }

  func libraryCounts() throws -> LibraryCounts {
    let all = try fetchAll()
    return LibraryCounts(
      all: all.count,
      unread: all.filter { $0.readingStatusRaw == "unread" }.count,
      today: try fetchToday().count,
      starred: all.filter(\.isStarred).count,
      interpreted: all.filter { $0.aiInterpretationStatusRaw == "completed" }.count,
      annotated: all.filter { !($0.annotations?.isEmpty ?? true) }.count
    )
  }
}

struct LibraryCounts {
  var all: Int = 0
  var unread: Int = 0
  var today: Int = 0
  var starred: Int = 0
  var interpreted: Int = 0
  var annotated: Int = 0
}

@MainActor
@Observable
final class ProjectRepository {
  private let modelContext: ModelContext
  private let dataChangeCenter: GistDataChangeCenter

  init(modelContext: ModelContext, dataChangeCenter: GistDataChangeCenter) {
    self.modelContext = modelContext
    self.dataChangeCenter = dataChangeCenter
  }

  func create(_ project: Project) throws {
    modelContext.insert(project)
    try modelContext.save()
    dataChangeCenter.markChanged()
  }

  func update(_ project: Project) throws {
    project.updatedAt = Date()
    try modelContext.save()
    dataChangeCenter.markChanged()
  }

  func fetchAll() throws -> [Project] {
    let descriptor = FetchDescriptor<Project>(
      sortBy: [
        SortDescriptor(\.sortOrder, order: .forward),
        SortDescriptor(\.updatedAt, order: .reverse),
      ]
    )
    return try modelContext.fetch(descriptor)
  }

  func findByID(_ id: UUID) -> Project? {
    var descriptor = FetchDescriptor<Project>(
      predicate: #Predicate { $0.id == id }
    )
    descriptor.fetchLimit = 1
    return try? modelContext.fetch(descriptor).first
  }

  func stats(for project: Project) -> ProjectStats {
    let items = project.researchItems ?? []
    let latestItem = items.max { $0.updatedAt < $1.updatedAt }
    return ProjectStats(
      totalCount: items.count,
      unreadCount: items.filter { $0.readingStatusRaw == "unread" }.count,
      competitionCount: items.filter { $0.itemTypeRaw == "competition" }.count,
      artifactCount: items.reduce(0) { $0 + $1.storedArtifacts.count },
      lastUpdatedAt: latestItem?.updatedAt ?? project.updatedAt,
      latestItemTitle: latestItem?.title
    )
  }
}

struct ProjectStats {
  var totalCount: Int
  var unreadCount: Int
  var competitionCount: Int
  var artifactCount: Int
  var lastUpdatedAt: Date
  var latestItemTitle: String?
}

@MainActor
@Observable
final class TagRepository {
  private let modelContext: ModelContext
  private let dataChangeCenter: GistDataChangeCenter

  init(modelContext: ModelContext, dataChangeCenter: GistDataChangeCenter) {
    self.modelContext = modelContext
    self.dataChangeCenter = dataChangeCenter
  }

  func create(_ tag: Tag) throws {
    modelContext.insert(tag)
    try modelContext.save()
    dataChangeCenter.markChanged()
  }

  func fetchAll() throws -> [Tag] {
    let descriptor = FetchDescriptor<Tag>(
      sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    return try modelContext.fetch(descriptor)
  }
}

struct AITaskResponse: Codable, Hashable {
  var id: Int
  var taskType: String
  var status: String
  var outputJSON: String?
  var errorMessage: String?

  var isDone: Bool { status == "done" }
  var isFailed: Bool { status == "failed" }
}

private actor MockAITaskStore {
  struct TaskRecord {
    var id: Int
    var taskType: String
    var readyAt: Date
    var outputJSON: String
  }

  private var nextID = 1
  private var tasks: [Int: TaskRecord] = [:]

  func create(taskType: String, outputJSON: String) -> AITaskResponse {
    let id = nextID
    nextID += 1
    tasks[id] = TaskRecord(
      id: id,
      taskType: taskType,
      readyAt: Date().addingTimeInterval(0.6),
      outputJSON: outputJSON
    )
    return AITaskResponse(
      id: id,
      taskType: taskType,
      status: "pending",
      outputJSON: nil,
      errorMessage: nil
    )
  }

  func response(for id: Int) -> AITaskResponse {
    guard let record = tasks[id] else {
      return AITaskResponse(
        id: id,
        taskType: "unknown",
        status: "failed",
        outputJSON: nil,
        errorMessage: "任务不存在"
      )
    }
    if Date() >= record.readyAt {
      return AITaskResponse(
        id: record.id,
        taskType: record.taskType,
        status: "done",
        outputJSON: record.outputJSON,
        errorMessage: nil
      )
    }
    return AITaskResponse(
      id: record.id,
      taskType: record.taskType,
      status: "processing",
      outputJSON: nil,
      errorMessage: nil
    )
  }
}

@MainActor
final class AITaskClient {
  static let shared = AITaskClient()

  private let store = MockAITaskStore()

  func createTask(
    taskType: String,
    inputType: String,
    inputPayload: [String: String]
  ) async throws -> AITaskResponse {
    let outputJSON = try mockOutputJSON(
      taskType: taskType,
      inputType: inputType,
      inputPayload: inputPayload
    )
    return await store.create(taskType: taskType, outputJSON: outputJSON)
  }

  func getTask(_ taskID: Int) async throws -> AITaskResponse {
    await store.response(for: taskID)
  }

  func pollUntilDone(
    _ taskID: Int,
    pollInterval: TimeInterval = 0.25,
    timeout: TimeInterval = 8
  ) async throws -> AITaskResponse {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      let response = try await getTask(taskID)
      if response.isDone || response.isFailed {
        return response
      }
      try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
    }
    throw NSError(domain: "AITaskClient", code: 408, userInfo: [
      NSLocalizedDescriptionKey: "AI 任务轮询超时"
    ])
  }

  func generateStructuredCard(for item: ResearchItem) async throws -> StructuredCardResult {
    let task = try await createTask(
      taskType: "structured-card",
      inputType: "item",
      inputPayload: [
        "itemID": item.id.uuidString,
        "title": item.title,
        "summary": item.summary ?? "",
        "fullText": item.fullText ?? "",
      ]
    )
    let completed = try await pollUntilDone(task.id)
    return try decodeOutput(completed, as: StructuredCardResult.self)
  }

  func extractCompetition(
    rawText: String,
    sourceURL: String?
  ) async throws -> CompetitionExtractionResult {
    let task = try await createTask(
      taskType: "extract-competition",
      inputType: "text",
      inputPayload: [
        "rawText": rawText,
        "sourceURL": sourceURL ?? "",
      ]
    )
    let completed = try await pollUntilDone(task.id)
    return try decodeOutput(completed, as: CompetitionExtractionResult.self)
  }

  func generatePaperArtifact(for item: ResearchItem) async throws -> PaperResearchArtifactEnvelope {
    let task = try await createTask(
      taskType: "generate-paper-artifact",
      inputType: "item",
      inputPayload: [
        "itemID": item.id.uuidString,
        "title": item.title,
        "venue": item.publicationVenue ?? "",
        "year": item.publicationYear.map(String.init) ?? "",
        "summary": item.summary ?? "",
      ]
    )
    let completed = try await pollUntilDone(task.id)
    return try decodeOutput(completed, as: PaperResearchArtifactEnvelope.self)
  }

  private func decodeOutput<T: Decodable>(_ response: AITaskResponse, as type: T.Type) throws -> T {
    guard let outputJSON = response.outputJSON, let data = outputJSON.data(using: .utf8) else {
      throw NSError(domain: "AITaskClient", code: 500, userInfo: [
        NSLocalizedDescriptionKey: "AI 输出为空"
      ])
    }
    return try JSONDecoder().decode(type, from: data)
  }

  private func mockOutputJSON(
    taskType: String,
    inputType: String,
    inputPayload: [String: String]
  ) throws -> String {
    switch taskType {
    case "structured-card":
      let title = inputPayload["title"] ?? "未命名资料"
      let result = StructuredCardResult(
        researchQuestion: CardField(
          content: "这篇资料想回答的核心问题是：\(title) 如何在你的当前研究场景里被复用。",
          confidence: 0.92,
          sourceQuote: "问题聚焦于方法与使用场景的匹配关系。",
          isOriginal: true
        ),
        methodology: CardField(
          content: "以问题拆解、方法归纳和关键证据整理为主，适合作为后续项目阅读卡基线。",
          confidence: 0.87,
          sourceQuote: nil,
          isOriginal: true
        ),
        datasetInfo: CardField(
          content: inputPayload["fullText"]?.isEmpty == false ? "正文中存在可进一步抽取的数据与实验设定。" : "当前仅有摘要与来源信息，数据集字段待补充。",
          confidence: 0.74,
          sourceQuote: nil,
          isOriginal: true
        ),
        keyFindings: CardField(
          content: "1. 资料主题与当前项目方向匹配。\n2. 可作为后续 AI 深度稿的输入基础。\n3. 关键内容适合纳入项目背景或方法综述。",
          confidence: 0.89,
          sourceQuote: nil,
          isOriginal: true
        ),
        limitations: CardField(
          content: "目前为本地 mock 结果，仍需要正文证据和人工校对补齐。",
          confidence: 0.93,
          sourceQuote: nil,
          isOriginal: false
        ),
        reusePoints: CardField(
          content: "可以直接回填到项目背景、竞赛材料准备和后续论文对比笔记中。",
          confidence: 0.84,
          sourceQuote: nil,
          isOriginal: false
        )
      )
      return encodeJSONString(result) ?? "{}"

    case "extract-competition":
      let rawText = inputPayload["rawText"] ?? ""
      let result = CompetitionExtractionResult(
        competitionName: rawText.isEmpty ? "研究原型演示挑战赛" : "从通知中提取的竞赛信息",
        officialURL: emptyToNil(inputPayload["sourceURL"]),
        deadlines: [
          ExtractedDeadline(
            name: "提交截止",
            date: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()),
            timezone: "Asia/Shanghai",
            confidence: 0.88,
            evidence: rawText.isEmpty ? "通知中提到下周完成提交。" : String(rawText.prefix(80))
          )
        ],
        submissionRequirements: [
          ExtractedSubmissionItem(
            item: "项目介绍文档",
            required: true,
            format: "PDF",
            confidence: 0.91,
            evidence: "通知提及需提交项目说明。"
          ),
          ExtractedSubmissionItem(
            item: "演示视频",
            required: true,
            format: "MP4",
            confidence: 0.82,
            evidence: "通知提及需要展示完整流程。"
          ),
        ],
        scoringCriteria: [
          ExtractedScoringCriterion(
            criterion: "完整闭环",
            weight: "40%",
            description: "是否覆盖从资料采集到项目推进的完整链路",
            confidence: 0.9,
            evidence: "通知中强调 end-to-end workflow。"
          ),
          ExtractedScoringCriterion(
            criterion: "研究价值",
            weight: "30%",
            description: "是否能真实服务科研工作流",
            confidence: 0.78,
            evidence: nil
          ),
        ],
        uploadMethod: ExtractedUploadMethod(
          platform: "线上表单",
          url: emptyToNil(inputPayload["sourceURL"]),
          confidence: 0.66,
          evidence: "通知中提到通过官网入口提交。"
        ),
        eligibility: ExtractedField(
          description: "面向 AI 产品与科研工具原型团队",
          confidence: 0.72,
          evidence: "通知中提到 research / demo / prototype 团队。"
        ),
        uncertainFields: ["赛制细则", "最终答辩时间"],
        overallConfidence: 0.82
      )
      return encodeJSONString(result) ?? "{}"

    case "generate-paper-artifact":
      let title = inputPayload["title"] ?? "未命名论文"
      let structured = PaperResearchArtifact(
        metadata: ArtifactMetadata(
          conference: emptyToNil(inputPayload["venue"]) ?? "待补充",
          arxiv: nil,
          code: nil,
          domain: "AI Research Workflow",
          keywords: "reading-card, project, synthesis"
        ),
        oneSentenceSummary: "这篇论文最有价值的地方，在于它能直接支撑你当前项目中的资料聚合与研究推进。",
        backgroundAndMotivation: BackgroundMotivation(
          fieldStatus: "相关方向正在从单篇阅读工具转向项目级知识组织。",
          corePainPoint: "论文阅读结果难以稳定回流到项目推进与产出沉淀。",
          solutionDirection: "把阅读卡、项目聚合和深度稿生成串起来。"
        ),
        methodDetails: MethodDetails(
          overallFramework: "先形成结构化阅读卡，再扩展为单篇深度稿。",
          keyDesign: "围绕研究问题、方法、结果和启发进行模块化整理。",
          workflowBreakdown: "采集 -> 阅读卡 -> 深度稿 -> 项目产出中心。"
        ),
        experimentResults: ExperimentResults(
          datasets: "以资料沉淀与项目推进场景为主的 mock 数据",
          metrics: "闭环完整性、可追踪性、复用价值",
          baseline: "仅保存原始链接或摘要",
          methodResult: "可以直接进入项目页产出中心，被后续任务复用",
          improvement: "从单条资料提升为项目级知识资产"
        ),
        ablation: ["如果没有结构化阅读卡，深度稿质量会明显下降。"],
        insights: ["适合作为项目综述和比赛材料的中间层资产。"],
        limitations: ["当前仍为 mock 生成，尚未接真实服务端模型。"],
        relatedWork: ["结构化阅读卡", "项目 AI 总结", "竞赛材料整理"],
        inspiration: ["可扩展为论文对比表和项目综述草稿。"],
        rating: ArtifactRating(
          novelty: "8/10",
          experimentQuality: "7/10",
          writingQuality: "8/10",
          value: "8/10"
        ),
        relatedPapers: ["FlashAttention", "Long Context Survey"],
        notes: "建议纳入项目科研产出中心，后续继续手动修订。"
      )
      let envelope = PaperResearchArtifactEnvelope(
        artifactType: "paper_deep_dive",
        title: "\(title) 深度解读稿",
        markdownContent: """
          # \(title) 深度解读稿

          ## 一句话总结
          \(structured.oneSentenceSummary ?? "暂无")

          ## 方法拆解
          \(structured.methodDetails?.overallFramework ?? "暂无")

          ## 对当前项目的价值
          \(structured.inspiration?.joined(separator: "\n") ?? "暂无")
          """,
        structuredJSON: structured
      )
      return encodeJSONString(envelope) ?? "{}"

    default:
      let fallback = [
        "taskType": taskType,
        "inputType": inputType,
      ]
      return encodeJSONString(fallback) ?? "{}"
    }
  }

  private func emptyToNil(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
