import SwiftData

enum GistModelContainer {
  static let shared: ModelContainer = {
    let schema = Schema([
      ResearchItem.self,
      Project.self,
      Tag.self,
      Annotation.self,
      CaptureInboxItem.self,
    ])

    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )

    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Failed to create Gist ModelContainer: \(error)")
    }
  }()
}
