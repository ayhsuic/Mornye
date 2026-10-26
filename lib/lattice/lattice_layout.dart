import 'dart:math';

/// 晶格瓦片：画布坐标中的一个封面单元。
class LatticeTile {
  const LatticeTile({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.index,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// 对应 [LatticeAlbum] 列表下标（骨架中不越界）。
  final int index;
}

/// 行内切分模式（宽度权重，内部归一化到 1）。
/// 相邻行循环不同模式，避免视觉重复。
const List<List<double>> _rowPatterns = [
  [0.45, 0.55],
  [0.30, 0.40, 0.30],
  [0.60, 0.40],
  [0.25, 0.50, 0.25],
  [0.35, 0.65],
  [0.40, 0.25, 0.35],
];

/// 行高档位（视口高度比例）：大小封面交错，接近 Folia 晶格的错落感。
const List<double> _rowHeightSteps = [0.33, 0.50, 0.62, 0.38, 0.55];

/// 生成"占满屏幕、不同尺寸交错"的晶格瓦片布局。
///
/// 画布总高 = [viewportHeight] × [pageCount]（多屏内容，靠平移浏览）。
/// 行高与行内切分按 [seed] 伪随机轮换，同一输入下结果稳定
/// （同一队列每次打开布局一致）。
List<LatticeTile> buildLatticeTiles({
  required int count,
  required double viewportWidth,
  required double viewportHeight,
  required int pageCount,
  required int seed,
}) {
  final rng = Random(seed);
  final tiles = <LatticeTile>[];
  const gap = 6.0;
  final canvasHeight = viewportHeight * max(1, pageCount).toDouble();

  var top = 0.0;
  var index = 0;
  var patternIdx = rng.nextInt(_rowPatterns.length);
  var heightIdx = rng.nextInt(_rowHeightSteps.length);

  while (top < canvasHeight && index < count) {
    final pattern = _rowPatterns[patternIdx];
    final rowHeight = max(viewportHeight * _rowHeightSteps[heightIdx], 90.0);
    final totalWeight = pattern.fold<double>(0, (a, b) => a + b);
    var left = 0.0;

    for (var i = 0; i < pattern.length && index < count; i++) {
      // 轻微错落：单元宽度与位置小幅抖动，打破整齐网格的"方块感"。
      final jitter = rng.nextDouble() * 0.04;
      final w = viewportWidth * pattern[i] / totalWeight;
      tiles.add(
        LatticeTile(
          left: left + jitter,
          top: top,
          width: w - jitter,
          height: rowHeight,
          index: index,
        ),
      );
      index++;
      left += w;
    }

    top += rowHeight + gap;
    // 下一行使用不同的模式与行高（避免相邻行雷同）。
    patternIdx =
        (patternIdx + 1 + rng.nextInt(_rowPatterns.length - 1)) %
        _rowPatterns.length;
    heightIdx =
        (heightIdx + 1 + rng.nextInt(_rowHeightSteps.length - 1)) %
        _rowHeightSteps.length;
  }

  return tiles;
}
