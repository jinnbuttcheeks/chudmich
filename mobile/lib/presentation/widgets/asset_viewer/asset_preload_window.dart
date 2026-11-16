/// Decides which neighbouring assets the viewer should keep warm.
///
/// The window is direction aware: after swiping forward the next assets are the
/// likely ones, so more of the budget goes ahead of the current index.
abstract final class AssetPreloadWindow {
  /// Number of assets kept behind and ahead of the direction of travel.
  static const int behind = 1;
  static const int ahead = 2;

  /// Indices to preload around [index], nearest first and in travel order.
  ///
  /// [direction] is the sign of the last page change (positive = forward). Zero
  /// (initial open) is treated as forward. Indices outside `0..total-1` and the
  /// current index itself are never returned.
  static List<int> indices({required int index, required int total, int direction = 0}) {
    final step = direction < 0 ? -1 : 1;
    final result = <int>[];
    for (var i = 1; i <= ahead; i++) {
      result.add(index + step * i);
    }
    for (var i = 1; i <= behind; i++) {
      result.add(index - step * i);
    }
    return result.where((i) => i >= 0 && i < total && i != index).toList();
  }
}
