import 'package:flutter/material.dart';

import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key, this.standalone = false});

  /// When true the screen is pushed as its own route (opened from the heart
  /// in the feed header) and shows a back button. Otherwise it is embedded.
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final List<IgNotification> today = notifications.take(4).toList();
    final List<IgNotification> week = notifications.skip(4).take(4).toList();
    final List<IgNotification> earlier = notifications.skip(8).toList();

    final Widget content = ListenableBuilder(
      listenable: AppState.instance,
      builder: (BuildContext context, Widget? _) {
        return Column(
          children: <Widget>[
            Padding(
              padding: standalone
                  ? const EdgeInsets.fromLTRB(2, 4, 10, 4)
                  : const EdgeInsets.fromLTRB(16, 8, 10, 4),
              child: Row(
                children: <Widget>[
                  if (standalone)
                    IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back, size: 24),
                      onPressed: () => Navigator.of(context).maybePop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: standalone ? 2 : 0),
                      child: Text('Activity', style: IgText.bold(size: 22)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _Section(title: 'Today', items: today),
                  _Section(title: 'This week', items: week),
                  _Section(title: 'Earlier', items: earlier),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (!standalone) return content;

    return Scaffold(
      backgroundColor: IgColors.bg,
      body: SafeArea(child: content),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<IgNotification> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
          child: Text(
            title,
            style: IgText.semibold(size: 13.5),
          ),
        ),
        for (final IgNotification item in items) _NotifRow(item: item),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.item});

  final IgNotification item;

  @override
  Widget build(BuildContext context) {
    final AppState state = AppState.instance;
    final bool following = state.isFollowing(item.user.handle);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: ClipOval(child: NetImage(url: item.user.avatar)),
                ),
                if (item.user.isOnline)
                  const Positioned(
                      right: 0, bottom: 2, child: OnlineDot(size: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: IgText.body(size: 13.5),
                children: <InlineSpan>[
                  TextSpan(
                    text: '${item.user.handle} ',
                    style: IgText.semibold(size: 13.5),
                  ),
                  TextSpan(text: item.action),
                  TextSpan(
                    text: '  ${item.age}',
                    style: IgText.body(
                      size: 13,
                      color: IgColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (item.followBack)
            GestureDetector(
              onTap: () => state.toggleFollow(item.user.handle),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: following ? IgColors.surfaceHigh : IgColors.blue,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  following ? 'Following' : 'Follow',
                  style: IgText.semibold(
                    size: 12.5,
                    color: following ? IgColors.textPrimary : Colors.white,
                  ),
                ),
              ),
            )
          else if (item.thumb != null)
            SizedBox(
              width: 44,
              height: 44,
              child: NetImage(url: item.thumb!),
            ),
        ],
      ),
    );
  }
}
