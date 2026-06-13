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
    return ProjectStats(
      totalCount: items.count,
      unreadCount: items.filter { $0.readingStatusRaw == "unread" }.count,
      competitionCount: items.filter { $0.itemTypeRaw == "competition" }.count,
      lastUpdatedAt: items.map(\.updatedAt).max() ?? project.updatedAt
    )
  }
}

struct ProjectStats {
  var totalCount: Int
  var unreadCount: Int
  var competitionCount: Int
  var lastUpdatedAt: Date
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
