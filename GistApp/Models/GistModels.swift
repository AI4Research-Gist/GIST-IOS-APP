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
