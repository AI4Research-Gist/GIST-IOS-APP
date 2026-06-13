import Foundation
import SwiftUI

enum GistTab: Int, Hashable, CaseIterable, Identifiable {
  case home
  case library
  case explore

  var id: Int { rawValue }

  var title: String {
    switch self {
    case .home: "首页"
    case .library: "资料库"
    case .explore: "探索"
    }
  }
}

enum GistLibraryDimension: Hashable {
  case unread
  case all
  case today
  case starred
  case interpreted
  case annotated
  case project(UUID)
  case tag(UUID)

  var title: String {
    switch self {
    case .unread: "未读"
    case .all: "全部"
    case .today: "今日新增"
    case .starred: "星标"
    case .interpreted: "已解读"
    case .annotated: "已标注"
    case .project: "项目资料"
    case .tag: "标签资料"
    }
  }
}

enum GistNavigationDestination: Hashable {
  case itemDetail(UUID)
  case projectDetail(UUID)
  case libraryList(GistLibraryDimension)
  case search
}

enum GistSheetType: Identifiable, Hashable {
  case newItem(projectID: UUID?)
  case aiInterpretation(itemID: UUID)
  case editProject(projectID: UUID?)
  case addItemToProject(projectID: UUID)

  var id: String {
    switch self {
    case .newItem(let projectID):
      "newItem-\(projectID?.uuidString ?? "none")"
    case .aiInterpretation(let itemID):
      "aiInterpretation-\(itemID.uuidString)"
    case .editProject(let projectID):
      "editProject-\(projectID?.uuidString ?? "new")"
    case .addItemToProject(let projectID):
      "addItemToProject-\(projectID.uuidString)"
    }
  }
}

@MainActor
@Observable
final class GistNavigationRouter {
  var selectedTab: GistTab = .home
  var homePath = NavigationPath()
  var libraryPath = NavigationPath()
  var explorePath = NavigationPath()

  init(initialTab: GistTab = .home) {
    selectedTab = initialTab
  }

  func popToRoot(for tab: GistTab) {
    switch tab {
    case .home:
      homePath = NavigationPath()
    case .library:
      libraryPath = NavigationPath()
    case .explore:
      explorePath = NavigationPath()
    }
  }

  func navigateToItem(_ itemID: UUID) {
    selectedTab = .library
    libraryPath = NavigationPath()
    libraryPath.append(GistNavigationDestination.itemDetail(itemID))
  }

  func navigateToProject(_ projectID: UUID) {
    selectedTab = .library
    libraryPath = NavigationPath()
    libraryPath.append(GistNavigationDestination.projectDetail(projectID))
  }
}

@MainActor
@Observable
final class GistSheetManager {
  var activeSheet: GistSheetType?

  init(initialSheet: GistSheetType? = nil) {
    activeSheet = initialSheet
  }

  func present(_ sheet: GistSheetType) {
    activeSheet = sheet
  }

  func dismiss() {
    activeSheet = nil
  }
}
