import Foundation

public enum AppInfo {
  public static let appStoreAppId = "6444915884"
  public static let clientName = "IceCubesApp"
  public static let scheme = "icecubesapp://"
  public static let scopes = "read write follow push"
  public static let weblink = "https://github.com/Dimillian/IceCubesApp"
  public static let revenueCatKey = "appl_JXmiRckOzXXTsHKitQiicXCvMQi"
  public static let defaultServer = "mastodon.social"
  // Stage 1 runs the main app without extension targets, so we avoid inheriting
  // the original shared keychain access group and use the app's default group.
  public static let keychainGroup: String? = nil
}
