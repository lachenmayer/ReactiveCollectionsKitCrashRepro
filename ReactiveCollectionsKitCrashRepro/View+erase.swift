// Copyright (c) 2024 Picnic Ventures, Ltd.

import SwiftUI

extension View {
  func erase() -> AnyView {
    AnyView(erasing: self)
  }
}
