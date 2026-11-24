import 'package:flutter/material.dart';

import '../backend/models.dart';
import '../data/fixtures.dart' as fixtures;
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import 'primitives.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, this.onSignOut});

  final StealthUser user;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: <Widget>[
            const _TopBar(),
            const SizedBox(height: 10),
            _IdentityAndStats(user: user),
            const SizedBox(height: 15),
            _ThreadsHandle(user: user),
            const SizedBox(height: 10),
            _ProfileActions(onSignOut: onSignOut),
          ],
        ),
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 40,
              child: IconButton(
                tooltip: 'Create',
                onPressed: () {},
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add, size: 32),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.lock_outline, size: 17),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      AppState.instance.me.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: IgText.bold(size: 16.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  IconButton(
                    tooltip: 'Threads',
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.alternate_email, size: 26),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: IgColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text('4', style: IgText.bold(size: 12)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                tooltip: 'Menu',
                onPressed: () {},
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.menu, size: 27),
              ),
            ),
          ],
        ),
      );
}

class _IdentityAndStats extends StatelessWidget {
  const _IdentityAndStats({required this.user});

  final StealthUser user;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 108,
        child: Row(
          children: <Widget>[
            const _ProfileAvatar(),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          user.displayName.isEmpty
                              ? user.handle
                              : user.displayName,
                          style: IgText.semibold(size: 14.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'he/him/هو',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: IgText.body(
                            size: 13,
                            color: IgColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ProfileStat(
                          value: fixtures.me.posts,
                          label: 'posts',
                        ),
                      ),
                      Expanded(
                        child: _ProfileStat(
                          value: fixtures.me.followers,
                          label: 'followers',
                        ),
                      ),
                      Expanded(
                        child: _ProfileStat(
                          value: fixtures.me.following,
                          label: 'following',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 92,
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: 0,
              bottom: 0,
              child: ClipOval(
                child: NetImage(
                  url: AppState.instance.me.avatar,
                  width: 86,
                  height: 86,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 2,
              child: Container(
                width: 94,
                height: 42,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: IgColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: IgColors.divider, width: 1),
                ),
                child: Text(
                  'Your thoughts g...',
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: IgText.body(size: 10.5, color: IgColors.textSecondary),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: -1,
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: IgColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 19, color: IgColors.bg),
              ),
            ),
          ],
        ),
      );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(value.toString(), style: IgText.semibold(size: 16)),
            Text(label, style: IgText.body(size: 13)),
          ],
        ),
      );
}

class _ThreadsHandle extends StatelessWidget {
  const _ThreadsHandle({required this.user});

  final StealthUser user;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          height: 27,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            border: Border.all(color: IgColors.divider, width: 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.alternate_email, size: 15),
              const SizedBox(width: 5),
              Text(user.handle, style: IgText.semibold(size: 12)),
            ],
          ),
        ),
      );
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          const Expanded(child: _ActionButton(label: 'Edit profile')),
          const SizedBox(width: 5),
          const Expanded(child: _ActionButton(label: 'Share profile')),
          const SizedBox(width: 5),
          Expanded(
            child: _ActionButton(
              label: 'Log out',
              onTap: onSignOut,
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: IgColors.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                tooltip: 'Discover people',
                onPressed: () {},
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 17),
              ),
            ),
          ),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 32,
        child: Material(
          color: IgColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(label, style: IgText.semibold(size: 13)),
            ),
          ),
        ),
      );
}
