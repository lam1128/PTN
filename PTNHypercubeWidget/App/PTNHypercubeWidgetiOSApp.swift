#if os(iOS)
import SwiftUI

@main
struct PTNHypercubeWidgetiOSApp: App {
    @StateObject private var store = AppStateStore()

    var body: some Scene {
        WindowGroup {
            MainWidgetView(store: store)
                .ignoresSafeArea(edges: .bottom)
                .preferredColorScheme(.light)
        }
    }
}
#endif
