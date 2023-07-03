/// Copyright (c) 2020 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class VideoCollectionViewCell: UICollectionViewCell {
  private lazy var thumbnailView: UIImageView = {
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 8
    imageView.layer.cornerCurve = .continuous
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    return imageView
  }()

  private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 1
    #if os(tvOS)
    label.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
    #else
    label.font = UIFont.preferredFont(forTextStyle: .headline)
    #endif
    return label
  }()

  private lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    #if os(tvOS)
    label.font = UIFont.systemFont(ofSize: 28, weight: .regular)
    #else
    label.font = UIFont.preferredFont(forTextStyle: .body)
    #endif
    return label
  }()

  var video: Video? {
    didSet {
      thumbnailView.layer.shadowOffset = CGSize(width: 2, height: 2)
      thumbnailView.layer.shadowRadius = 10
      thumbnailView.layer.shadowOpacity = 0.3

      thumbnailView.image = UIImage(named: video?.thumbnailName ?? "")
      titleLabel.text = video?.title
      subtitleLabel.text = video?.description
    }
  }

  public static var reuseIdentifier: String {
    return String(describing: self)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(thumbnailView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(subtitleLabel)

    layoutSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    var spacing: CGFloat = 8
    #if os(tvOS)
    spacing = 12
    #endif

    NSLayoutConstraint.activate([
      thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
      thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
      thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
      thumbnailView.heightAnchor.constraint(lessThanOrEqualTo: contentView.heightAnchor, multiplier: 3 / 4),

      titleLabel.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 5),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
    ])
  }

  #if os(tvOS)
  override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    let propertyAnimator: UIViewPropertyAnimator

    if isFocused {
      propertyAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
        self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
      }
    } else {
      propertyAnimator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) {
        self.transform = .identity
      }
    }

    propertyAnimator.startAnimation()
  }
  #endif
}
