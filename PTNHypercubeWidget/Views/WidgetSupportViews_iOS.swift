#if os(iOS)
import SwiftUI

/// The Mac version preserves an exact scroll offset. iOS uses the native
/// SwiftUI scroll container; the binding remains in the shared view so the
/// reward sections keep the same structure on both platforms.
struct ManagedScrollView<Content: View>: View {
    @Binding var scrollOffset: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct WindowDragHandle: View {
    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
