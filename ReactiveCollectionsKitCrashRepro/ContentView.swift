// Copyright (c) 2024 Picnic Ventures, Ltd.

import CompositionalLayoutDSL
import SwiftUI

struct ContentView: View {
  @State private var showList = true
  @State private var change = 1

  var body: some View {
    Group {
      if showList {
        CollectionView(
          cells: (0 ... 100_000).map { $0 * change },
          cellView: {
            Cell(n: $0).erase()
          },
          layout: {
            CollectionViewLayouts.squareGrid(columnCount: 3)
          },
          headerView: {
            Header().erase()
          },
          headerLayout: {
            $0.height(.absolute(50))
          }
        )
      } else {
        Spacer()
      }
    }
    .task {
      var i = 0
      while true {
        try? await Task.sleep(for: .milliseconds(10))
        i += 1
        change = i
      }
    }
    .task {
      while true {
        try? await Task.sleep(for: .milliseconds(50))
        showList.toggle()
      }
    }
  }
}

#Preview { ContentView() }

private struct Cell: View {
  let n: Int

  var body: some View {
    Text("\(n)")
  }
}

private struct Header: View {
  var body: some View {
    Text("header")
  }
}
