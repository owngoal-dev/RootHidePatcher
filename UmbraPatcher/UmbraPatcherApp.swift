import SwiftUI

@main
struct UmbraPatcherApp: App {
  @StateObject private var session = ConversionSession()

  var body: some Scene {
    WindowGroup {
      ContentView(session: session)
    }
  }
}
