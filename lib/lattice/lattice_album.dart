import 'package:flutter/material.dart';

/// 晶格中的一个专辑/封面数据模型（骨架）。
///
/// 由调用方从播放队列按专辑聚合填充：
/// - [coverUrl] 为空时使用 [coverSeed] 生成渐变占位封面；
/// - [isPlaying] 标记当前播放的专辑（带呼吸光晕）；
/// - [onTap] 点击封面后的行为（切换播放）。
class LatticeAlbum {
  const LatticeAlbum({
    required this.id,
    required this.title,
    this.artist = '',
    this.coverUrl,
    this.coverSeed = 0,
    this.isPlaying = false,
    this.onTap,
  });

  /// 专辑唯一标识（用于列表 key 与去重）。
  final String id;

  final String title;

  final String artist;

  /// 远程封面地址（WebDAV / 本地 / 在线）。为空或不可加载时走占位封面。
  final String? coverUrl;

  /// 占位封面的颜色种子（同一专辑恒定，保证布局稳定）。
  final int coverSeed;

  /// 是否为当前正在播放的专辑。
  final bool isPlaying;

  /// 点击该封面触发（由调用方决定播放哪张专辑/切歌）。
  final VoidCallback? onTap;
}
