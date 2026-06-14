import Foundation
import SwiftData

enum ResearchItemType: String, Codable, CaseIterable, Identifiable {
  case paper = "paper"
  case article = "article"
  case competition = "competition"
  case voice = "voice"
  case insight = "insight"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .paper: "论文"
    case .article: "文章"
    case .competition: "竞赛"
    case .voice: "语音"
    case .insight: "灵感"
    }
  }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
  case unread = "unread"
  case reading = "reading"
  case completed = "completed"

  var id: String { rawValue }
}

enum AIInterpretationStatus: String, Codable, CaseIterable, Identifiable {
  case none = "none"
  case pending = "pending"
  case processing = "processing"
  case completed = "completed"
  case failed = "failed"

  var id: String { rawValue }
}

enum CompetitionStage: String, Codable, CaseIterable, Identifiable {
  case collecting = "collecting"
  case preparing = "preparing"
  case submitted = "submitted"
  case resultPending = "result_pending"
  case completed = "completed"

  var id: String { rawValue }
}

enum AnnotationType: String, Codable, CaseIterable, Identifiable {
  case highlight = "highlight"
  case note = "note"

  var id: String { rawValue }
}

enum InboxStatus: String, Codable, CaseIterable, Identifiable {
  case pending = "pending"
  case imported = "imported"
  case failed = "failed"

  var id: String { rawValue }
}

@Model
final class ResearchItem {
  var id: UUID = UUID()
  var createdAt: Date = Date()
  var updatedAt: Date = Date()

  var title: String = ""
  var summary: String? = nil
  var sourceURL: String? = nil
  var sourceName: String? = nil

  var itemTypeRaw: String = ResearchItemType.article.rawValue
  var readingStatusRaw: String = ReadingStatus.unread.rawValue
  var isStarred: Bool = false

  @Transient
  var itemType: ResearchItemType {
    get { ResearchItemType(rawValue: itemTypeRaw) ?? .article }
    set { itemTypeRaw = newValue.rawValue }
  }

  @Transient
  var readingStatus: ReadingStatus {
    get { ReadingStatus(rawValue: readingStatusRaw) ?? .unread }
    set { readingStatusRaw = newValue.rawValue }
  }

  var authors: [String]? = nil
  var publicationVenue: String? = nil
  var publicationYear: Int? = nil
  var doi: String? = nil
  var arxivID: String? = nil

  var competitionDeadline: Date? = nil
  var competitionStageRaw: String? = nil
  var competitionSubmissionItems: [String]? = nil
  var competitionScoringPoints: [String]? = nil
  var competitionURL: String? = nil

  @Transient
  var competitionStage: CompetitionStage? {
    get {
      guard let competitionStageRaw else { return nil }
      return CompetitionStage(rawValue: competitionStageRaw)
    }
    set { competitionStageRaw = newValue?.rawValue }
  }

  var voiceFilePath: String? = nil
  var voiceTranscript: String? = nil
  var voiceDuration: TimeInterval? = nil

  var researchQuestion: String? = nil
  var methodology: String? = nil
  var datasetInfo: String? = nil
  var keyFindings: String? = nil
  var limitations: String? = nil
  var reusePoints: String? = nil

  var fullText: String? = nil
  var originalHTML: String? = nil

  var aiInterpretationStatusRaw: String = AIInterpretationStatus.none.rawValue
  var aiInterpretationResult: String? = nil
  var aiStructuredCardJSON: String? = nil
  var aiInterpretationDate: Date? = nil
  var aiInterpretationHistoryJSON: String? = nil

  @Transient
  var aiInterpretationStatus: AIInterpretationStatus {
    get { AIInterpretationStatus(rawValue: aiInterpretationStatusRaw) ?? .none }
    set { aiInterpretationStatusRaw = newValue.rawValue }
  }

  var projects: [Project]? = nil
  var tags: [Tag]? = nil

  @Relationship(deleteRule: .cascade, inverse: \Annotation.researchItem)
  var annotations: [Annotation]? = nil

  var thumbnailData: Data? = nil

  var lastOpenedAt: Date? = nil
  var readingProgress: Double? = nil
  var userNotes: String? = nil
  var readingTime: TimeInterval? = nil

  init(
    id: UUID = UUID(),
    title: String = "",
    itemType: ResearchItemType = .article,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    readingStatus: ReadingStatus = .unread,
    isStarred: Bool = false,
    aiInterpretationStatus: AIInterpretationStatus = .none
  ) {
    self.id = id
    self.title = title
    self.itemTypeRaw = itemType.rawValue
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.readingStatusRaw = readingStatus.rawValue
    self.isStarred = isStarred
    self.aiInterpretationStatusRaw = aiInterpretationStatus.rawValue
  }
}

