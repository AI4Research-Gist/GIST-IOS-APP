import SwiftUI

@MainActor
struct ProjectDetailView: View {
  @Environment(GistTheme.self) private var theme
  @Environment(ProjectRepository.self) private var projectRepository
  @Environment(ResearchItemRepository.self) private var itemRepository
  @Environment(GistNavigationRouter.self) private var router
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(GistDataChangeCenter.self) private var dataChangeCenter
  let projectID: UUID
  @State private var project: Project?
  @State private var items: [ResearchItem] = []
  @State private var selectedType: ResearchItemType?
  @State private var errorMessage: String?
  @State private var didApplyLaunchTodoToggle = false
  @State private var todoSectionScrollTrigger = false
  @State private var isBackgroundExpanded = true
  @State private var isQuestionsExpanded = true

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: theme.spacing.xxl) {
          Text(project?.name ?? "项目")
            .font(theme.fonts.title2)
            .foregroundStyle(theme.colors.textPrimary)

          itemAggregationSection

          if !competitionItems.isEmpty {
            competitionSection
          }

          researchBackgroundSection
          aiSummarySection
          artifactCenterSection
          todoSection
            .id("projectTodoSection")

          if let errorMessage {
            Text(errorMessage)
              .font(theme.fonts.footnote)
              .foregroundStyle(theme.colors.statusWarning)
          }
        }
        .padding(theme.spacing.lg)
      }
      .onChange(of: todoSectionScrollTrigger) { _, shouldScroll in
        guard shouldScroll else { return }
        withAnimation {
          proxy.scrollTo("projectTodoSection", anchor: .top)
        }
      }
    }
    .background(theme.colors.bgPrimary)
    .navigationTitle("项目")
    .task(id: dataChangeCenter.revision) {
      load()
    }
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          sheetManager.present(.addItemToProject(projectID: projectID))
        } label: {
          Image(systemName: "plus")
        }
        Button {
          sheetManager.present(.editProject(projectID: projectID))
        } label: {
          Image(systemName: "pencil")
        }
      }
    }
  }

  private var filteredItems: [ResearchItem] {
    guard let selectedType else { return items }
    return items.filter { $0.itemTypeRaw == selectedType.rawValue }
  }

  private var competitionItems: [ResearchItem] {
    items.filter { $0.itemTypeRaw == ResearchItemType.competition.rawValue }
  }

  private var researchBackgroundSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      DisclosureGroup(isExpanded: $isBackgroundExpanded) {
        Text(project?.researchBackground ?? project?.descriptionText ?? "还没有研究背景。")
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, theme.spacing.sm)
      } label: {
        Text("研究背景")
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
      }

      if let questions = decoded(project?.researchQuestionsJSON), !questions.isEmpty {
        DisclosureGroup(isExpanded: $isQuestionsExpanded) {
          VStack(alignment: .leading, spacing: theme.spacing.xs) {
            ForEach(questions, id: \.self) { question in
              Text("• \(question)")
                .font(theme.fonts.callout)
                .foregroundStyle(theme.colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .padding(.top, theme.spacing.sm)
        } label: {
          Text("研究问题")
            .font(theme.fonts.footnote.weight(.semibold))
            .foregroundStyle(theme.colors.textTertiary)
        }
      }
    }
    .gistCard()
  }

  private var itemAggregationSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("资料聚合")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      Picker("类型", selection: $selectedType) {
        Text("全部").tag(nil as ResearchItemType?)
        Text("论文").tag(ResearchItemType.paper as ResearchItemType?)
        Text("文章").tag(ResearchItemType.article as ResearchItemType?)
        Text("灵感").tag(ResearchItemType.insight as ResearchItemType?)
        Text("语音").tag(ResearchItemType.voice as ResearchItemType?)
      }
      .pickerStyle(.segmented)

      if filteredItems.isEmpty {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
          Text("项目还没有资料。")
            .font(theme.fonts.callout)
            .foregroundStyle(theme.colors.textSecondary)
          Button("添加资料") {
            sheetManager.present(.addItemToProject(projectID: projectID))
          }
          .font(theme.fonts.footnote)
          .foregroundStyle(theme.colors.textLink)
        }
      } else {
        ForEach(filteredItems, id: \.id) { item in
          Button {
            router.libraryPath.append(GistNavigationDestination.itemDetail(item.id))
          } label: {
            ResearchItemRow(item: item)
          }
          .buttonStyle(.plain)
        }
      }
    }
    .gistCard()
  }

  private var competitionSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      Text("竞赛节点")
        .font(theme.fonts.headline)
        .foregroundStyle(theme.colors.textPrimary)
      ForEach(competitionItems, id: \.id) { item in
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          Text(item.title)
            .font(theme.fonts.body)
            .foregroundStyle(theme.colors.textPrimary)
          if let deadline = item.competitionDeadline {
            Text("截止：\(deadline.formatted(.dateTime.month().day().hour().minute()))")
              .font(theme.fonts.footnote)
              .foregroundStyle(theme.colors.statusWarning)
          }
        }
      }
    }
    .gistCard()
  }

  private var aiSummarySection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      HStack(alignment: .firstTextBaseline) {
        Text("AI 项目总结")
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        Text(aiSummaryTimestampText)
          .font(theme.fonts.caption2)
          .foregroundStyle(theme.colors.textTertiary)
      }
      Text(project?.aiSummary ?? "项目级 AI 总结将在阶段 3 接入。")
        .font(theme.fonts.callout)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .gistCard()
  }

  private var artifactCenterSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      HStack {
        Text("科研产出中心")
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        Text("\(artifactSummaries.count) 篇")
          .font(theme.fonts.caption2)
          .foregroundStyle(theme.colors.textTertiary)
      }

      if artifactSummaries.isEmpty {
        Text("先在重要论文详情页生成深度解读稿，这里会自动聚合产出。")
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
      } else {
        ForEach(artifactSummaries) { summary in
          Button {
            router.libraryPath.append(GistNavigationDestination.itemDetail(summary.itemID))
          } label: {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
              Text(summary.title)
                .font(theme.fonts.body)
                .foregroundStyle(theme.colors.textPrimary)
              Text(summary.oneSentenceSummary)
                .font(theme.fonts.footnote)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(2)
              Text("来自 \(summary.itemTitle) · \(summary.createdAt.formatted(.dateTime.month().day().hour().minute()))")
                .font(theme.fonts.caption2)
                .foregroundStyle(theme.colors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .buttonStyle(.plain)
        }
      }
    }
    .gistCard()
  }

  private var todoSection: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      HStack {
        Text("待办事项")
          .font(theme.fonts.headline)
          .foregroundStyle(theme.colors.textPrimary)
        Spacer()
        Button {
          addTodo()
        } label: {
          Image(systemName: "plus")
        }
      }
      let todos = todoItems
      if todos.isEmpty {
        Text("还没有待办事项。")
          .font(theme.fonts.callout)
          .foregroundStyle(theme.colors.textSecondary)
      } else {
        ForEach(todos) { todo in
          Button {
            toggleTodo(todo)
          } label: {
            Label(todo.title, systemImage: todo.isDone ? "checkmark.circle.fill" : "circle")
              .font(theme.fonts.callout)
              .foregroundStyle(todo.isDone ? theme.colors.statusCompleted : theme.colors.textSecondary)
              .strikethrough(todo.isDone)
          }
          .buttonStyle(.plain)
        }
      }
    }
    .gistCard()
  }

  private var todoItems: [ProjectTodoItem] {
    (decoded(project?.todoItemsJSON) ?? []).enumerated().map { index, raw in
      ProjectTodoItem(index: index, rawValue: raw)
    }
  }

  private func load() {
    guard let project = projectRepository.findByID(projectID) else {
      errorMessage = "未找到项目。"
      return
    }
    self.project = project
    do {
      items = try itemRepository.fetchByProject(projectID)
      errorMessage = nil
      applyLaunchTodoToggleIfNeeded()
    } catch {
      errorMessage = "项目资料读取失败：\(error.localizedDescription)"
    }
  }

  private func applyLaunchTodoToggleIfNeeded() {
    guard !didApplyLaunchTodoToggle, GistLaunchConfiguration.current.projectAutoToggleFirstTodo else { return }
    guard let firstTodo = todoItems.first else { return }
    didApplyLaunchTodoToggle = true
    toggleTodo(firstTodo)
    if GistLaunchConfiguration.current.initialRoute == .projectTodo {
      todoSectionScrollTrigger = true
    }
  }

  private func decoded(_ json: String?) -> [String]? {
    guard let json, let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode([String].self, from: data)
  }

  private func saveTodos(_ todos: [String]) {
    guard let project else { return }
    if let data = try? JSONEncoder().encode(todos) {
      project.todoItemsJSON = String(data: data, encoding: .utf8)
    } else {
      project.todoItemsJSON = nil
    }
    try? projectRepository.update(project)
    self.project = project
  }

  private func toggleTodo(_ todo: ProjectTodoItem) {
    var raw = decoded(project?.todoItemsJSON) ?? []
    guard raw.indices.contains(todo.index) else { return }
    raw[todo.index] = todo.toggledRawValue
    saveTodos(raw)
  }

  private func addTodo() {
    var raw = decoded(project?.todoItemsJSON) ?? []
    raw.append("新待办事项")
    saveTodos(raw)
  }

  private var aiSummaryTimestampText: String {
    guard let generatedAt = project?.aiSummaryDate else { return "未生成" }
    return generatedAt.formatted(.dateTime.month().day().hour().minute())
  }

  private var artifactSummaries: [ProjectArtifactSummary] {
    items.flatMap { item in
      item.storedArtifacts.map { artifact in
        ProjectArtifactSummary(
          id: artifact.id,
          itemID: item.id,
          itemTitle: item.title,
          title: artifact.title,
          oneSentenceSummary: artifact.paperArtifact.oneSentenceSummary ?? "已生成深度稿",
          createdAt: artifact.createdAt
        )
      }
    }
    .sorted { $0.createdAt > $1.createdAt }
  }
}

private struct ProjectTodoItem: Identifiable {
  let index: Int
  let rawValue: String

  var id: Int { index }

  var isDone: Bool {
    rawValue.hasPrefix("[x] ")
  }

  var title: String {
    if rawValue.hasPrefix("[x] ") {
      String(rawValue.dropFirst(4))
    } else if rawValue.hasPrefix("[ ] ") {
      String(rawValue.dropFirst(4))
    } else {
      rawValue
    }
  }

  var toggledRawValue: String {
    isDone ? "[ ] \(title)" : "[x] \(title)"
  }
}

private struct ProjectArtifactSummary: Identifiable {
  let id: UUID
  let itemID: UUID
  let itemTitle: String
  let title: String
  let oneSentenceSummary: String
  let createdAt: Date
}
