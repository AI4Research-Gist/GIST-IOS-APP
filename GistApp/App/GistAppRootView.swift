import SwiftData
import SwiftUI

@MainActor
struct GistAppRootView: View {
  private let launchConfiguration: GistLaunchConfiguration
  private let container: ModelContainer
  private let initialSheet: GistSheetType?
  @State private var theme = GistTheme()
  @State private var router: GistNavigationRouter
  @State private var sheetManager: GistSheetManager
  @State private var toastCenter = GistToastCenter()
  @State private var dataChangeCenter = GistDataChangeCenter()

  init() {
    let launchConfiguration = GistLaunchConfiguration.current
    self.launchConfiguration = launchConfiguration
    container = GistModelContainer.shared
    initialSheet = launchConfiguration.initialSheet
    _router = State(initialValue: GistNavigationRouter(initialTab: launchConfiguration.initialTab))
    _sheetManager = State(initialValue: GistSheetManager())
  }

  var body: some View {
    GistRootContentView(
      launchConfiguration: launchConfiguration,
      initialSheet: initialSheet
    )
      .modelContainer(container)
      .environment(theme)
      .environment(router)
      .environment(sheetManager)
      .environment(toastCenter)
      .environment(dataChangeCenter)
      .preferredColorScheme(.dark)
  }
}

private struct GistRootContentView: View {
  let launchConfiguration: GistLaunchConfiguration
  let initialSheet: GistSheetType?
  @Environment(\.modelContext) private var modelContext
  @Environment(GistTheme.self) private var theme
  @Environment(GistNavigationRouter.self) private var router
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(GistToastCenter.self) private var toastCenter
  @Environment(GistDataChangeCenter.self) private var dataChangeCenter
  @State private var isLaunchPrepared = false
  @State private var launchPreparationError: String?

  var body: some View {
    Group {
      if isLaunchPrepared {
        contentView
      } else {
        ZStack {
          theme.colors.bgPrimary
            .ignoresSafeArea()
          if let launchPreparationError {
            Text(launchPreparationError)
              .foregroundStyle(theme.colors.statusWarning)
              .padding(theme.spacing.lg)
          } else {
            ProgressView()
              .tint(theme.colors.accentPrimary)
          }
        }
      }
    }
    .task {
      prepareLaunchIfNeeded()
    }
  }

  private var contentView: some View {
    @Bindable var router = router
    @Bindable var sheetManager = sheetManager
    let itemRepository = ResearchItemRepository(
      modelContext: modelContext,
      dataChangeCenter: dataChangeCenter
    )
    let projectRepository = ProjectRepository(
      modelContext: modelContext,
      dataChangeCenter: dataChangeCenter
    )
    let tagRepository = TagRepository(
      modelContext: modelContext,
      dataChangeCenter: dataChangeCenter
    )

    return TabView(selection: $router.selectedTab) {
      GistNavigationStack(path: $router.homePath) {
        HomeWorkbenchView()
      }
      .tabItem {
        Label(
          GistTab.home.title,
          systemImage: router.selectedTab == .home ? theme.icons.homeSelected : theme.icons.home
        )
      }
      .tag(GistTab.home)

      GistNavigationStack(path: $router.libraryPath) {
        LibraryDirectoryView()
      }
      .tabItem {
        Label(
          GistTab.library.title,
          systemImage: router.selectedTab == .library
            ? theme.icons.librarySelected : theme.icons.library
        )
      }
      .tag(GistTab.library)

      GistNavigationStack(path: $router.explorePath) {
        ExploreRootView()
      }
      .tabItem {
        Label(GistTab.explore.title, systemImage: theme.icons.explore)
      }
      .tag(GistTab.explore)
    }
    .tint(theme.colors.accentPrimary)
    .background(theme.colors.bgPrimary)
    .environment(itemRepository)
    .environment(projectRepository)
    .environment(tagRepository)
    .sheet(item: $sheetManager.activeSheet) { sheet in
      GistSheetHost(sheet: sheet)
        .environment(theme)
        .environment(router)
        .environment(sheetManager)
        .environment(toastCenter)
        .environment(itemRepository)
        .environment(projectRepository)
        .environment(tagRepository)
        .presentationBackground(theme.colors.bgSheet)
    }
    .overlay(alignment: .top) {
      GistToastOverlayView()
    }
    .overlay(alignment: .topLeading) {
      if launchConfiguration.preloadTabStacks {
        GistAcceptanceStackOverlay()
          .padding(theme.spacing.md)
      }
    }
  }

