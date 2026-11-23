import 'package:flutter/material.dart';

import '../data/fixtures.dart';
import '../theme/ig_theme.dart';
import '../widgets/post_card.dart';
import '../widgets/story_tray.dart';
import 'activity_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _Header(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: feedPosts.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Column(
                  children: <Widget>[
                    const StoryTray(),
                    const Divider(height: 1, color: IgColors.divider),
                  ],
                );
              }
              final IgPost post = feedPosts[index - 1];
              return Column(
                children: <Widget>[
                  PostCard(post: post),
                  const Divider(height: 1, color: IgColors.divider),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: IgColors.bg,
      padding: const EdgeInsets.fromLTRB(14, 5, 10, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Instagram', style: IgText.wordmark(size: 34)),
            ),
          ),
          _headerIcon(
            icon: Icons.favorite_border,
            label: 'Activity',
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    const ActivityScreen(standalone: true),
              ),
            ),
          ),
          const SizedBox(width: 3),
        ],
      ),
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: label,
      icon: Icon(icon, size: 25),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
