import 'package:flutter/material.dart';

import '../backend/models.dart';
import '../data/fixtures.dart' as fixtures;
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';
import '../widgets/profile_empty_state.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  const ProfileScreen({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  // Pushys app section: mirrors the signed-in user on every build so the
  // profile, empty state and profile tab always reflect `jade12` (or whatever
  // the user signed up / logged in as) instead of the fixture handle.
  @override
  Widget build(BuildContext context) {
    final StealthUser me = AppState.instance.me;
    return DefaultTabController(
      length: 4,
      initialIndex: 3,
      child: Column(
        children: <Widget>[
          ProfileHeader(user: me, onSignOut: () async {
    await AuthService.instance.signOut();
  }),
          _ProfileTabBar(user: me),
          Expanded(child: ProfileEmptyState(user: me)),

          // Nothing else renders on this screen; the decoy messages, the real
          // session, the search and the profile edits all live on their own
          // screens from here.
        ],
      ),
    );
  }
}

class _ProfileTabBar extends StatelessWidget {
  const _ProfileTabBar({required this.user});

  final StealthUser user;

  @override
  Widget build(BuildContext context) => TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorWeight: 1.5,
        dividerHeight: 0,
        labelColor: IgColors.textPrimary,
        unselectedLabelColor: IgColors.textSecondary,
        tabs: <Widget>[
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${fixtures.me.posts}',
                  style: IgText.medium(size: 12,
                      color: IgColors.textSecondary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.grid_on, size: 23),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${fixtures.me.followers}',
                  style: IgText.medium(size: 12,
                      color: IgColors.textSecondary),
                ),
                const SizedBox(width: 4),
                ReelsIcon(
                  color: IgColors.textSecondary,
                  filled: false,
                  size: 23,
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${fixtures.me.following}',
                  style: IgText.medium(size: 12,
                      color: IgColors.textSecondary),
                ),
                const SizedBox(width: 4),
                Icon(Icons.sync, size: 25),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IgText.medium(size: 12,
                        color: IgColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.account_box, size: 22),
              ],
            ),
          ),
        ],
      );
}
