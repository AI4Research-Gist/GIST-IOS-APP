import Foundation

@MainActor
@Observable
final class GistToastCenter {
  var current: GistToast?

  func show(message: String, itemID: UUID? = nil) {
    current = GistToast(message: message, itemID: itemID)
  }

  func dismiss() {
    current = nil
  }
}

struct GistToast: Identifiable, Equatable {
  let id = UUID()
  let message: String
  let itemID: UUID?
}
