# Lattice 晶格网格播放视图

本目录是「Folia 拼贴播放界面」的 Flutter 移植，对应需求：
**底部悬浮播放栏点击 → 全屏 Lattice 晶格网格；专辑封面从方形改为占满屏幕，不同尺寸交错拼贴，可到处滑动。**

## 文件说明

| 文件 | 职责 |
|---|---|
| `lattice_album.dart` | 数据模型：一个专辑/封面的最小字段（id/标题/封面/是否播放/点击回调） |
| `lattice_layout.dart` | 布局生成器：按视口生成"不同尺寸交错、铺满 N 屏"的晶格瓦片（固定种子，布局稳定） |
| `lattice_playback_view.dart` | 主视图：`InteractiveViewer` 平移 + 封面单元 + 播放呼吸光晕 + 标题条 |

**依赖**：仅 `flutter/material` + 项目内已有 `cached_network_image`（封面缓存），
不引用其他 Mornye 内部符号。

## 接入状态（已完成）

入口链（`lib/screens/now_playing_screen.dart`）：

- 移动端路由打开播放页 **默认进入 Lattice 晶格网格**（`_latticeMode = !embedded`）；
- 数据适配：`_aggregateLatticeAlbums` 从 `playQueueProvider`（`StreamProvider<List<MediaItem>>`）
  按专辑去重聚合 → `List<LatticeAlbum>`；
  - `coverUrl` 取 `item.artUri`（本地/WebDAV/在线封面地址统一由 Mornye 封面链路给出）；
  - `isPlaying` 跟随 `currentMediaItemProvider`（正在播放的专辑带呼吸光晕）；
  - `onTap` 点击封面 → `musicPlayerControllerProvider.jumpTo(i)` 跳转到该专辑首曲；
- 顶栏两个按钮：
  - 收起（复用 `_minimize`：路由场景 pop，桌面场景收进内容面板）；
  - 切回经典播放页（`_latticeMode = false`，可随时切换回来）；
- 过渡动效全部沿用 `NowPlayingRoute`，未改动；
- 桌面嵌入面板（`embedded`）保持经典布局，不启用 Lattice。

**手势说明**：Lattice 的 `InteractiveViewer` 会抢占垂直拖拽，
`NowPlayingRoute` 的下拉关闭在 Lattice 模式下由「收起」按钮承担；经典模式保留下拉关闭。

## 已知缺口（按优先级）

1. **惯性滑动**：`InteractiveViewer` 拖动松手即停，无 Folia 式惯性减速。
   体验不足时换成自绘 `GestureDetector`（onPanUpdate + `AnimationController` +
   `FrictionSimulation`），本视图的瓦片坐标已与画布解耦，替换成本低。
2. **进场动画**：瓦片 stagger 入场未实现（当前直接呈现）。后续可加
   `AnimationController` + 逐个 `FadeTransition/ScaleTransition`。
3. **布局档位**：`_rowPatterns` / `_rowHeightSteps` 是写死的模式表；
   想更"晶格感"可改成面积分割（golden-ratio 递归切分）算法。
4. **专辑级播放语义**：点击封面目前跳到该专辑在队列中的首曲；
   若需要"只播该专辑"（临时队列）需另接入播放编排。

## 验证方式

- 本地以 `dart format` 校验过格式；完整 `flutter analyze` + 测试在 fork CI 执行；
- 真机验证项：平移/缩放、点击切歌、呼吸光晕、收起与视图切换、WebDAV 封面加载。

## 验证记录

- `flutter analyze` 与 3550+ 测试在 fork CI 全绿（run 40292370184，commit 4f06ce0）；
- 队列为空但有当前曲目时（如会话恢复/单曲播放），以单曲兜底展示晶格封面，
  避免全黑空屏；空态（无队列无当前曲目）显示提示文案。
