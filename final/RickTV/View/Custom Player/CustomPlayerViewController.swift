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
import MediaPlayer

/// The Set of custom player controllers currently using or transitioning out of PiP
private var activeCustomPlayerViewControllers = Set<CustomPlayerViewController>()

public class CustomPlayerViewController: UIViewController {
  weak var delegate: CustomPlayerViewControllerDelegate?

  public var player: AVPlayer? {
    didSet {
      playerLayer = AVPlayerLayer(player: player)
    }
  }

  private var playerLayer: AVPlayerLayer?
  private var pictureInPictureController: AVPictureInPictureController?
  private var controlsView: CustomPlayerControlsView?

  init() {
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    guard let playerLayer = playerLayer else {
      fatalError("Missing AVPlayerLayer")
    }

    view.backgroundColor = .black
    view.layer.addSublayer(playerLayer)

    pictureInPictureController = AVPictureInPictureController(
      playerLayer: playerLayer)
    pictureInPictureController?.delegate = self

    let tapGestureRecognizer = UITapGestureRecognizer(
      target: self,
      action: #selector(tapGestureHandler))


    #if os(tvOS)
    tapGestureRecognizer.allowedTouchTypes = [UITouch.TouchType.indirect].map { $0.rawValue as NSNumber
    }
    tapGestureRecognizer.allowedPressTypes = []
    #endif

    view.addGestureRecognizer(tapGestureRecognizer)

    setupNowPlayingInfo()
    addRemoteCommandEvent()
  }

  override public func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    playerLayer?.frame = view.bounds
  }

  @objc private func tapGestureHandler(recognizer: UITapGestureRecognizer) {
    switch recognizer.state {
    case .ended:
      if controlsView == nil {
        showControls()
      } else {
        hideControls()
      }
    default:
      break
    }
  }

  private func showControls() {
    let controlsView = CustomPlayerControlsView(player: player, pipController: pictureInPictureController)
    controlsView.delegate = self
    controlsView.translatesAutoresizingMaskIntoConstraints = false

    controlsView.alpha = 0.0

    let controlsViewHeight: CGFloat = 180.0

    view.addSubview(controlsView)
    NSLayoutConstraint.activate([
      controlsView.heightAnchor.constraint(equalToConstant: controlsViewHeight),
      controlsView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 90),
      controlsView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -90),
      controlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -60)
    ])

    UIView.animate(withDuration: 0.25) {
      controlsView.alpha = 1.0
    }

    self.controlsView = controlsView

    // Set the additional bottom safe area inset to the height of the custom UI so existing PiP windows avoid it.
    additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: controlsViewHeight, right: 0)
  }

  private func hideControls() {
    guard let controlsView = controlsView else { return }

    UIView.animate(withDuration: 0.25) {
      controlsView.alpha = 0.0
    } completion: { _ in
      controlsView.removeFromSuperview()
      self.controlsView = nil
    }

    // Reset the safe area inset to its default value.
    additionalSafeAreaInsets = .zero
  }

  
}

// MARK: For Remote Command
extension CustomPlayerViewController {
  func setupNowPlayingInfo() {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = [
        MPMediaItemPropertyTitle: "Never Gonna Give Up",
        MPMediaItemPropertyArtist : "Rick",
//        MPNowPlayingInfoPropertyPlaybackRate : NSNumber(value: 1.0), //再生レート
//        MPMediaItemPropertyPlaybackDuration : player?.currentItem?.duration ?? NSNumber(value: 0) //シークバー
    ]
  }

  func addRemoteCommandEvent() {
      let commandCenter = MPRemoteCommandCenter.shared()
      commandCenter.togglePlayPauseCommand.addTarget(handler: { [unowned self] commandEvent -> MPRemoteCommandHandlerStatus in
          self.remoteTogglePlayPause(commandEvent)
          return MPRemoteCommandHandlerStatus.success

      })
      commandCenter.playCommand.addTarget(handler: { [unowned self] commandEvent -> MPRemoteCommandHandlerStatus in
          self.remotePlay(commandEvent)
        player?.play()
          return MPRemoteCommandHandlerStatus.success
      })
      commandCenter.pauseCommand.addTarget(handler: { [unowned self] commandEvent -> MPRemoteCommandHandlerStatus in
          self.remotePause(commandEvent)
        player?.pause()
          return MPRemoteCommandHandlerStatus.success
      })
  }

  func remoteTogglePlayPause(_ event: MPRemoteCommandEvent) {
      // イヤホンのセンターボタンを押した時の処理
      print("イヤホンのセンターボタンを押した時の処理")
    // Do nothing
  }

  func remotePlay(_ event: MPRemoteCommandEvent) {
      // プレイボタンが押された時の処理
      print("プレイボタンが押された時の処理")
      // （今回は再生をおこなっています）
    player?.play()

  }

  func remotePause(_ event: MPRemoteCommandEvent) {
      // ポーズボタンが押された時の処理
      print("ポーズが押された時の処理")
      // （今回は停止をおこなっています）
    player?.pause()
  }
}

extension CustomPlayerViewController: CustomPlayerControlsViewDelegate {
  func controlsViewDidRequestStartPictureInPicture(
    _ controlsView: CustomPlayerControlsView
  ) {
    pictureInPictureController?.startPictureInPicture()
    hideControls()
  }

  func controlsViewDidRequestStopPictureInPicture(
    _ controlsView: CustomPlayerControlsView
  ) {
    pictureInPictureController?.stopPictureInPicture()
    hideControls()
  }

  func controlsViewDidRequestControlsDismissal(
    _ controlsView: CustomPlayerControlsView
  ) {
    hideControls()
  }

  func controlsViewDidRequestPlayerDismissal(
    _ controlsView: CustomPlayerControlsView
  ) {
    player?.rate = 0
    dismiss(animated: true)
  }
}

// MARK: - AVPictureInPictureDelegate

extension CustomPlayerViewController: AVPictureInPictureControllerDelegate {
  public func pictureInPictureControllerWillStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    activeCustomPlayerViewControllers.insert(self)
  }

  public func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    dismiss(animated: true, completion: nil)
  }

  public func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    activeCustomPlayerViewControllers.remove(self)
  }

  public func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    activeCustomPlayerViewControllers.remove(self)
  }

  public func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  ) {
    delegate?.playerViewController(
      self,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
  }
}

protocol CustomPlayerViewControllerDelegate: AnyObject {
  func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(
    _ playerViewController: CustomPlayerViewController
  ) -> Bool

  func playerViewController(
    _ playerViewController: CustomPlayerViewController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  )
}
