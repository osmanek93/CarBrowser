
import SwiftUI

@main
struct CarBrowserApp: App {
    var body: some Scene {
        WindowGroup {
            BrowserView()
                .preferredColorScheme(.dark)
        }
    }
}
