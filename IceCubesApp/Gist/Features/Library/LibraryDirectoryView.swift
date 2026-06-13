import SwiftUI

@MainActor
struct LibraryDirectoryView: View {
  private enum SectionAnchor: String {
    case status
    case smartLists
    case projects
    case favorites
    case tags
  }

  @Environment(GistTheme.self) private var theme
  @Environment(GistNavigationRouter.self) private var router
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(ResearchItemRepository.self) private var itemRepository
  @Environment(ProjectRepository.self) private var projectRepository
  @Environment(TagRepository.self) private var tagRepository
  @State private var counts = LibraryCounts()
  @State private var projects: [Project] = []
  @State private var tags: [Tag] = []
  @State private var errorMessage: String?
  @State private var didApplyLaunchFocus = false

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: theme.spacing.xxl) {
          directorySection("状态") {
            LibraryDirectoryRow(title: "未读", icon: "book", count: "\(counts.unread)") {
              router.libraryPath.append(GistNavigationDestination.libraryList(.unread))
            }
            LibraryDirectoryRow(title: "全部", icon: "books.vertical", count: "\(counts.all)") {
              router.libraryPath.append(GistNavigationDestination.libraryList(.all))
            }
            LibraryDirectoryRow(title: "今日新增", icon: "calendar", count: "\(counts.today)") {
              router.libraryPath.append(GistNavigationDestination.libraryList(.today))
            }
            LibraryDirectoryRow(title: "星标", icon: "star", count: "\(counts.starred)") {
              router.libraryPath.append(GistNavigationDestination.libraryList(.starred))
            }
            LibraryDirectoryRow(title: "已解读", icon: "sparkles", count: "\(counts.interpreted)") {
              router.libraryPath.append(GistNavigationDestination.libraryList(.interpreted))
            }
            LibraryDirectoryRow(title: "已标注", icon: "highlighter", count: "\(counts.annotated)") {
              router.libraryPath.append(GistNavigationDestination.libraryList(.annotated))
            }
          }
          .id(SectionAnchor.status)

          directorySection("智能列表") {
            LibraryGuideRow(title: "新建智能列表", icon: "line.3.horizontal.decrease.circle")
          }
          .id(SectionAnchor.smartLists)

          directorySection("项目") {
            if projects.isEmpty {
              LibraryGuideRow(title: "新建项目", icon: theme.icons.project) {
                sheetManager.present(.editProject(projectID: nil))
              }
            } else {
              ForEach(projects, id: \.id) { project in
                let stats = projectRepository.stats(for: project)
                LibraryDirectoryRow(
                  title: project.name,
                  icon: theme.icons.project,
                  count: "\(stats.totalCount) 篇 · \(stats.unreadCount) 未读"
                ) {
                  router.libraryPath.append(GistNavigationDestination.projectDetail(project.id))
                }
              }
              LibraryGuideRow(title: "新建项目", icon: theme.icons.project) {
                sheetManager.present(.editProject(projectID: nil))
              }
            }
          }
          .id(SectionAnchor.projects)

          directorySection("收藏夹") {
            LibraryGuideRow(title: "新建收藏夹", icon: "bookmark")
          }
          .id(SectionAnchor.favorites)

          directorySection("标签") {
            if tags.isEmpty {
              Text("添加标签后会以胶囊形式显示在这里。")
                .font(theme.fonts.callout)
                .foregroundStyle(theme.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .gistCard()
            } else {
              LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: theme.spacing.sm)]) {
                ForEach(tags, id: \.id) { tag in
                  Button {
                    router.libraryPath.append(GistNavigationDestination.libraryList(.tag(tag.id)))
                  } label: {
                    Text(tag.name)
                      .font(theme.fonts.caption1)
                      .foregroundStyle(theme.colors.accentPrimary)
                      .lineLimit(1)
                      .padding(.vertical, theme.spacing.sm)
                      .padding(.horizontal, theme.spacing.md)
                      .background(theme.colors.bgCard)
                      .clipShape(Capsule())
                  }
                  .buttonStyle(.plain)
                }
              }
            }
          }
          .id(SectionAnchor.tags)

          if let errorMessage {
            Text(errorMessage)
              .font(theme.fonts.footnote)
              .foregroundStyle(theme.colors.statusWarning)
          }
        }
        .padding(theme.spacing.lg)
        .padding(.bottom, theme.spacing.xxxl)
      }
      .task {
        applyLaunchFocusIfNeeded(proxy: proxy)
      }
    }
    .background(theme.colors.bgPrimary)
    .navigationTitle("资料库")
    .task {
      load()
    }
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          router.libraryPath.append(GistNavigationDestination.search)
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

  private func load() {
    do {
      counts = try itemRepository.libraryCounts()
      projects = try projectRepository.fetchAll()
      tags = try tagRepository.fetchAll()
      errorMessage = nil
    } catch {
      errorMessage = "资料库读取失败：\(error.localizedDescription)"
    }
  }

  private func applyLaunchFocusIfNeeded(proxy: ScrollViewProxy) {
    guard !didApplyLaunchFocus else { return }
    guard let focus = GistLaunchConfiguration.current.directoryFocusSection else { return }
    didApplyLaunchFocus = true

    let anchor: SectionAnchor = switch focus {
    case .smartLists: .smartLists
    case .projects: .projects
    case .favorites: .favorites
    case .tags: .tags
    }

    withAnimation(.easeInOut(duration: 0.2)) {
      proxy.scrollTo(anchor, anchor: .top)
    }
  }

  private func directorySection<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text(title)
        .font(theme.fonts.footnote)
        .foregroundStyle(theme.colors.textTertiary)
      content()
    }
  }
}

private struct LibraryDirectoryRow: View {
  @Environment(GistTheme.self) private var theme
  let title: String
  let icon: String
  let count: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: theme.spacing.md) {
        Image(systemName: icon)
          .foregroundStyle(theme.colors.accentPrimary)
        Text(title)
          .font(theme.fonts.body)
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        Text(count)
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.textTertiary)
        Image(systemName: "chevron.right")
          .font(theme.fonts.caption1)
          .foregroundStyle(theme.colors.textTertiary)
      }
      .gistCard()
    }
    .buttonStyle(.plain)
  }
}

private struct LibraryGuideRow: View {
  @Environment(GistTheme.self) private var theme
  let title: String
  let icon: String
  var action: (() -> Void)?

  var body: some View {
    Button {
      action?()
    } label: {
      HStack(spacing: theme.spacing.md) {
        Image(systemName: icon)
          .foregroundStyle(theme.colors.accentSecondary)
        Text(title)
          .font(theme.fonts.body)
          .foregroundStyle(theme.colors.textSecondary)
        Spacer()
        Image(systemName: "plus")
          .font(theme.fonts.caption1)
          .foregroundStyle(theme.colors.textTertiary)
      }
      .gistCard()
    }
    .buttonStyle(.plain)
  }
}
