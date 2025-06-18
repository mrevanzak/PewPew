import SwiftUI

struct Card<Content: View>: View {
  @ViewBuilder let content: Content
  let alignment: HorizontalAlignment

  init(alignment: HorizontalAlignment = .center, @ViewBuilder content: () -> Content) {
    self.alignment = alignment
    self.content = content()
  }

  var body: some View {
    VStack(alignment: alignment, spacing: 4) {
      content
    }
    .padding(12)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}
