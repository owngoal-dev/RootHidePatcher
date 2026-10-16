import SwiftUI

@main
struct DerootifierApp: App {
  @StateObject private var session = ConversionSession()

  var body: some Scene {
    WindowGroup {
      ContentView(session: session)
    }
  }
}
