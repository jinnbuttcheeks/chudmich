import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/providers/asset_viewer/video_player_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:native_video_player/native_video_player.dart';

class _MockController extends Mock implements NativeVideoPlayerController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('onNativeStatusChanged', () {
    const channel = 'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

    VideoPlayerNotifier build(PlaybackStatus status, int position) {
      // The wakelock plugin talks to a pigeon channel; answer it with a void success reply.
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMessageHandler(
        channel,
        (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]),
      );
      addTearDown(() => messenger.setMockMessageHandler(channel, null));
      final controller = _MockController();
      when(
        () => controller.playbackInfo,
      ).thenReturn(PlaybackInfo(status: status, position: position, positionFraction: 0.5, volume: 1, speed: 1));
      when(() => controller.seekTo(any())).thenAnswer((_) async {});
      final notifier = VideoPlayerNotifier()..attachController(controller);
      addTearDown(notifier.dispose);
      return notifier;
    }

    test('keeps the published position on pause, where a seek may still be in flight', () {
      final notifier = build(PlaybackStatus.paused, 4950)..onNativeStatusChanged();
      expect(notifier.state.position, Duration.zero);
    });

    test('publishes the exact position when playback ends', () {
      final notifier = build(PlaybackStatus.stopped, 5000)..onNativeStatusChanged();
      expect(notifier.state.status, VideoPlaybackStatus.completed);
      expect(notifier.state.position, const Duration(milliseconds: 5000));
    });

    test('leaves the position to the throttled feed while playing', () {
      final notifier = build(PlaybackStatus.playing, 4950)..onNativeStatusChanged();
      expect(notifier.state.position, Duration.zero);
    });

    for (final status in [PlaybackStatus.paused, PlaybackStatus.stopped]) {
      test('does not overwrite a seek with the stale native position on ${status.name}', () {
        final notifier = build(status, 1000)..seekTo(const Duration(seconds: 2));
        notifier.onNativeStatusChanged();
        expect(notifier.state.position, const Duration(seconds: 2));
      });
    }
  });

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
