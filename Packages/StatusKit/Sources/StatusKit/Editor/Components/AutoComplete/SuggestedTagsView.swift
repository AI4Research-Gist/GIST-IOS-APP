import DesignSystem
import EmojiText
import Foundation
import Models
import SwiftData
import SwiftUI

extension StatusEditor.AutoCompleteView {
  @available(iOS 26.0, *)
  struct SuggestedTagsView: View {
    enum ViewState {
      case loading, loaded(tags: [String]), error
    }
    
    @Environment(\.modelContext) private var context
    @Environment(Theme.self) private var theme
    
#if canImport(FoundationModels)
    private let assistant = StatusEditor.Assistant()
#endif

    var store: StatusEditor.EditorStore
    @Binding var isTagSuggestionExpanded: Bool
    
    @State var viewState: ViewState = .loading
    
    @Query(sort: \RecentTag.lastUse, order: .reverse) var recentTags: [RecentTag]

    var body: some View {
      switch viewState {
      case .loading:
        ProgressView()
          .task {
#if canImport(FoundationModels)
            viewState = .loaded(tags: await assistant.generateTags(from: store.statusText.string).values)
#else
            viewState = .loaded(tags: [])
#endif
          }
      case .loaded(let tags):
        ForEach(tags, id: \.self ) { tag in
          Button {
            withAnimation {
              isTagSuggestionExpanded = false
              store.selectHashtagSuggestion(tag: tag)
            }
            
            if let index = recentTags.firstIndex(where: {
              $0.title.lowercased() == tag.lowercased()
            }) {
              recentTags[index].lastUse = Date()
            } else {
              var tag = tag
              if tag.first == "#" {
                tag.removeFirst()
              }
              context.insert(RecentTag(title: tag))
            }
          } label: {
            Text(tag)
              .font(.scaledFootnote)
              .fontWeight(.bold)
              .foregroundColor(theme.labelColor)
          }
        }
      case .error:
        EmptyView()
      }
    }
  }
}
