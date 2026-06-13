import SwiftUI

@MainActor
struct EditProjectSheet: View {
  @Environment(GistTheme.self) private var theme
  @Environment(GistSheetManager.self) private var sheetManager
  @Environment(ProjectRepository.self) private var projectRepository
  let projectID: UUID?

  @State private var name = ""
  @State private var descriptionText = ""
  @State private var researchBackground = ""
  @State private var researchQuestion = ""
  @State private var isActive = true
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Form {
        Section("项目名称") {
          TextField("例如：ML Safety", text: $name)
        }

        Section("研究背景") {
          TextField("项目描述", text: $descriptionText, axis: .vertical)
          TextField("研究背景", text: $researchBackground, axis: .vertical)
          TextField("研究问题", text: $researchQuestion, axis: .vertical)
        }

        Section {
          Toggle("设为活跃项目", isOn: $isActive)
        }

        if let errorMessage {
          Text(errorMessage)
            .foregroundStyle(theme.colors.statusWarning)
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.colors.bgSheet)
      .navigationTitle(projectID == nil ? "新建项目" : "编辑项目")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("取消") {
            sheetManager.dismiss()
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("保存") {
            save()
          }
        }
      }
      .task {
        load()
      }
    }
  }

  private func load() {
    guard let projectID, let project = projectRepository.findByID(projectID) else { return }
    name = project.name
    descriptionText = project.descriptionText ?? ""
    researchBackground = project.researchBackground ?? ""
    researchQuestion = decodedFirst(project.researchQuestionsJSON)
    isActive = project.isActive
  }

  private func save() {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      errorMessage = "项目名称不可为空。"
      return
    }

    let project = projectID.flatMap { projectRepository.findByID($0) } ?? Project()
    project.name = trimmedName
    project.descriptionText = emptyToNil(descriptionText)
    project.researchBackground = emptyToNil(researchBackground)
    project.researchQuestionsJSON = encodedQuestions()
    project.isActive = isActive

    do {
      if projectID == nil {
        try projectRepository.create(project)
      } else {
        try projectRepository.update(project)
      }
      sheetManager.dismiss()
    } catch {
      errorMessage = "保存失败：\(error.localizedDescription)"
    }
  }

  private func encodedQuestions() -> String? {
    let question = researchQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !question.isEmpty else { return nil }
    guard let data = try? JSONEncoder().encode([question]) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func decodedFirst(_ json: String?) -> String {
    guard let json,
      let data = json.data(using: .utf8),
      let questions = try? JSONDecoder().decode([String].self, from: data)
    else { return "" }
    return questions.first ?? ""
  }

  private func emptyToNil(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
