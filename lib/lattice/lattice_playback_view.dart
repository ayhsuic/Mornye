import 'package:flutter/material.dart';

import 'lattice_album.dart';
import 'lattice_layout.dart';

/// 全屏 Lattice 晶格网格视图（骨架）。
///
/// 设计意图（对应需求）：
/// - 从底部悬浮播放栏点击进入后，本视图即全屏播放内容层；
/// - 专辑封面不再 1:1 小方块，而是不同尺寸交错拼贴、占满屏幕；
/// - 单指拖动可在画布内任意方向滑动（[InteractiveViewer]，
///   [boundaryMargin] 放行多屏浏览）；
/// - 点封面触发切换播放；当前播放专辑带呼吸光晕。
///
/// 接入方式（详见同目录 README.md）：
/// 把本组件作为全屏播放器的内容层，数据经 [albums] 从播放队列按专辑聚合。
/// 本文件不依赖 Mornye 任何内部符号，可独立编译；接入后建议
/// `flutter analyze` 复核。
class LatticePlaybackView extends StatefulWidget {
  const LatticePlaybackView({
    super.key,
    this.albums = const [],
    this.pageCount = 3,
    this.panEnabled = true,
    this.playingGlow = true,
  });

  /// 晶格数据源（队列 → 专辑去重后填充）。
  final List<LatticeAlbum> albums;

  /// 画布屏数：内容高度 = 视口高度 × [pageCount]，超出部分靠平移浏览。
  final int pageCount;

  /// 是否允许平移（调试/预览时可关）。
  final bool panEnabled;

  /// 当前播放专辑是否显示呼吸光晕。
  final bool playingGlow;

  @override
  State<LatticePlaybackView> createState() => _LatticePlaybackViewState();
}

class _LatticePlaybackViewState extends State<LatticePlaybackView>
    with SingleTickerProviderStateMixin {
  /// 呼吸光晕动画：正在播放的封面周期性放大/发光。
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) return const SizedBox.shrink();

        // 固定种子：同一队列每次打开布局一致（不随随机漂移）。
        const seed = 0x5eed;
        final tiles = buildLatticeTiles(
          count: widget.albums.length,
          viewportWidth: width,
          viewportHeight: height,
          pageCount: widget.pageCount,
          seed: seed,
        );
        final canvasHeight = height * widget.pageCount.toDouble();

        return SizedBox(
          width: width,
          height: canvasHeight,
          child: InteractiveViewer(
            panEnabled: widget.panEnabled,
            scaleEnabled: true,
            minScale: 0.8,
            maxScale: 2.5,
            // 允许画布四方向都滑出视口：实现"到处滑"。
            boundaryMargin: EdgeInsets.all(width * 0.5),
            clipBehavior: Clip.none,
            constrained: false,
            child: Stack(
              children: [
                for (final tile in tiles)
                  Positioned(
                    left: tile.left,
                    top: tile.top,
                    width: tile.width,
                    height: tile.height,
                    child: _LatticeCell(
                      album: widget.albums[tile.index],
                      glow: widget.playingGlow ? _glow : null,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 单个晶格封面单元：封面图（或渐变占位）+ 播放光晕 + 标题条 + 点击。
class _LatticeCell extends StatelessWidget {
  const _LatticeCell({required this.album, this.glow});

  final LatticeAlbum album;
  final Animation<double>? glow;

  @override
  Widget build(BuildContext context) {
    final cover = _buildCover();
    return GestureDetector(
      onTap: album.onTap,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            cover,
            if (album.isPlaying && glow != null)
              _PlayingGlow(animation: glow!),
            // 底部标题条：半透明渐变，保证深色/浅色封面下都可读。
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (album.artist.isNotEmpty)
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    final url = album.coverUrl;
    if (url == null || url.isEmpty) {
      return _PlaceholderCover(seed: album.coverSeed);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      // 加载失败自动降级为渐变占位（如离线/服务器不可达）。
      errorBuilder: (_, __, ___) => _PlaceholderCover(seed: album.coverSeed),
    );
  }
}

/// 正在播放封面的呼吸光晕。
class _PlayingGlow extends StatelessWidget {
  const _PlayingGlow({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.22 + t * 0.32),
                blurRadius: 16 + t * 14,
                spreadRadius: 2 + t * 3,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 无封面时的渐变占位：按 [seed] 稳定取色，视觉上近似"专辑色块"。
class _PlaceholderCover extends StatelessWidget {
  const _PlaceholderCover({required this.seed});

  final int seed;

  static const List<int> _hues = [320, 265, 210, 160, 90, 35, 12];

  @override
  Widget build(BuildContext context) {
    final h1 = _hues[seed % _hues.length];
    final h2 = _hues[(seed ~/ 7) % _hues.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, h1.toDouble(), 0.72, 0.62).toColor(),
            HSLColor.fromAHSL(1, h2.toDouble(), 0.80, 0.42).toColor(),
          ],
        ),
      ),
    );
  }
}
