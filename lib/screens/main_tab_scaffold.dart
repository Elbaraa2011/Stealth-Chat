import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../screens/explore_screen.dart';
import '../screens/feed_screen.dart';
import '../screens/dm_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reels_screen.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';

class MainTabScaffold extends StatelessWidget {
  const MainTabScaffold({super.key});

  /// 0 Home · 1 Search · 2 Reels · 3 Messages · 4 Profile.
  /// Activity is intentionally not a tab: it opens from the heart in the
  /// feed header only.
  static final List<Widget> _tabs = <Widget>[
    const FeedScreen(),
    const ExploreScreen(),
    const ReelsScreen(),
    const DmScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (BuildContext context, Widget? _) {
        final int index = AppState.instance.tabIndex;
        return Scaffold(
          backgroundColor: IgColors.bg,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: index,
              children: _tabs,
            ),
          ),
          bottomNavigationBar: _BottomBar(index: index),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index});

  final int index;

  static const List<String> _icons = <String>[
    'assets/icons/home.svg',
    'assets/icons/search.svg',
    'assets/icons/reels.svg',
    'assets/images/message_icon.svg',
  ];
  static const List<String> _labels = <String>[
    'Home',
    'Search',
    'Reels',
    'Messages',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
        child: Container(
          height: 58,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: IgColors.surface,
            border: Border.all(color: IgColors.divider, width: 0.8),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: <Widget>[
              for (int tab = 0; tab < 5; tab++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == tab,
                    label: _labels[tab],
                    child: GestureDetector(
                      key: ValueKey<String>('tab-$tab'),
                      onTap: () => AppState.instance.selectTab(tab),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: index == tab
                              ? IgColors.surfaceHigh
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        alignment: Alignment.center,
                        child: tab == 4
                            ? ClipOval(
                                child: Image.asset(
                                  AppState.instance.me.avatar,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context,
                                          Object error, StackTrace? stack) =>
                                      const Icon(
                                    Icons.person_outline,
                                    size: 25,
                                    color: IgColors.textPrimary,
                                  ),
                                ),
                              )
                            : SvgPicture.asset(
                                _icons[tab],
                                width: tab == 2 ? 23 : 22,
                                height: tab == 2 ? 23 : 22,
                                colorFilter: ColorFilter.mode(
                                  index == tab
                                      ? IgColors.textPrimary
                                      : IgColors.textSecondary,
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