  private func prepareLaunchIfNeeded() {
    guard !isLaunchPrepared else { return }

    let itemRepository = ResearchItemRepository(
      modelContext: modelContext,
      dataChangeCenter: dataChangeCenter
    )
    let projectRepository = ProjectRepository(
      modelContext: modelContext,
      dataChangeCenter: dataChangeCenter
    )
    let snapshot: GistLaunchSeedSnapshot

    do {
      snapshot = try GistAcceptanceBootstrapper.prepareIfNeeded(
        configuration: launchConfiguration,
        modelContext: modelContext
      )
      launchPreparationError = nil
    } catch {
      launchPreparationError = "阶段 1 验收种子准备失败：\(error.localizedDescription)"
      isLaunchPrepared = true
      return
    }

    applyInitialRoute(snapshot: snapshot, itemRepository: itemRepository, projectRepository: projectRepository)
    applyAcceptanceScenarios(
      snapshot: snapshot,
      itemRepository: itemRepository,
      projectRepository: projectRepository
    )
    presentInitialUI(snapshot: snapshot, itemRepository: itemRepository)
    isLaunchPrepared = true
  }

  private func applyInitialRoute(
    snapshot: GistLaunchSeedSnapshot,
    itemRepository: ResearchItemRepository,
    projectRepository: ProjectRepository
  ) {
    guard let initialRoute = launchConfiguration.initialRoute else { return }

    switch initialRoute {
    case .libraryList(let dimension):
      router.selectedTab = .library
      router.libraryPath.append(GistNavigationDestination.libraryList(dimension))
    case .itemDetail(let itemType):
      if let itemID = resolveItemID(for: itemType, snapshot: snapshot, itemRepository: itemRepository) {
        router.navigateToItem(itemID)
      }
    case .projectDetail:
      if let projectID = resolveProjectID(snapshot: snapshot, projectRepository: projectRepository) {
        router.navigateToProject(projectID)
      }
    case .projectAddItem:
      if let projectID = resolveProjectID(snapshot: snapshot, projectRepository: projectRepository) {
        router.navigateToProject(projectID)
        sheetManager.present(.addItemToProject(projectID: projectID))
      }
    case .projectTodo:
      if let projectID = resolveProjectID(snapshot: snapshot, projectRepository: projectRepository) {
        router.navigateToProject(projectID)
      }
    }
  }

  private func presentInitialUI(
    snapshot: GistLaunchSeedSnapshot,
    itemRepository: ResearchItemRepository
  ) {
    if let initialSheet {
      sheetManager.present(initialSheet)
    }

    guard let toastType = launchConfiguration.initialToastItemType,
      let itemID = resolveItemID(for: toastType, snapshot: snapshot, itemRepository: itemRepository)
    else { return }

    toastCenter.show(message: "已添加「\(itemTitle(for: itemID, itemRepository: itemRepository))」", itemID: itemID)

    if launchConfiguration.autoOpenToastItem {
      router.navigateToItem(itemID)
      toastCenter.dismiss()
    }
  }

