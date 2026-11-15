import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' hide Store;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/data/store.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/generated/translations.g.dart';
import 'package:immich_mobile/providers/auth.provider.dart';
import 'package:immich_mobile/providers/user.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/theme/glass/glass.dart';
import 'package:immich_mobile/widgets/common/user_circle_avatar.dart';
import 'package:immich_mobile/widgets/settings/advanced_settings.dart';
import 'package:immich_mobile/widgets/settings/asset_list_settings/asset_list_settings.dart';
import 'package:immich_mobile/widgets/settings/asset_viewer_settings/asset_viewer_settings.dart';
import 'package:immich_mobile/widgets/settings/backup_settings/backup_settings.dart';
import 'package:immich_mobile/widgets/settings/beta_sync_settings/sync_status_and_actions.dart';
import 'package:immich_mobile/widgets/settings/free_up_space_settings.dart';
import 'package:immich_mobile/widgets/settings/language_settings.dart';
import 'package:immich_mobile/widgets/settings/networking_settings/networking_settings.dart';
import 'package:immich_mobile/widgets/settings/notification_setting.dart';
import 'package:immich_mobile/widgets/settings/passkey_settings.dart';
import 'package:immich_mobile/widgets/settings/preference_settings/preference_setting.dart';

enum SettingSection {
  advanced(Icons.build_outlined),
  assetViewer(Icons.image_outlined),
  backup(Icons.cloud_upload_outlined),
  freeUpSpace(Icons.cleaning_services_outlined),
  languages(Icons.language),
  networking(Icons.wifi),
  notifications(Icons.notifications_none_rounded),
  passkeys(Icons.key_outlined),
  preferences(Icons.interests_outlined),
  timeline(Icons.auto_awesome_mosaic_outlined),
  beta(Icons.sync_outlined);

  final IconData icon;

  String title(Translations t) => switch (this) {
    SettingSection.advanced => t.advanced,
    SettingSection.assetViewer => t.asset_viewer_settings_title,
    SettingSection.backup => t.backup,
    SettingSection.freeUpSpace => t.free_up_space,
    SettingSection.languages => t.language,
    SettingSection.networking => t.networking_settings,
    SettingSection.notifications => t.notifications,
    SettingSection.passkeys => t.passkeys(count: 2),
    SettingSection.preferences => t.preferences_settings_title,
    SettingSection.timeline => t.asset_list_settings_title,
    SettingSection.beta => t.sync_status,
  };

  String subtitle(Translations t) => switch (this) {
    SettingSection.advanced => t.advanced_settings_tile_subtitle,
    SettingSection.assetViewer => t.asset_viewer_settings_subtitle,
    SettingSection.backup => t.backup_settings_subtitle,
    SettingSection.freeUpSpace => t.free_up_space_settings_subtitle,
    SettingSection.languages => t.setting_languages_subtitle,
    SettingSection.networking => t.networking_subtitle,
    SettingSection.notifications => t.setting_notifications_subtitle,
    SettingSection.passkeys => t.manage_your_passkeys,
    SettingSection.preferences => t.preferences_settings_subtitle,
    SettingSection.timeline => t.asset_list_settings_subtitle,
    SettingSection.beta => t.sync_status_subtitle,
  };

  Widget get widget => switch (this) {
    SettingSection.advanced => const AdvancedSettings(),
    SettingSection.assetViewer => const AssetViewerSettings(),
    SettingSection.backup => const BackupSettings(),
    SettingSection.freeUpSpace => const FreeUpSpaceSettings(),
    SettingSection.languages => const LanguageSettings(),
    SettingSection.networking => const NetworkingSettings(),
    SettingSection.notifications => const NotificationSetting(),
    SettingSection.passkeys => const PasskeySettings(),
    SettingSection.preferences => const PreferenceSetting(),
    SettingSection.timeline => const AssetListSettings(),
    SettingSection.beta => const SyncStatusAndActions(),
  };

  static Iterable<SettingSection> visible(WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider).isAuthenticated;
    final isPasskeyEnabled = ref.watch(Store.passkeys.enabled()).valueOrNull ?? false;
    return values.where((section) => section != passkeys || (isLoggedIn && isPasskeyEnabled));
  }

  const SettingSection(this.icon);
}

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: context.isMobile
            ? AppBar(centerTitle: false)
            : AppBar(centerTitle: false, title: Text(context.t.settings)),
        body: context.isMobile ? const _MobileLayout() : const _TabletLayout(),
      ),
    );
  }
}

