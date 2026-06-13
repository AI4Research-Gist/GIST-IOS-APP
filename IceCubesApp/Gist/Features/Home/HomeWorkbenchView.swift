import SwiftUI

@MainActor
struct HomeWorkbenchView: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistNavigationRouter.self) private var router
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(ResearchItemRepository.self) private var itemRepository
  @Environment(ProjectRepository.self) private var projectRepository
  @State private var unreadItems: [ResearchItem] = []
  @State private var recentItems: [ResearchItem] = []
  @State private var insightItems: [ResearchItem] = []
  @State private var pendingAIItems: [ResearchItem] = []
  @State private var upcomingCompetitions: [ResearchItem] = []
  @State private var projects: [Project] = []
  @State private var errorMessage: String?

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: theme.spacing.xxl) {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text(currentDateText)
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.textTertiary)
          Text("Gist·简研")
            .font(theme.fonts.largeTitle)
            .foregroundStyle(theme.colors.textPrimary)
          Text(greetingMessage)
            .font(theme.fonts.subheadline)
            .foregroundStyle(theme.colors.textSecondary)
        }

        if let competition = upcomingCompetitions.first {
          CompetitionDeadlineCard(item: competition)
        }

        HomeItemListCard(
          title: "未读内容",
          count: "\(unreadItems.count) 篇",
          items: unreadItems,
          emptyMessage: "暂无未读内容。新增论文或文章后会优先出现在这里。",
          showAllAction: {
            router.selectedTab = .library
            router.libraryPath.append(GistNavigationDestination.libraryList(.unread))
          }
        )

        if !recentItems.isEmpty {
          HomeItemListCard(
            title: "最近阅读",
            count: nil,
            items: recentItems,
            emptyMessage: "",
            showAllAction: nil
          )
        }

        HomeInsightCard(items: insightItems)

        HomeProjectCard(projects: projects)

        if !pendingAIItems.isEmpty {
          HomeItemListCard(
            title: "待 AI 解读",
            count: "\(pendingAIItems.count) 篇",
            items: pendingAIItems,
            emptyMessage: "",
            showAllAction: nil
          )
        }

        if let errorMessage {
          Text(errorMessage)
            .font(theme.fonts.footnote)
            .foregroundStyle(theme.colors.statusWarning)
        }
      }
      .padding(theme.spacing.lg)
      .padding(.bottom, theme.spacing.xxxl)
    }
    .background(theme.colors.bgPrimary)
    .navigationTitle("首页")
    .task {
      load()
    }
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          router.homePath.append(GistNavigationDestination.search)
        } label: {
          Image(systemName: theme.icons.search)
        }
        Button {
          sheetManager.present(.newItem(projectID: nil))
        } label: {
          Image(systemName: theme.icons.add)
        }
      }
    }
  }

  private var currentDateText: String {
    Date.now.formatted(.dateTime.month().day().weekday(.wide))
  }

  private var greetingMessage: String {
    let hour = Calendar.current.component(.hour, from: Date())
    return switch hour {
    case 0..<6: "夜深了"
    case 6..<12: "早上好"
    case 12..<14: "中午好"
    case 14..<18: "下午好"
    default: "晚上好"
    }
  }

  private func load() {
    do {
      unreadItems = try itemRepository.fetchUnread(limit: 5)
      recentItems = try itemRepository.fetchRecentlyOpened(limit: 5)
      insightItems = try itemRepository.fetchInsights(limit: 5)
      pendingAIItems = try itemRepository.fetchPendingAIInterpretation(limit: 5)
      upcomingCompetitions = try itemRepository.fetchWithUpcomingDeadlines(withinDays: 7)
      projects = try projectRepository.fetchAll().filter(\.isActive)
      errorMessage = nil
    } catch {
      errorMessage = "首页数据读取失败：\(error.localizedDescription)"
    }
  }
}

private struct HomeItemListCard: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistNavigationRouter.self) private var router
  let title: String
  let count: String?
  let items: [ResearchItem]
  let emptyMessage: String
  let showAllAction: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      HStack {
        Text(title)
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        if let count {
          Text(count)
            .font(theme.fonts.caption1)
            .foregroundStyle(theme.colors.textTertiary)
        }
      }
      if items.isEmpty {
        Text(emptyMessage)
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
      } else {
        ForEach(items.prefix(5), id: \.id) { item in
          Button {
            router.homePath.append(GistNavigationDestination.itemDetail(item.id))
          } label: {
            ResearchItemRow(item: item)
          }
          .buttonStyle(.plain)
          Divider()
            .background(theme.colors.separator)
        }
        if let showAllAction {
          Button("查看全部") {
            showAllAction()
          }
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.textLink)
          .frame(maxWidth: .infinity, alignment: .trailing)
        }
      }
    }
    .gistCard()
  }
}

private struct CompetitionDeadlineCard: View {
  @Environment(GistTheme.self) private var theme
  let item: ResearchItem

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Label("竞赛节点", systemImage: theme.icons.competition)
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.statusWarning)
      Text(item.title)
        .font(theme.fonts.title3)
        .foregroundStyle(theme.colors.textPrimary)
        .lineLimit(1)
      if let deadline = item.competitionDeadline {
        Text("截止：\(deadline.formatted(.dateTime.month().day().hour().minute()))")
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
      }
    }
    .gistCard()
  }
}

private struct HomeInsightCard: View {
  @Environment(GistTheme.self) private var theme
  let items: [ResearchItem]

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("灵感漫游")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      if let item = items.randomElement() {
        Text(item.summary ?? item.title)
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
          .lineLimit(3)
      } else {
        Text("记录你的第一个灵感，它会在这里被重新唤起。")
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
      }
    }
    .gistCard()
  }
}

private struct HomeProjectCard: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistNavigationRouter.self) private var router
  let projects: [Project]

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("项目进展")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      if projects.isEmpty {
        Text("创建项目后，这里会聚合最近阅读和未读进展。")
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
      } else {
        ForEach(projects.prefix(3), id: \.id) { project in
          Button {
            router.navigateToProject(project.id)
          } label: {
            HStack {
              Label(project.name, systemImage: theme.icons.project)
                .font(theme.fonts.body)
                .foregroundStyle(theme.colors.textPrimary)
              Spacer()
              Text("\(project.researchItems?.count ?? 0) 篇")
                .font(theme.fonts.footnote)
                .foregroundStyle(theme.colors.textTertiary)
            }
          }
          .buttonStyle(.plain)
        }
      }
    }
    .gistCard()
  }
}
