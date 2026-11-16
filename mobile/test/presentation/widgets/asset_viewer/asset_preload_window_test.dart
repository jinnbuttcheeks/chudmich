import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/asset_preload_window.dart';

void main() {
  List<int> window(int index, int total, [int direction = 0]) =>
      AssetPreloadWindow.indices(index: index, total: total, direction: direction);

  test('opening the viewer preloads two ahead and one behind, nearest first', () {
    expect(window(10, 100), [11, 12, 9]);
  });

  test('after swiping backwards the window mirrors', () {
    expect(window(10, 100, -1), [9, 8, 11]);
  });

  test('forward direction matches the initial window', () {
    expect(window(10, 100, 1), window(10, 100));
  });

  test('clamps at the first asset', () {
    expect(window(0, 100), [1, 2]);
    expect(window(0, 100, -1), [1]);
  });

  test('clamps at the last asset', () {
    expect(window(99, 100), [98]);
    expect(window(99, 100, -1), [98, 97]);
  });

  test('never includes the current index and handles tiny timelines', () {
    expect(window(0, 1), isEmpty);
    expect(window(1, 2), [0]);
    expect(window(5, 100).contains(5), isFalse);
  });

  test('window plus current fits the large image cache (5 entries)', () {
    expect(AssetPreloadWindow.ahead + AssetPreloadWindow.behind + 1, lessThanOrEqualTo(5));
  });
}
