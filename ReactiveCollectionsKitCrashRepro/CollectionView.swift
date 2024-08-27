// Copyright (c) 2024 Picnic Ventures, Ltd.

import CompositionalLayoutDSL
import ReactiveCollectionsKit
import SwiftUI
import UIKit

@MainActor
struct CollectionView: UIViewControllerRepresentable {
  let scrollDirection: UICollectionView.ScrollDirection
  let showScrollIndicators: Bool
  let sections: [CollectionSection]

  init(
    _ scrollDirection: UICollectionView.ScrollDirection = .vertical,
    showScrollIndicators: Bool = true,
    sections: [CollectionSection]
  ) {
    self.scrollDirection = scrollDirection
    self.showScrollIndicators = showScrollIndicators
    self.sections = sections
  }

  /// Single section.
  init<CellProps>(
    _ scrollDirection: UICollectionView.ScrollDirection = .vertical,
    showScrollIndicators: Bool = true,
    cells cellProps: [CellProps],
    cellView: @escaping (CellProps) -> AnyView,
    layout: @escaping () -> LayoutSection
  ) where CellProps: Equatable, CellProps: Hashable, CellProps: Identifiable {
    self.scrollDirection = scrollDirection
    self.showScrollIndicators = showScrollIndicators
    let cells = cellProps
      .map { props in CollectionCell(id: props.id, props: props, view: cellView) }
    self.sections = [CollectionSection(id: 0, cells: cells, layout: layout)]
  }

  /// Single section & header.
  init<CellProps>(
    _ scrollDirection: UICollectionView.ScrollDirection = .vertical,
    showScrollIndicators: Bool = true,
    cells cellProps: [CellProps],
    cellView: @escaping (CellProps) -> AnyView,
    layout: @escaping () -> LayoutSection,
    headerView: @escaping () -> AnyView,
    headerLayout: @escaping CollectionHeaderLayout = { header in header }
  ) where CellProps: Equatable, CellProps: Hashable, CellProps: Identifiable {
    self.scrollDirection = scrollDirection
    self.showScrollIndicators = showScrollIndicators
    let cells = cellProps
      .map { props in CollectionCell(id: props.id, props: props, view: cellView) }
    let header = CollectionHeader(
      id: 0,
      props: 0,
      view: { _ in headerView() },
      layout: headerLayout
    )
    self.sections = [CollectionSection(id: 0, cells: cells, header: header, layout: layout)]
  }

  var layout: UICollectionViewCompositionalLayout {
    LayoutBuilder {
      CompositionalLayout { sectionIndex, environment -> LayoutSection? in
        let section = sections[sectionIndex]
        let layout = section.layout()
        guard let headerLayout = section.headerLayout else { return layout }
        let header = headerLayout(
          BoundarySupplementaryItem(elementKind: UICollectionView.elementKindSectionHeader)
        )
        return layout.boundarySupplementaryItems {
          header
        }
      }
      .scrollDirection(scrollDirection)
    }
  }

  func makeUIViewController(context: Context) -> CollectionViewController {
    let controller = CollectionViewController(layout: layout)
    controller.sync(self)
    return controller
  }

  func updateUIViewController(_ controller: CollectionViewController, context: Context) {
    controller.sync(self)
  }
}

@MainActor
final class CollectionViewController: UICollectionViewController {
  private lazy var driver = CollectionViewDriver(view: self.collectionView)

  init(layout: UICollectionViewLayout) {
    super.init(collectionViewLayout: layout)
    self.collectionView.backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func sync(_ view: CollectionView) {
    driver.update(viewModel: CollectionViewModel(id: 0, sections: view.sections.map(\.viewModel)))
    collectionView.setCollectionViewLayout(view.layout, animated: false)
    collectionView.showsHorizontalScrollIndicator = view.showScrollIndicators
    collectionView.showsVerticalScrollIndicator = view.showScrollIndicators
  }
}

@MainActor
struct CollectionSection {
  let id: UniqueIdentifier
  let layout: () -> LayoutSection
  let headerLayout: CollectionHeaderLayout?

  private let cells: [AnyCellViewModel]
  private let header: AnySupplementaryViewModel?

  init<CellProps>(
    id: UniqueIdentifier,
    cells: [CollectionCell<CellProps>],
    layout: @escaping () -> LayoutSection
  ) {
    self.id = id
    self.cells = cells.map { $0.eraseToAnyViewModel() }
    self.layout = layout
    self.header = nil
    self.headerLayout = nil
  }

  init<CellProps, HeaderProps>(
    id: UniqueIdentifier,
    cells: [CollectionCell<CellProps>],
    header: CollectionHeader<HeaderProps>,
    layout: @escaping () -> LayoutSection
  ) {
    self.id = id
    self.cells = cells.map { $0.eraseToAnyViewModel() }
    self.layout = layout
    self.header = header.eraseToAnyViewModel()
    self.headerLayout = header.layout
  }

  fileprivate var viewModel: SectionViewModel {
    SectionViewModel(id: id, cells: cells, header: header, footer: nil)
  }
}

struct CollectionCell<Props>: CellViewModel where Props: Equatable, Props: Hashable {
  let id: UniqueIdentifier
  let props: Props
  let view: (Props) -> AnyView

  static func == (lhs: CollectionCell, rhs: CollectionCell) -> Bool {
    lhs.id == rhs.id && lhs.props == rhs.props
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(props)
  }

  func configure(cell: AnyViewCell) {
    cell.sync(view: view(props))
  }
}

typealias CollectionHeaderLayout =
  ((BoundarySupplementaryItem) -> any LayoutBoundarySupplementaryItem)

struct CollectionHeader<Props>: SupplementaryHeaderViewModel where Props: Equatable,
  Props: Hashable
{
  let id: UniqueIdentifier
  let props: Props
  let view: (Props) -> AnyView
  let layout: CollectionHeaderLayout

  static func == (lhs: CollectionHeader, rhs: CollectionHeader) -> Bool {
    lhs.id == rhs.id && lhs.props == rhs.props
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(props)
  }

  func configure(view v: AnyViewCell) {
    v.sync(view: view(props))
  }
}

class AnyViewCell: UICollectionViewCell {
  private let hostingController = UIHostingController<AnyView?>(rootView: nil)

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(hostingController.view)
    hostingController.view.frame = contentView.bounds
    hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    hostingController.view.backgroundColor = nil
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func sync(view: AnyView) {
    hostingController.rootView = view
  }
}
