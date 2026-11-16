import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/providers/asset_viewer/video_player_provider.dart';

void main() {
  group('shouldPublishPosition', () {
    const published = Duration(seconds: 5);

    test('drops the 8 ms poll ticks between publishes', () {
      expect(
        VideoPlayerNotifier.shouldPublishPosition(published, published + const Duration(milliseconds: 8)),
        isFalse,
      );
      expect(
        VideoPlayerNotifier.shouldPublishPosition(published, published + const Duration(milliseconds: 99)),
        isFalse,
      );
    });

    test('publishes once the position moved a tenth of a second, in either direction', () {
      expect(
        VideoPlayerNotifier.shouldPublishPosition(published, published + const Duration(milliseconds: 100)),
        isTrue,
      );
      expect(
        VideoPlayerNotifier.shouldPublishPosition(published, published - const Duration(milliseconds: 100)),
        isTrue,
      );
    });

    test('a loop back to the start is published immediately', () {
      expect(VideoPlayerNotifier.shouldPublishPosition(const Duration(milliseconds: 40), Duration.zero), isTrue);
    });

    test('120 ticks at 8 ms publish about ten times', () {
      var last = Duration.zero;
      var publishes = 0;
      for (var ms = 8; ms <= 960; ms += 8) {
        final next = Duration(milliseconds: ms);
        if (VideoPlayerNotifier.shouldPublishPosition(last, next)) {
          last = next;
          publishes++;
        }
      }
      expect(publishes, lessThanOrEqualTo(10));
    });
  });
}