/// Colour of each section's icon badge.
Color _badgeColor(SettingSection section) => switch (section) {
  SettingSection.advanced => const Color(0xFF8E8E93),
  SettingSection.assetViewer => const Color(0xFF3D8BFF),
  SettingSection.backup => const Color(0xFF34C759),
  SettingSection.freeUpSpace => const Color(0xFFFF9F0A),
  SettingSection.languages => const Color(0xFF5E5CE6),
  SettingSection.networking => const Color(0xFF30B0C7),
  SettingSection.notifications => const Color(0xFFFF453A),
  SettingSection.passkeys => const Color(0xFFBF5AF2),
  SettingSection.preferences => const Color(0xFFFF375F),
  SettingSection.timeline => const Color(0xFF0A84FF),
  SettingSection.beta => const Color(0xFF64D2FF),
};

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tokens = context.glass;
    final textTheme = context.textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassSurface(
        blur: false,
        shadow: false,
        radius: 28,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (user != null) UserCircleAvatar(size: 56, user: user, hasBorder: true),
            if (user != null) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? context.t.settings,
                    style: textTheme.titleLarge?.copyWith(color: tokens.ink, fontSize: 22),
                  ),
                  if (user != null)
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(color: tokens.inkSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout();

  static const _groups = <List<SettingSection>>[
    [SettingSection.backup, SettingSection.freeUpSpace, SettingSection.beta, SettingSection.passkeys],
    [
      SettingSection.preferences,
      SettingSection.timeline,
      SettingSection.assetViewer,
      SettingSection.languages,
      SettingSection.notifications,
    ],
    [SettingSection.networking, SettingSection.advanced],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = SettingSection.visible(ref).toSet();
    final tokens = context.glass;

    Widget tile(SettingSection setting) => GlassGroupTile(
      icon: setting.icon,
      iconColor: _badgeColor(setting),
      title: setting == SettingSection.beta ? context.t.sync_status : setting.title(context.t),
      subtitle: setting == SettingSection.beta ? context.t.sync_status_subtitle : setting.subtitle(context.t),
      onTap: () => context.pushRoute(
        setting == SettingSection.beta ? const SyncStatusRoute() : SettingsSubRoute(section: setting),
      ),
    );

    return GlassLightScrollDriver(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(context.t.settings, style: context.textTheme.headlineLarge?.copyWith(color: tokens.ink)),
          ),
          const _ProfileHeader(),
          for (final group in _groups)
            if (group.any(visible.contains))
              GlassGroup(
                children: [
                  for (final s in group)
                    if (visible.contains(s)) tile(s),
                ],
              ),
          GlassGroup(
            children: [
              GlassGroupTile(
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFFFD60A),
                title: context.t.whats_new,
                subtitle: context.t.whats_new_settings_subtitle,
                onTap: () => context.pushRoute(const WhatsNewRoute()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabletLayout extends HookConsumerWidget {
  const _TabletLayout();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSection = useState<SettingSection>(SettingSection.values.first);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: CustomScrollView(
            slivers: [
              ...SettingSection.visible(ref).map(
                (s) => SliverToBoxAdapter(
                  child: ListTile(
                    title: Text(s.title(context.t)),
                    leading: Icon(s.icon),
                    selected: s.index == selectedSection.value.index,
                    selectedColor: context.primaryColor,
                    selectedTileColor: context.themeData.highlightColor,
                    onTap: () => selectedSection.value = s,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ListTile(
                  title: Text(context.t.whats_new),
                  leading: const Icon(Icons.auto_awesome_outlined),
                  onTap: () => context.pushRoute(const WhatsNewRoute()),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(flex: 4, child: selectedSection.value.widget),
      ],
    );
  }
}

@RoutePage()
class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage(this.section, {super.key});

  final SettingSection section;

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      intensity: 0.7,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(centerTitle: false, title: Text(section.title(context.t))),
        body: section.widget,
      ),
    );
  }
}
