import SwiftUI

@MainActor
struct ResearchItemListView: View {
  private struct SwipeActionSpec: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let tint: Color?
    let action: () -> Void
  }

  @Environment(GistTheme.self) private var theme
  @Environment(ResearchItemRepository.self) private var repository
  @Environment(GistNavigationRouter.self) private var router
  let dimension: GistLibraryDimension
  @State private var items: [ResearchItem] = []
  @State private var errorMessage: String?
  @State private var isSelecting = false
  @State private var selectedItemIDs: Set<UUID> = []
  @State private var didApplyLaunchSelection = false

  var body: some View {
    Group {
      if items.isEmpty {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
          Text(errorMessage ?? emptyMessage)
            .font(theme.fonts.callout)
            .foregroundStyle(theme.colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gistCard()
          Spacer()
        }
        .padding(theme.spacing.lg)
      } else {
        List {
          ForEach(items, id: \.id) { item in
            Button {
              if isSelecting {
                toggleSelection(item.id)
              } else {
                router.libraryPath.append(GistNavigationDestination.itemDetail(item.id))
              }
            } label: {
              HStack(spacing: theme.spacing.md) {
                if isSelecting {
                  Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(
                      selectedItemIDs.contains(item.id)
                        ? theme.colors.accentPrimary : theme.colors.textTertiary
                    )
                }
                ResearchItemRow(item: item)
              }
            }
            .buttonStyle(.plain)
            .listRowBackground(theme.colors.bgPrimary)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              ForEach(swipeActions(for: item)) { spec in
                Button {
                  spec.action()
                } label: {
                  Label(spec.title, systemImage: spec.systemImage)
                }
                .tint(spec.tint)
              }
            }
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
          VStack(spacing: theme.spacing.sm) {
            if isSelecting {
              selectionBar
            }
            if shouldShowSwipeActionsPreview, let previewItem = items.first {
              swipeActionsPreview(for: previewItem)
            }
          }
        }
      }
    }
    .background(theme.colors.bgPrimary)
    .navigationTitle(dimension.title)
    .task {
      load()
    }
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Menu {
          Button("最近更新") {}
          Button("最近创建") {}
          Button("标题 A-Z") {}
        } label: {
          Image(systemName: "arrow.up.arrow.down")
        }
        Button(isSelecting ? "完成" : "选择") {
          isSelecting.toggle()
          if !isSelecting {
            selectedItemIDs.removeAll()
          }
        }
      }
    }
  }

  private var selectionBar: some View {
    HStack(spacing: theme.spacing.md) {
      Button("全选") {
        selectedItemIDs = Set(items.map(\.id))
      }
      Spacer()
      Button("标星") {
        applyToSelected { $0.isStarred = true }
      }
      Button("已读") {
        applyToSelected { $0.readingStatus = .completed }
      }
      Button(role: .destructive) {
        deleteSelected()
      } label: {
        Text("删除")
      }
      Text("已选 \(selectedItemIDs.count)")
        .font(theme.fonts.caption1)
        .foregroundStyle(theme.colors.textTertiary)
    }
    .font(theme.fonts.footnote)
    .padding(theme.spacing.md)
    .background(theme.colors.bgCard)
  }

  private var shouldShowSwipeActionsPreview: Bool {
    GistLaunchConfiguration.current.showsSwipeActionsPreview && !isSelecting
  }

  private func swipeActionsPreview(for item: ResearchItem) -> some View {
    let specs = swipeActions(for: item)

    return VStack(alignment: .leading, spacing: theme.spacing.sm) {
      Text("左滑动作预览")
        .font(theme.fonts.caption1.weight(.semibold))
        .foregroundStyle(theme.colors.textSecondary)
      HStack(spacing: theme.spacing.sm) {
        ForEach(specs) { spec in
          Label(spec.title, systemImage: spec.systemImage)
            .font(theme.fonts.caption1)
            .foregroundStyle(theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background((spec.tint ?? theme.colors.bgCard).opacity(0.22))
            .clipShape(Capsule())
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(theme.spacing.md)
    .background(theme.colors.bgCard)
  }

  private func load() {
    do {
      items = try itemsForDimension()
      errorMessage = nil
      applyLaunchSelectionIfNeeded()
    } catch {
      errorMessage = "读取资料失败：\(error.localizedDescription)"
      items = []
    }
  }

  private func applyLaunchSelectionIfNeeded() {
    guard !didApplyLaunchSelection, GistLaunchConfiguration.current.listStartsSelecting else { return }
    didApplyLaunchSelection = true
    isSelecting = true
    selectedItemIDs = Set(items.map(\.id))
  }

  private func toggleSelection(_ itemID: UUID) {
    if selectedItemIDs.contains(itemID) {
      selectedItemIDs.remove(itemID)
    } else {
      selectedItemIDs.insert(itemID)
    }
  }

  private func applyToSelected(_ update: (ResearchItem) -> Void) {
    for item in items where selectedItemIDs.contains(item.id) {
      update(item)
      try? repository.update(item)
    }
    selectedItemIDs.removeAll()
    isSelecting = false
    load()
  }

  private func deleteSelected() {
    for item in items where selectedItemIDs.contains(item.id) {
      try? repository.delete(item)
    }
    selectedItemIDs.removeAll()
    isSelecting = false
    load()
  }

  private func itemsForDimension() throws -> [ResearchItem] {
    switch dimension {
    case .unread:
      try repository.fetchUnread()
    case .all:
      try repository.fetchAll()
    case .today:
      try repository.fetchToday()
    case .starred:
      try repository.fetchStarred()
    case .interpreted:
      try repository.fetchInterpreted()
    case .annotated:
      try repository.fetchAnnotated()
    case .project(let projectID):
      try repository.fetchByProject(projectID)
    case .tag(let tagID):
      try repository.fetchByTag(tagID)
    }
  }

  private func markCompleted(_ item: ResearchItem) {
    item.readingStatus = .completed
    try? repository.update(item)
    load()
  }

  private func toggleStar(_ item: ResearchItem) {
    item.isStarred.toggle()
    try? repository.update(item)
    load()
  }

  private func swipeActions(for item: ResearchItem) -> [SwipeActionSpec] {
    [
      SwipeActionSpec(
        id: "mark-completed",
        title: "标为已读",
        systemImage: "checkmark.circle",
        tint: nil,
        action: { markCompleted(item) }
      ),
      SwipeActionSpec(
        id: "toggle-star",
        title: "标星",
        systemImage: theme.icons.star,
        tint: theme.colors.statusStarred,
        action: { toggleStar(item) }
      ),
      SwipeActionSpec(
        id: "more",
        title: "更多",
        systemImage: theme.icons.more,
        tint: nil,
        action: {}
      ),
    ]
  }

  private var emptyMessage: String {
    switch dimension {
    case .unread:
      "还没有未读资料。"
    case .all:
      "还没有任何资料。点击右上角 + 添加第一篇论文或文章。"
    case .today:
      "今天还没有新增资料。"
    case .starred:
      "还没有星标资料。"
    case .interpreted:
      "还没有已解读资料。"
    case .annotated:
      "还没有已标注资料。"
    case .project:
      "这个项目还没有资料。"
    case .tag:
      "这个标签下还没有资料。"
    }
  }
}
