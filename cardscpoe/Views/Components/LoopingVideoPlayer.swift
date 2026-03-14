import SwiftUI
import AVKit

/// 循环、静音播放的视频视图，适用于 Paywall 等展示场景。
enum VideoFillMode {
    case aspectFit   // 完整显示，可能留黑边
    case aspectFill  // 铺满区域，可能裁剪
}

struct LoopingVideoPlayer: View {
    let url: URL?
    var fillMode: VideoFillMode = .aspectFill

    var body: some View {
        LoopingVideoPlayerRepresentable(url: url, fillMode: fillMode)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LoopingVideoPlayerRepresentable: UIViewRepresentable {
    let url: URL?
    let fillMode: VideoFillMode

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(fillMode: fillMode)
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let playerView = uiView as? PlayerUIView else { return }
        playerView.configure(url: url)
    }
}

private final class PlayerUIView: UIView {
    private var playerLooper: AVPlayerLooper?
    private var currentURL: URL?
    private let fillMode: VideoFillMode

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    init(fillMode: VideoFillMode = .aspectFill) {
        self.fillMode = fillMode
        super.init(frame: .zero)
    }

    override init(frame: CGRect) {
        self.fillMode = .aspectFill
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        self.fillMode = .aspectFill
        super.init(coder: coder)
    }

    func configure(url: URL?) {
        guard let url = url, url != currentURL else { return }
        currentURL = url

        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.isMuted = true
        queuePlayer.volume = 0

        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        self.playerLooper = looper

        if let layer = self.layer as? AVPlayerLayer {
            layer.player = queuePlayer
            layer.videoGravity = fillMode == .aspectFill ? .resizeAspectFill : .resizeAspect
        }

        queuePlayer.play()
    }
}
