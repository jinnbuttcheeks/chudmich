import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/data/store.dart';
import 'package:immich_mobile/domain/models/user.model.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/presentation/widgets/common/bottom_inset_sliver.dart';
import 'package:immich_mobile/presentation/widgets/common/press_scale.dart';
import 'package:immich_mobile/presentation/widgets/images/remote_image_provider.dart';
import 'package:immich_mobile/presentation/widgets/images/thumbnail.widget.dart';
import 'package:immich_mobile/presentation/widgets/people/partner_user_avatar.widget.dart';
import 'package:immich_mobile/providers/infrastructure/album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/memory.provider.dart';
import 'package:immich_mobile/providers/infrastructure/user.provider.dart';
import 'package:immich_mobile/providers/server_info.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/theme/glass/glass.dart';
import 'package:immich_mobile/utils/image_url_builder.dart';
import 'package:immich_mobile/widgets/common/immich_sliver_app_bar.dart';
import 'package:immich_mobile/widgets/map/map_thumbnail.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

@RoutePage()
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: GlassLightScrollDriver(
          child: CustomScrollView(
            slivers: [
              ImmichSliverAppBar(
                snap: false,
                floating: false,
                pinned: true,
                showUploadButton: false,
                largeTitle: context.t.library$,
              ),
              const _LibraryDashboard(),
              const _QuickAccessButtonList(),
              const BottomInsetSliver(extra: 16),
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
/// Fixed palette for the dashboard badges, so every collection keeps its own identity.
abstract final class LibraryHue {
  static const favorites = Color(0xFFFF4D6D);
  static const archive = Color(0xFFFFA62B);
  static const links = Color(0xFF2EC4B6);
  static const trash = Color(0xFF8D99AE);
  static const people = Color(0xFF7C5CFF);
  static const places = Color(0xFF34C759);
  static const device = Color(0xFF3D8BFF);
  static const memories = Color(0xFFFF7A59);
}

/// Bento grid of hero cards: one tall hero beside a stack of small cards,
/// followed by wide cards with live previews.
class _LibraryDashboard extends ConsumerWidget {
  const _LibraryDashboard();

  static const double gap = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTrashEnabled = ref.watch(serverInfoProvider.select((state) => state.serverFeatures.trash));

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      sliver: SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final unit = (constraints.maxWidth - gap) / 2;
            final small = (unit - gap) / 2;
            return Column(
              children: [
                SizedBox(
                  height: unit,
                  child: Row(
                    children: [
                      Expanded(
                        child: LibraryBentoCard(
                          hue: LibraryHue.favorites,
                          icon: Icons.favorite_rounded,
                          title: context.t.favorites,
                          hero: true,
                          onTap: () => context.pushRoute(const FavoriteRoute()),
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: LibraryBentoCard(
                                hue: LibraryHue.archive,
                                icon: Icons.inventory_2_rounded,
                                title: context.t.archived,
                                onTap: () => context.pushRoute(const ArchiveRoute()),
                              ),
                            ),
                            const SizedBox(height: gap),
                            Expanded(
                              child: LibraryBentoCard(
                                hue: LibraryHue.links,
                                icon: Icons.link_rounded,
                                title: context.t.shared_links,
                                onTap: () => context.pushRoute(const SharedLinkRoute()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: gap),
                SizedBox(height: small + 8, child: const _PeopleWideCard()),
                const SizedBox(height: gap),
                SizedBox(
                  height: unit * 0.82,
                  child: const Row(
                    children: [
                      Expanded(child: _PlacesCard()),
                      SizedBox(width: gap),
                      Expanded(child: _DeviceCard()),
                    ],
                  ),
                ),
                const SizedBox(height: gap),
                SizedBox(height: small + 8, child: const _MemoriesWideCard()),
                if (isTrashEnabled) ...[
                  const SizedBox(height: gap),
                  SizedBox(
                    height: 64,
                    child: LibraryBentoCard(
                      hue: LibraryHue.trash,
                      icon: Icons.delete_rounded,
                      title: context.t.trash,
                      compact: true,
                      onTap: () => context.pushRoute(const TrashRoute()),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Glass card of the dashboard. Cards sit in a scrolling list, so they use
/// fake glass (tinted gradients) rather than a backdrop filter.
@visibleForTesting
class LibraryBentoCard extends StatelessWidget {
  const LibraryBentoCard({
    required this.hue,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.hero = false,
    this.compact = false,
    this.preview,
  });

  final Color hue;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool hero;
  final bool compact;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    final textTheme = Theme.of(context).textTheme;
    return PressScale(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          blur: false,
          shadow: false,
          radius: 28,
          tint: Color.alphaBlend(hue.withValues(alpha: tokens.isDark ? 0.20 : 0.16), tokens.tint),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hero)
                Positioned(
                  right: -22,
                  bottom: -26,
                  child: Icon(icon, size: 150, color: hue.withValues(alpha: tokens.isDark ? 0.22 : 0.18)),
                ),
              if (preview != null) Positioned.fill(child: preview!),
              Padding(
                padding: EdgeInsets.all(compact ? 14 : 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Short cards (the small ones beside the hero, the trash strip) lay out in a row.
                    if (compact || constraints.maxHeight < 72) {
                      return Row(
                        children: [
                          GlassIconBadge(icon: icon, color: hue, size: compact ? 36 : 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall?.copyWith(color: tokens.ink, height: 1.1),
                            ),
                          ),
                          if (compact) Icon(Icons.chevron_right_rounded, color: tokens.inkSecondary),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassIconBadge(icon: icon, color: hue, size: hero ? 44 : 36),
                        const Spacer(),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: (hero ? textTheme.headlineSmall : textTheme.titleMedium)?.copyWith(
                            color: tokens.ink,
                            height: 1.1,
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: tokens.inkSecondary)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Overlapping round previews on the right edge of a wide card.
@visibleForTesting
class LibraryAvatarStack extends StatelessWidget {
  const LibraryAvatarStack({required this.children});

  final List<Widget> children;
  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    const overlap = size * 0.62;
    return SizedBox(
      width: size + overlap * (children.length - 1).clamp(0, 99),
      height: size,
      child: Stack(
        children: [
          for (var i = children.length - 1; i >= 0; i--)
            Positioned(
              left: overlap * i,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.canvas, width: 2.5),
                ),
                child: ClipOval(
                  child: SizedBox.square(dimension: size - 5, child: children[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeopleWideCard extends ConsumerWidget {
  const _PeopleWideCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(Store.people.all());
    final list = people.valueOrNull ?? const [];
    return LibraryWideCard(
      hue: LibraryHue.people,
      icon: Icons.face_retouching_natural_rounded,
      title: context.t.people,
      onTap: () => context.pushRoute(const PeopleCollectionRoute()),
      trailing: list.isEmpty
          ? null
          : LibraryAvatarStack(
              children: [
                for (final person in list.take(4))
                  Image(
                    image: RemoteImageProvider(url: getFaceThumbnailUrl(person.id, updatedAt: person.updatedAt)),
                    fit: BoxFit.cover,
                  ),
              ],
            ),
    );
  }
}

class _MemoriesWideCard extends ConsumerWidget {
  const _MemoriesWideCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(allMemoriesProvider(false));
    final list = memories.valueOrNull ?? const [];
    return LibraryWideCard(
      hue: LibraryHue.memories,
      icon: Icons.auto_awesome_rounded,
      title: context.t.memories,
      onTap: () => context.pushRoute(const MemoryListRoute()),
      trailing: list.isEmpty
          ? null
          : LibraryAvatarStack(
              children: [
                for (final memory in list.take(4))
                  Thumbnail.remote(
                    remoteId: memory.assets[0].id,
                    thumbhash: memory.assets[0].thumbHash ?? "",
                    fit: BoxFit.cover,
                  ),
              ],
            ),
    );
  }
}

@visibleForTesting
class LibraryWideCard extends StatelessWidget {
  const LibraryWideCard({
    required this.hue,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final Color hue;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    return PressScale(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          blur: false,
          shadow: false,
          radius: 28,
          tint: Color.alphaBlend(hue.withValues(alpha: tokens.isDark ? 0.20 : 0.16), tokens.tint),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              GlassIconBadge(icon: icon, color: hue, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: tokens.ink),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacesCard extends StatelessWidget {
  const _PlacesCard();

  @override
  Widget build(BuildContext context) {
    return LibraryBentoCard(
      hue: LibraryHue.places,
      icon: Icons.place_rounded,
      title: context.t.places,
      onTap: () => context.pushRoute(PlaceRoute(currentLocation: null)),
      preview: Opacity(
        opacity: 0.55,
        child: IgnorePointer(
          child: MapThumbnail(
            zoom: 8,
            centre: const LatLng(21.44950, -157.91959),
            showAttribution: false,
            themeMode: context.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(localAlbumProvider).valueOrNull ?? const [];
    return LibraryBentoCard(
      hue: LibraryHue.device,
      icon: Icons.smartphone_rounded,
      title: context.t.on_this_device,
      subtitle: albums.isEmpty ? null : '${albums.length}',
      onTap: () => context.pushRoute(const LocalAlbumsRoute()),
    );
  }
}

@visibleForTesting
final sharedWithPartnerProvider = StreamProvider.autoDispose<Iterable<Partner>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    // TODO: Refactor with a route guard to avoid this check in every provider
    return const .empty();
  }

  return ref.watch(partnerServiceProvider).search(currentUser.id, .sharedWith);
});

class _QuickAccessButtonList extends ConsumerWidget {
  const _QuickAccessButtonList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partners = ref.watch(sharedWithPartnerProvider).valueOrNull ?? [];

    return SliverToBoxAdapter(
      child: GlassGroup(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        children: [
          GlassGroupTile(
            icon: Icons.folder_rounded,
            iconColor: const Color(0xFF5E9BFF),
            title: context.t.folders,
            onTap: () => context.pushRoute(FolderRoute()),
          ),
          GlassGroupTile(
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFF8E8E93),
            title: context.t.locked_folder,
            onTap: () => context.pushRoute(const LockedFolderRoute()),
          ),
          GlassGroupTile(
            icon: Icons.group_rounded,
            iconColor: const Color(0xFF30B0C7),
            title: context.t.partners,
            onTap: () => context.pushRoute(const PartnerRoute()),
          ),
          for (final partner in partners)
            GlassGroupTile(
              leading: PartnerUserAvatar(userId: partner.id, name: partner.name),
              title: context.t.partner_list_user_photos(user: partner.name),
              onTap: () => context.pushRoute(PartnerDetailRoute(partner: partner)),
            ),
        ],
      ),
    );
  }
}
