import AppAccount
import DesignSystem
import Env
import SwiftUI

@MainActor
struct ToolbarTab: ToolbarContent {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Environment(UserPreferences.self) private var userPreferences

  @Binding var routerPath: RouterPath
  
  @Namespace private var transition

  var body: some ToolbarContent {
    if !isSecondaryColumn {
      statusEditorToolbarItem(
        routerPath: routerPath,
        visibility: userPreferences.postVisibility)
      ToolbarItem(placement: .navigationBarLeading) {
        AppAccountsSelectorView(
            transition: transition,
            routerPath: routerPath,
            avatarConfig: .embed)
        }
      }
    if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
      if (!isSecondaryColumn && !userPreferences.showiPadSecondaryColumn) || isSecondaryColumn {
        SecondaryColumnToolbarItem()
      }
    }
  }
}
