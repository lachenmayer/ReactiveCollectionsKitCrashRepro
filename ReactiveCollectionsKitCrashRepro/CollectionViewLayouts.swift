// Copyright (c) 2024 Picnic Ventures, Ltd.

import CompositionalLayoutDSL
import UIKit

enum CollectionViewLayouts {
  static func squareGrid(columnCount: Int) -> any LayoutSection {
    let cellSize = NSCollectionLayoutDimension.fractionalWidth(1.0 / Double(columnCount))
    return Section {
      HGroup(count: columnCount) {
        Item(width: cellSize, height: cellSize)
      }
      .height(cellSize)
    }
  }
}
