import AppIntents
import Env
import MediaUI
import StatusKit
import SwiftUI

extension IceCubesApp {
  var appScene: some Scene {
    WindowGroup(id: "MainWindow") {
      GistAppRootView()
    }
    .commands {
      appMenu
    }
    .onChange(of: scenePhase) { _, newValue in
      handleScenePhase(scenePhase: newValue)
    }
    #if targetEnvironment(macCatalyst)
      .windowResize()
    #elseif os(visionOS)
      .defaultSize(width: 800, height: 1200)
    #endif
  }

  @SceneBuilder
  var otherScenes: some Scene {
    WindowGroup(for: WindowDestinationEditor.self) { destination in
      Group {
        switch destination.wrappedValue {
        case let .newStatusEditor(visibility):
          StatusEditor.MainView(mode: .new(text: nil, visibility: visibility))
        case let .prefilledStatusEditor(text, visibility):
          StatusEditor.MainView(mode: .new(text: text, visibility: visibility))
        case let .editStatusEditor(status):
          StatusEditor.MainView(mode: .edit(status: status))
        case let .quoteStatusEditor(status):
          StatusEditor.MainView(mode: .quote(status: status))
        case let .replyToStatusEditor(status):
          StatusEditor.MainView(mode: .replyTo(status: status))
        case let .mentionStatusEditor(account, visibility):
          StatusEditor.MainView(mode: .mention(account: account, visibility: visibility))
        case let .quoteLinkStatusEditor(link):
          StatusEditor.MainView(mode: .quoteLink(link: link))
        case .none:
          EmptyView()
        }
      }
      .withEnvironments()
      .environment(\.isCatalystWindow, true)
      .environment(RouterPath())
      .withModelContainer()
      .applyTheme(theme)
      .frame(minWidth: 300, minHeight: 400)
    }
    .defaultSize(width: 600, height: 800)
    .windowResizability(.contentMinSize)

    WindowGroup(for: WindowDestinationMedia.self) { destination in
      Group {
        switch destination.wrappedValue {
        case let .mediaViewer(attachments, selectedAttachment):
          MediaUIView(
            selectedAttachment: selectedAttachment,
            attachments: attachments)
        case .none:
          EmptyView()
        }
      }
      .withEnvironments()
      .withModelContainer()
      .applyTheme(theme)
      .environment(\.isCatalystWindow, true)
      .frame(minWidth: 300, minHeight: 400)
    }
    .defaultSize(width: 1200, height: 1000)
    .windowResizability(.contentMinSize)
  }

  private func handleIntent(_: any AppIntent) {
    if let postIntent = appIntentService.handledIntent?.intent as? PostIntent {
      #if os(visionOS) || os(macOS)
        openWindow(
          value: WindowDestinationEditor.prefilledStatusEditor(
            text: postIntent.content ?? "",
            visibility: userPreferences.postVisibility))
      #else
        appRouterPath.presentedSheet = .prefilledStatusEditor(
          text: postIntent.content ?? "",
          visibility: userPreferences.postVisibility)
      #endif
    } else if let tabIntent = appIntentService.handledIntent?.intent as? TabIntent {
      selectedTab = tabIntent.tab.toAppTab
    } else if let imageIntent = appIntentService.handledIntent?.intent as? PostImageIntent,
      let urls = imageIntent.images?.compactMap({ $0.fileURL })
    {
      appRouterPath.presentedSheet = .imageURL(
        urls: urls,
        caption: imageIntent.caption,
        altTexts: imageIntent.altText.map { [$0] },
        visibility: userPreferences.postVisibility)
    }
  }
}

extension Scene {
  func windowResize() -> some Scene {
    return self.windowResizability(.contentSize)
  }
}
