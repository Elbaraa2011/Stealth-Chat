import 'package:flutter/material.dart';

import '../backend/models.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';

class ProfileEmptyState extends StatelessWidget {
  const ProfileEmptyState({super.key, required this.user});

  final StealthUser user;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: IgColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.username.substring(0, 1).toUpperCase(),
                  style: IgText.bold(
                    size: 28,
                    color: IgColors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      user.displayName.isEmpty
                          ? user.username
                          : user.displayName,
                      textAlign: TextAlign.center,
                      style: IgText.bold(size: 24),
                    ),
                  ),
                  if (user.avatar.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    const VerifiedBadge(size: 14),
                  ],
                ],
              ),
              Text(
                '@${user.username}',
                textAlign: TextAlign.center,
                style: IgText.body(
                  size: 13,
                  color: IgColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "When people tag you in photos and videos, they'll appear here.",
                textAlign: TextAlign.center,
                style: IgText.body(
                  size: 14,
                  color: IgColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}
