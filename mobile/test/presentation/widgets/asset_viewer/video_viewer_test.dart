import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/domain/models/asset/base_asset.model.dart';
import 'package:immich_mobile/presentation/widgets/asset_viewer/video_viewer.widget.dart';
import 'package:immich_mobile/providers/infrastructure/storage.provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:native_video_player/native_video_player.dart';

import '../../../infrastructure/repository.mock.dart';
import '../../../unit/factories/local_asset_factory.dart';
import '../../../unit/factories/remote_asset_factory.dart';
import '../../../unit/presentation/presentation_context.dart';

void main() {
  late PresentationContext context;
  late MockStorageRepository storage;

  final local = LocalAssetFactory.create(id: 'local-1').copyWith(type: .video, playbackStyle: .video);
  final remote = RemoteAssetFactory.create(type: .video, localId: local.id);

  setUp(() async {
    context = await PresentationContext.create();
    storage = MockStorageRepository();
    final assets = context.service.asset.service;
    when(() => assets.getAsset(remote)).thenAnswer((_) async => remote);
    when(() => assets.getAsset(local)).thenAnswer((_) async => local);
    when(() => assets.getLocalAsset(local.id)).thenAnswer((_) async => local);
  });

  tearDown(() async {
    await context.dispose();
  });

  Future<VideoSource?> pumpViewer(WidgetTester tester, BaseAsset asset) async {
    await tester.pumpTestWidget(
      context,
      NativeVideoViewer(asset: asset, image: const SizedBox()),
      overrides: [storageRepositoryProvider.overrideWithValue(storage)],
      expectSettle: false,
    );
    return tester.state<NativeVideoViewerState>(find.byType(NativeVideoViewer)).videoSource;
  }

  testWidgets('plays the local file when it exists', (tester) async {
    final file = File('/videos/local-1.mp4');
    when(() => storage.getFileForAsset(local.id)).thenAnswer((_) async => file);

    final source = await pumpViewer(tester, remote);

    expect(source?.type, VideoSourceType.file);
    expect(source?.path, endsWith(file.path));
  });

  testWidgets('plays the server copy when the local file cannot be read', (tester) async {
    when(() => storage.getFileForAsset(local.id)).thenAnswer((_) async => null);

    final source = await pumpViewer(tester, remote);

    expect(source?.type, VideoSourceType.network);
    expect(source?.path, endsWith('/assets/${remote.id}/video/playback'));
  });

  testWidgets('gives up when a local only asset has no file', (tester) async {
    when(() => storage.getFileForAsset(local.id)).thenAnswer((_) async => null);

    final source = await pumpViewer(tester, local);

    expect(source, isNull);
  });

  group('paging', () {
    final surface = find.byType(NativeVideoPlayerView);

    setUp(() {
      // Platform view creation is a main-thread call on Android; tests only need it not to throw.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        (_) async => null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      );
    });

    testWidgets('a neighbour video page does not create the native player surface', (tester) async {
      when(() => storage.getFileForAsset(local.id)).thenAnswer((_) async => null);

      await pumpViewer(tester, remote);

      expect(surface, findsNothing);
    });

    testWidgets('the surface is created once the page becomes current', (tester) async {
      when(() => storage.getFileForAsset(local.id)).thenAnswer((_) async => null);

      await tester.pumpTestWidget(
        context,
        NativeVideoViewer(asset: remote, image: const SizedBox(), isCurrent: true),
        overrides: [storageRepositoryProvider.overrideWithValue(storage)],
        expectSettle: false,
      );

      expect(surface, findsOneWidget);
    });

    testWidgets('swiping across a video page never builds the surface and settles on the next page', (tester) async {
      when(() => storage.getFileForAsset(local.id)).thenAnswer((_) async => null);
      final controller = PageController();
      addTearDown(controller.dispose);

      await tester.pumpTestWidget(
        context,
        SizedBox(
          width: 400,
          height: 600,
          child: PageView(
            controller: controller,
            children: [
              const ColoredBox(color: Colors.red),
              NativeVideoViewer(asset: remote, image: const SizedBox()),
              const ColoredBox(color: Colors.blue),
            ],
          ),
        ),
        overrides: [storageRepositoryProvider.overrideWithValue(storage)],
        expectSettle: false,
      );

      final gesture = await tester.startGesture(const Offset(300, 300));
      await gesture.moveBy(const Offset(-250, 0));
      await tester.pump();
      expect(surface, findsNothing, reason: 'the video page is half on screen mid-drag');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.page, 1.0);

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      expect(controller.page, 2.0);
      expect(surface, findsNothing);
    });
  });
}