  private func applyAcceptanceScenarios(
    snapshot: GistLaunchSeedSnapshot,
    itemRepository: ResearchItemRepository,
    projectRepository: ProjectRepository
  ) {
    guard launchConfiguration.preloadTabStacks else { return }
    guard
      let projectID = resolveProjectID(snapshot: snapshot, projectRepository: projectRepository),
      let paperID = resolveItemID(for: .paper, snapshot: snapshot, itemRepository: itemRepository)
    else {
      return
    }

    router.homePath = NavigationPath()
    router.homePath.append(GistNavigationDestination.search)

    router.libraryPath = NavigationPath()
    router.libraryPath.append(GistNavigationDestination.libraryList(.unread))
    router.libraryPath.append(GistNavigationDestination.itemDetail(paperID))

    router.explorePath = NavigationPath()
    router.explorePath.append(GistNavigationDestination.projectDetail(projectID))
    router.selectedTab = .library
  }

  private func resolveProjectID(
    snapshot: GistLaunchSeedSnapshot,
    projectRepository: ProjectRepository
  ) -> UUID? {
    if let projectID = snapshot.projectID {
      return projectID
    }
    return try? projectRepository.fetchAll().first?.id
  }

  private func resolveItemID(
    for type: ResearchItemType,
    snapshot: GistLaunchSeedSnapshot,
    itemRepository: ResearchItemRepository
  ) -> UUID? {
    if let itemID = snapshot.itemIDsByType[type] {
      return itemID
    }
    return try? itemRepository.fetchAll().first(where: { $0.itemTypeRaw == type.rawValue })?.id
  }

  private func itemTitle(
    for itemID: UUID,
    itemRepository: ResearchItemRepository
  ) -> String {
    itemRepository.findByID(itemID)?.title ?? "资料"
  }
}

private struct GistAcceptanceStackOverlay: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistNavigationRouter.self) private var router

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("验收模式")
        .font(theme.fonts.caption1.weight(.semibold))
        .foregroundStyle(theme.colors.textSecondary)
      Text("Tab 栈独立保留")
        .font(theme.fonts.footnote.weight(.semibold))
        .foregroundStyle(theme.colors.textPrimary)
      Text("当前 Tab：\(router.selectedTab.title)")
        .font(theme.fonts.caption1)
        .foregroundStyle(theme.colors.textSecondary)
      Text("首页 H\(router.homePath.count) · 资料库 L\(router.libraryPath.count) · 探索 E\(router.explorePath.count)")
        .font(theme.fonts.caption2)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .padding(theme.spacing.md)
    .background(theme.colors.bgCard.opacity(0.96))
    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
  }
}

private struct GistNavigationStack<Root: View>: View {
  @Binding var path: NavigationPath
  let root: Root

  init(path: Binding<NavigationPath>, @ViewBuilder root: () -> Root) {
    _path = path
    self.root = root()
  }

  var body: some View {
    NavigationStack(path: $path) {
      root
        .navigationDestination(for: GistNavigationDestination.self) { destination in
          switch destination {
          case .itemDetail(let itemID):
            ResearchItemDetailView(itemID: itemID)
          case .projectDetail(let projectID):
            ProjectDetailView(projectID: projectID)
          case .libraryList(let dimension):
            ResearchItemListView(dimension: dimension)
          case .search:
            GistPlaceholderPage(title: "搜索", message: "全局搜索将在后续阶段接入。")
          }
        }
    }
  }
}

private struct GistSheetHost: View {
  let sheet: GistSheetType

  var body: some View {
    switch sheet {
    case .newItem(let projectID):
      NewItemSheet(initialProjectID: projectID)
    case .aiInterpretation:
      GistPlaceholderPage(title: "AI 解读", message: "阶段 1 保留 Sheet 入口，真实 AI 在阶段 3 接入。")
    case .editProject(let projectID):
      EditProjectSheet(projectID: projectID)
    case .addItemToProject(let projectID):
      ProjectAddItemSheet(projectID: projectID)
    }
  }
}

struct GistPlaceholderPage: View {
  @Environment(GistTheme.self) private var theme
  let title: String
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text(title)
        .font(theme.fonts.title2)
        .foregroundStyle(theme.colors.textPrimary)
      Text(message)
        .font(theme.fonts.body)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(theme.spacing.lg)
    .background(theme.colors.bgPrimary)
  }
}