@Model
final class Project {
  var id: UUID = UUID()
  var name: String = ""
  var descriptionText: String? = nil
  var researchBackground: String? = nil
  var researchQuestionsJSON: String? = nil
  var todoItemsJSON: String? = nil
  var aiSummary: String? = nil
  var aiSummaryDate: Date? = nil
  var createdAt: Date = Date()
  var updatedAt: Date = Date()
  var isActive: Bool = true
  var sortOrder: Int = 0
  var colorHex: String? = nil
  var iconName: String? = nil

  @Relationship(deleteRule: .nullify, inverse: \ResearchItem.projects)
  var researchItems: [ResearchItem]? = nil

  init(name: String = "") {
    self.name = name
  }
}

@Model
final class Tag {
  var id: UUID = UUID()
  var name: String = ""
  var colorHex: String? = nil
  var createdAt: Date = Date()

  @Relationship(deleteRule: .nullify, inverse: \ResearchItem.tags)
  var researchItems: [ResearchItem]? = nil

  init(name: String = "") {
    self.name = name
  }
}

@Model
final class Annotation {
  var id: UUID = UUID()
  var createdAt: Date = Date()
  var updatedAt: Date = Date()
  var annotationTypeRaw: String = AnnotationType.highlight.rawValue
  var selectedText: String = ""
  var noteText: String? = nil
  var highlightColorHex: String? = nil
  var locationInText: Int = 0

  @Transient
  var annotationType: AnnotationType {
    get { AnnotationType(rawValue: annotationTypeRaw) ?? .highlight }
    set { annotationTypeRaw = newValue.rawValue }
  }

  var researchItem: ResearchItem? = nil

  init(selectedText: String = "") {
    self.selectedText = selectedText
  }
}

@Model
final class CaptureInboxItem {
  var id: UUID = UUID()
  var rawURL: String? = nil
  var rawText: String? = nil
  var rawImagePath: String? = nil
  var sourceApp: String? = nil
  var receivedAt: Date = Date()
  var suggestedTypeRaw: String = ResearchItemType.article.rawValue
  var statusRaw: String = InboxStatus.pending.rawValue
  var errorMessage: String? = nil
  var targetProjectID: UUID? = nil

  @Transient
  var suggestedType: ResearchItemType {
    get { ResearchItemType(rawValue: suggestedTypeRaw) ?? .article }
    set { suggestedTypeRaw = newValue.rawValue }
  }

  @Transient
  var status: InboxStatus {
    get { InboxStatus(rawValue: statusRaw) ?? .pending }
    set { statusRaw = newValue.rawValue }
  }

  init(rawURL: String? = nil, rawText: String? = nil) {
    self.rawURL = rawURL
    self.rawText = rawText
  }
}

@Model
final class CompetitionExtractionCache {
  var id: UUID = UUID()
  var serverTaskID: Int? = nil
  var competitionItemID: UUID? = nil
  var competitionServerItemID: Int? = nil
  var competitionName: String? = nil
  var sourceURL: String? = nil
  var rawInputPreview: String? = nil
  var extractedJSON: String? = nil
  var overallConfidence: Double? = nil
  var reviewStatusRaw: String = "pending"
  var createdAt: Date = Date()
  var updatedAt: Date = Date()
  var reviewedAt: Date? = nil
  var lastSyncedAt: Date? = nil

  init() {}
}

@Model
final class PaperResearchArtifactCache {
  var id: UUID = UUID()
  var serverArtifactID: Int? = nil
  var sourceItemID: UUID? = nil
  var sourceServerItemID: Int? = nil
  var projectID: UUID? = nil
  var title: String = ""
  var artifactTypeRaw: String = "paper_deep_dive"
  var markdownContent: String? = nil
  var structuredJSON: String? = nil
  var statusRaw: String = "draft"
  var generatedAt: Date? = nil
  var updatedAt: Date = Date()
  var userEdited: Bool = false
  var modelName: String? = nil
  var lastSyncedAt: Date? = nil

  init() {}
}

struct CardField: Codable, Hashable {
  var content: String
  var confidence: Double
  var sourceQuote: String?
  var isOriginal: Bool
}

