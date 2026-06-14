import Foundation

@MainActor
@Observable
final class GistToastCenter {
  var current: GistToast?

  func show(message: String, itemID: UUID? = nil) {
    current = GistToast(
      message: message,
      destination: itemID.map { .item($0) },
      actionLabel: nil
    )
  }

  func show(message: String, projectID: UUID, actionLabel: String? = nil) {
    current = GistToast(
      message: message,
      destination: .project(projectID),
      actionLabel: actionLabel
    )
  }

  func dismiss() {
    current = nil
  }
}

enum GistToastDestination: Equatable {
  case item(UUID)
  case project(UUID)
}

struct GistToast: Identifiable, Equatable {
  let id = UUID()
  let message: String
  let destination: GistToastDestination?
  let actionLabel: String?
}
