import SwiftUI

@MainActor
struct ProjectAddItemSheet: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(GistToastCenter.self) private var toastCenter
  @Environment(ProjectRepository.self) private var projectRepository
  @Environment(ResearchItemRepository.self) private var itemRepository

  let projectID: UUID
  @State private var project: Project?
  @State private var availableItems: [ResearchItem] = []
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      List {
        Section {
          Button {
            sheetManager.present(.newItem(projectID: projectID))
          } label: {
            Label("新建资料并归入项目", systemImage: "plus.circle")
          }
        }

        Section("从资料库选择") {
          if availableItems.isEmpty {
            Text("没有可添加的资料。")
              .foregroundStyle(theme.colors.textSecondary)
          } else {
            ForEach(availableItems, id: \.id) { item in
              Button {
                add(item)
              } label: {
                ResearchItemRow(item: item)
              }
              .buttonStyle(.plain)
            }
          }
        }

        if let errorMessage {
          Text(errorMessage)
            .foregroundStyle(theme.colors.statusWarning)
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.colors.bgSheet)
      .navigationTitle("添加资料")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("关闭") {
            sheetManager.dismiss()
          }
        }
      }
      .task {
        load()
      }
    }
  }

  private func load() {
    guard let project = projectRepository.findByID(projectID) else {
      errorMessage = "未找到项目。"
      return
    }
    self.project = project
    do {
      let projectItemIDs = Set((project.researchItems ?? []).map(\.id))
      availableItems = try itemRepository.fetchAll().filter { !projectItemIDs.contains($0.id) }
      errorMessage = nil
    } catch {
      errorMessage = "资料读取失败：\(error.localizedDescription)"
    }
  }

  private func add(_ item: ResearchItem) {
    guard let project else { return }
    var projects = item.projects ?? []
    if !projects.contains(where: { $0.id == project.id }) {
      projects.append(project)
      item.projects = projects
    }

    do {
      try itemRepository.update(item)
      toastCenter.show(message: "已加入项目「\(project.name)」", itemID: item.id)
      load()
    } catch {
      errorMessage = "添加失败：\(error.localizedDescription)"
    }
  }
}