struct StructuredCardResult: Codable, Hashable {
  var researchQuestion: CardField?
  var methodology: CardField?
  var datasetInfo: CardField?
  var keyFindings: CardField?
  var limitations: CardField?
  var reusePoints: CardField?
}

struct CompetitionExtractionResult: Codable, Hashable {
  var competitionName: String?
  var officialURL: String?
  var deadlines: [ExtractedDeadline]?
  var submissionRequirements: [ExtractedSubmissionItem]?
  var scoringCriteria: [ExtractedScoringCriterion]?
  var uploadMethod: ExtractedUploadMethod?
  var eligibility: ExtractedField?
  var uncertainFields: [String]?
  var overallConfidence: Double?
}

struct ExtractedDeadline: Codable, Hashable {
  var name: String
  var date: String
  var timezone: String?
  var confidence: Double
  var evidence: String?
}

struct ExtractedSubmissionItem: Codable, Hashable {
  var item: String
  var required: Bool?
  var format: String?
  var confidence: Double
  var evidence: String?
}

struct ExtractedScoringCriterion: Codable, Hashable {
  var criterion: String
  var weight: String?
  var description: String?
  var confidence: Double
  var evidence: String?
}

struct ExtractedUploadMethod: Codable, Hashable {
  var platform: String?
  var url: String?
  var confidence: Double
  var evidence: String?
}

struct ExtractedField: Codable, Hashable {
  var description: String
  var confidence: Double
  var evidence: String?
}

struct PaperResearchArtifactEnvelope: Codable, Hashable {
  var artifactType: String
  var title: String
  var markdownContent: String
  var structuredJSON: PaperResearchArtifact
}

struct PaperResearchArtifact: Codable, Hashable {
  var metadata: ArtifactMetadata?
  var oneSentenceSummary: String?
  var backgroundAndMotivation: BackgroundMotivation?
  var methodDetails: MethodDetails?
  var experimentResults: ExperimentResults?
  var ablation: [String]?
  var insights: [String]?
  var limitations: [String]?
  var relatedWork: [String]?
  var inspiration: [String]?
  var rating: ArtifactRating?
  var relatedPapers: [String]?
  var notes: String?
}

struct ArtifactMetadata: Codable, Hashable {
  var conference: String?
  var arxiv: String?
  var code: String?
  var domain: String?
  var keywords: String?
}

struct BackgroundMotivation: Codable, Hashable {
  var fieldStatus: String?
  var corePainPoint: String?
  var solutionDirection: String?
}

struct MethodDetails: Codable, Hashable {
  var overallFramework: String?
  var keyDesign: String?
  var workflowBreakdown: String?
}

struct ExperimentResults: Codable, Hashable {
  var datasets: String?
  var metrics: String?
  var baseline: String?
  var methodResult: String?
  var improvement: String?
}

struct ArtifactRating: Codable, Hashable {
  var novelty: String?
  var experimentQuality: String?
  var writingQuality: String?
  var value: String?
}

enum StoredAIArtifactKind: String, Codable, Hashable {
  case paperDeepDive = "paper_deep_dive"
}

struct StoredAIArtifact: Identifiable, Codable, Hashable {
  var id: UUID = UUID()
  var kind: StoredAIArtifactKind
  var sourceItemID: UUID
  var sourceItemTitle: String
  var title: String
  var createdAt: Date = Date()
  var markdownContent: String
  var paperArtifact: PaperResearchArtifact
}

extension ResearchItem {
  var structuredCardResult: StructuredCardResult? {
    get { decodeJSONString(aiStructuredCardJSON, as: StructuredCardResult.self) }
    set { aiStructuredCardJSON = encodeJSONString(newValue) }
  }

  var storedArtifacts: [StoredAIArtifact] {
    get { decodeJSONString(aiInterpretationHistoryJSON, as: [StoredAIArtifact].self) ?? [] }
    set { aiInterpretationHistoryJSON = encodeJSONString(newValue) }
  }

  func appendStoredArtifact(_ artifact: StoredAIArtifact) {
    var next = storedArtifacts
    next.insert(artifact, at: 0)
    storedArtifacts = next
  }
}

func encodeJSONString<T: Encodable>(_ value: T?) -> String? {
  guard let value, let data = try? JSONEncoder().encode(value) else { return nil }
  return String(data: data, encoding: .utf8)
}

func decodeJSONString<T: Decodable>(_ json: String?, as type: T.Type) -> T? {
  guard let json, let data = json.data(using: .utf8) else { return nil }
  return try? JSONDecoder().decode(type, from: data)
}
