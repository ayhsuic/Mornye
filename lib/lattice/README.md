# Lattice 晶格网格播放视图（骨架）

本目录是「Folia 拼贴播放界面」的 Flutter 移植骨架，对应需求：
**底部悬浮播放栏点击 → 全屏 Lattice 晶格网格；专辑封面从方形改为占满屏幕，不同尺寸交错拼贴，可到处滑动。**

## 文件说明

| 文件 | 职责 |
|---|---|
| `lattice_album.dart` | 数据模型：一个专辑/封面的最小字段（id/标题/封面/是否播放/点击回调） |
| `lattice_layout.dart` | 布局生成器：按视口生成"不同尺寸交错、铺满 N 屏"的晶格瓦片（固定种子，布局稳定） |
| `lattice_playback_view.dart` | 主视图：`InteractiveViewer` 平移 + 封面单元 + 播放呼吸光晕 + 标题条 |

**零新增依赖**：只用 Flutter SDK 自带能力（`InteractiveViewer` / `AnimationController` /
`HSLColor` 等），不引用 Mornye 内部符号——拷贝进 `lib/` 后 `flutter analyze` 可直接通过。

## 接入方式（两步）

### 1. 数据适配（调用方填充 `List<LatticeAlbum>`）

从 Mornye 的播放队列按专辑去重聚合，示例骨架：

```dart
final albums = [
  for (final album in queueAlbums)
    LatticeAlbum(
      id: album.id,
      title: album.title,
      artist: album.artist,
      coverUrl: album.coverUrl,   // WebDAV/本地/在线封面地址
      coverSeed: album.id.hashCode,
      isPlaying: album.id == currentAlbumId,
      onTap: () => playAlbum(album),
    ),
];
```

真实接入点建议：`lib/providers/playback_provider.dart` / `music_player_provider.dart`
（当前队列与当前歌曲/专辑的权威来源）。封面地址可复用 Mornye 现有封面解析链路
（本地封面落盘 + 网络封面缓存），无需本视图感知。

### 2. 替换全屏播放器内容层

Mornye 现有链路：底部迷你播放栏 → `NowPlayingRoute`
（`lib/routes/now_playing_route.dart`，含 Hero 封面展开/下拉关闭动效）→
`NowPlayingScreen`（`lib/screens/now_playing_screen.dart`）。

把 `NowPlayingScreen` 的默认内容区替换为：

```dart
LatticePlaybackView(albums: albums);
```

- 入口/过渡动效全部沿用 `NowPlayingRoute`，**不改动**；
- 下拉关闭、返回键行为由现有 Route 继续承担；
- 若要保留原播放器视图，可做成「拼贴 / 原视图」切换（例如右上角模式按钮）。

## 已知骨架缺口（按优先级）

1. **惯性滑动**：`InteractiveViewer` 拖动松手即停，无 Folia 式惯性减速。
   体验不足时换成自绘 `GestureDetector`（onPanUpdate + `AnimationController` +
   `FrictionSimulation`），本视图的瓦片坐标已与画布解耦，替换成本低。
2. **封面缓存**：骨架用 `Image.network`；正式版建议换成 Mornye 的封面缓存服务
   （避免 WebDAV 重复拉取大图）。
3. **进场动画**：瓦片 stagger 入场未实现（当前直接呈现）。后续可加
   `AnimationController` + 逐个 `FadeTransition/ScaleTransition`。
4. **布局档位**：`_rowPatterns` / `_rowHeightSteps` 是写死的模式表；
   想更"晶格感"可改成面积分割（golden-ratio 递归切分）算法。

## 验证方式

- 本机无 Flutter SDK，**未编译验证**；fork 后先 `flutter analyze lib/lattice/`，
  再真机跑一遍平移/点击/光晕。
