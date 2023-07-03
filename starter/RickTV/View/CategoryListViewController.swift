/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import AVKit

class CategoryListViewController: UICollectionViewController {
  // MARK: - Properties
  private var dataProvider = DataProvider()
  private lazy var dataSource = makeDataSource()

  // MARK: - Value Types
  typealias DataSource = UICollectionViewDiffableDataSource<Category, Video>
  typealias Snapshot = NSDiffableDataSourceSnapshot<Category, Video>

  init() {
    super.init(collectionViewLayout: UICollectionViewLayout())
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    #if os(tvOS)
    collectionView.backgroundColor = .clear
    #else
    collectionView.backgroundColor = .systemBackground
    navigationItem.largeTitleDisplayMode = .automatic
    navigationController?.navigationBar.prefersLargeTitles = true
    #endif

    title = "Categories"

    configureLayout()
    applySnapshot(animatingDifferences: false)
  }

  // MARK: - Functions
  func makeDataSource() -> DataSource {
    collectionView.register(
      VideoCollectionViewCell.self,
      forCellWithReuseIdentifier: VideoCollectionViewCell.reuseIdentifier)

    let dataSource = DataSource(
      collectionView: collectionView
    ) { collectionView, indexPath, video ->
      UICollectionViewCell? in
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "VideoCollectionViewCell",
        for: indexPath) as? VideoCollectionViewCell
      cell?.video = video
      cell?.layoutSubviews()
      return cell
    }

    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
      guard kind == UICollectionView.elementKindSectionHeader else {
        return nil
      }
      let section = self.dataSource.snapshot()
        .sectionIdentifiers[indexPath.section]
      let view = collectionView.dequeueReusableSupplementaryView(
        ofKind: kind,
        withReuseIdentifier: SectionHeaderReusableView.reuseIdentifier,
        for: indexPath) as? SectionHeaderReusableView
      view?.titleLabel.text = section.title
      return view
    }
    return dataSource
  }

  func applySnapshot(animatingDifferences: Bool = true) {
    var snapshot = Snapshot()
    snapshot.appendSections(dataProvider.categories)

    dataProvider.categories.forEach { category in
      snapshot.appendItems(category.videos, toSection: category)
    }

    dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
  }
}

// MARK: - UICollectionViewDataSource Implementation
extension CategoryListViewController {
  override func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    guard let videoURL = Bundle.main.url(forResource: "rick", withExtension: "mp4") else {
      return
    }

    let item = AVPlayerItem(url: videoURL)
    let player = AVQueuePlayer(playerItem: item)

    player.actionAtItemEnd = .pause

    presentPlayerController(with: player, customPlayer: false)
  }

  func presentPlayerController(with player: AVPlayer, customPlayer: Bool = false) {
    let controller: UIViewController

    if customPlayer {
      let customController = CustomPlayerViewController()
      customController.delegate = self
      customController.player = player
      controller = customController
    } else {
      let avController = AVPlayerViewController()
      avController.delegate = self
      avController.player = player
      controller = avController
    }

    present(controller, animated: true) {
      player.play()
    }
  }
}

// MARK: - Layout Handling
extension CategoryListViewController {
  private func configureLayout() {
    collectionView.register(
      SectionHeaderReusableView.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: SectionHeaderReusableView.reuseIdentifier)

    let layout = UICollectionViewCompositionalLayout { _, layoutEnvironment -> NSCollectionLayoutSection? in
      let isPhone = layoutEnvironment.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiom.phone
      let size = NSCollectionLayoutSize(
        widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
        heightDimension: NSCollectionLayoutDimension.absolute(isPhone ? 280 : 250))


      var itemCount = 1

      #if targetEnvironment(macCatalyst) || os(tvOS)
      let width = self.view.frame.width

      if width >= 1800 {
        itemCount = 6
      } else if width >= 1200 {
        itemCount = 4
      } else if width >= 1000 {
        itemCount = 3
      } else {
        itemCount = 2
      }

      #if os(tvOS)
      itemCount -= 1
      #endif

      #else
      let orientation = UIDevice.current.orientation
      if isPhone {
        itemCount = orientation == .landscapeRight || orientation == .landscapeLeft ? 2 : 1
      } else {
        itemCount = orientation == .portrait || orientation == .portraitUpsideDown ? 3 : 4
      }
      #endif

      let item = NSCollectionLayoutItem(layoutSize: size)
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: itemCount)
      let section = NSCollectionLayoutSection(group: group)
      section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
      #if os(tvOS)
      section.contentInsets.trailing = 20
      #endif
      // Supplementary header view setup
      let headerFooterSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(20))
      let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
        layoutSize: headerFooterSize,
        elementKind: UICollectionView.elementKindSectionHeader,
        alignment: .top)
      section.boundarySupplementaryItems = [sectionHeader]
      return section
    }

    collectionView.collectionViewLayout = layout
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.collectionView.collectionViewLayout.invalidateLayout()
    }, completion: nil)
  }
}

extension CategoryListViewController: AVPlayerViewControllerDelegate {
  @objc func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
    if let presentedViewController = presentedViewController as? AVPlayerViewController,
      presentedViewController == playerViewController {
      return true
    }
    return false
  }

  @objc func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
    // Dismiss the controller when PiP starts so that the user is returned to the item selection screen.
    return true
  }

  @objc func playerViewController(
    _ playerViewController: AVPlayerViewController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  ) {
    restore(playerViewController: playerViewController, completionHandler: completionHandler)
  }
}

extension CategoryListViewController: CustomPlayerViewControllerDelegate {
  func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: CustomPlayerViewController) -> Bool {
    // Dismiss the controller when PiP starts so that the user is returned to the item selection screen.
    return true
  }

  func playerViewController(
    _ playerViewController: CustomPlayerViewController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  ) {
    restore(playerViewController: playerViewController, completionHandler: completionHandler)
  }
}

extension CategoryListViewController {
  func restore(playerViewController: UIViewController, completionHandler: @escaping (Bool) -> Void) {
    // TODO: Restore player from PiP
  }
}
