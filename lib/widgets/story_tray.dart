import 'package:flutter/material.dart';

import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../screens/story_viewer_screen.dart';
import 'primitives.dart';

class StoryTray extends StatelessWidget {
  const StoryTray({super.key});

  static const double _tileWidth = 82;

  @override
  Widget build(BuildContext context) {
    // The tray sits inside a const FeedScreen in an IndexedStack, so nothing
    // rebuilds it for us: listen directly or a viewed ring never goes grey.
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (BuildContext context, Widget? _) => _tray(context),
    );
  }

  Widget _tray(BuildContext context) {
    final AppState state = AppState.instance;
    return SizedBox(
      height: 106,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 5),
        itemCount: storyGroups.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) return const _YourStoryTile();
          final StoryGroup group = storyGroups[index - 1];
          return _StoryTile(
            group: group,
            viewed: state.isStoryViewed(group.user.handle),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => StoryViewerScreen(
                  groups: storyGroups,
                  initialGroup: index - 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({
    required this.group,
    required this.viewed,
    required this.onTap,
  });

  final StoryGroup group;
  final bool viewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: StoryTray._tileWidth,
        child: Column(
          children: <Widget>[
            StoryRing(
              size: 70,
              viewed: viewed,
              strokeWidth: 2.4,
              gap: 2.5,
              closeFriend: group.user.isCloseFriend,
              child: NetImage(url: group.user.avatar),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: StoryTray._tileWidth - 4,
              child: Text(
                group.user.handle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: IgText.body(
                  size: 11,
                  color: viewed ? IgColors.textTertiary : IgColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YourStoryTile extends StatelessWidget {
  const _YourStoryTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: StoryTray._tileWidth,
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Center(
                  child: ClipOval(
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: NetImage(url: me.avatar),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      color: IgColors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: IgColors.bg, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: StoryTray._tileWidth - 4,
            child: Text(
              'Your story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: IgText.body(size: 11),
            ),
          ),
        ],
      ),
    );
  }
}
