import 'package:flutter/material.dart';

import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';

/// Top scrim so the handle and progress bars stay legible over bright media.
const LinearGradient _topScrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[Color(0x99000000), Color(0x00000000)],
);

/// Full-screen story player: 5 second segments, tap to skip, swipe down to
/// dismiss. Viewed rings go grey in the tray behind.
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.groups,
    this.initialGroup = 0,
  });

  final List<StoryGroup> groups;
  final int initialGroup;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  late int _group = widget.initialGroup;
  int _item = 0;

  StoryGroup get _current => widget.groups[_group];

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener(_onSegmentComplete);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSegment());
  }

  @override
  void dispose() {
    _progress.removeStatusListener(_onSegmentComplete);
    _progress.dispose();
    super.dispose();
  }

  void _startSegment() {
    if (!mounted) return;
    AppState.instance.markStoryViewed(_current.user.handle);
    _progress.forward(from: 0);
  }

  void _onSegmentComplete(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _advance();
  }

  void _advance() {
    if (_item + 1 < _current.stories.length) {
      setState(() => _item += 1);
      _startSegment();
      return;
    }
    if (_group + 1 < widget.groups.length) {
      setState(() {
        _group += 1;
        _item = 0;
      });
      _startSegment();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _rewind() {
    if (_item > 0) {
      setState(() => _item -= 1);
      _startSegment();
      return;
    }
    if (_group > 0) {
      setState(() {
        _group -= 1;
        _item = 0;
      });
      _startSegment();
      return;
    }
    _progress.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IgColors.bg,
      body: GestureDetector(
        onVerticalDragEnd: (DragEndDetails details) {
          if ((details.primaryVelocity ?? 0) > 220) {
            Navigator.of(context).maybePop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: ColoredBox(
                key: ValueKey<String>(
                  '${_current.user.handle}-$_item',
                ),
                color: IgColors.mediaPlaceholder,
                child: NetImage(
                  url: _current.stories[_item].mediaId,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: IgColors.bottomFade),
              ),
            ),
            const IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 150,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: _topScrim),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  _progressBars(),
                  _header(),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _rewind,
                            onLongPressStart: (_) => _progress.stop(),
                            onLongPressEnd: (_) => _progress.forward(),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _advance,
                            onLongPressStart: (_) => _progress.stop(),
                            onLongPressEnd: (_) => _progress.forward(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _replyBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressBars() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (BuildContext context, Widget? _) {
          return Row(
            children: List<Widget>.generate(_current.stories.length, (int i) {
              final double fill = i < _item
                  ? 1
                  : i == _item
                      ? _progress.value
                      : 0;
              return Expanded(
                child: Container(
                  height: 2.5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0x4DFFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fill.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Row(
        children: <Widget>[
          StoryRing(
            size: 34,
            strokeWidth: 1.6,
            gap: 1.5,
            child: NetImage(url: _current.user.avatar),
          ),
          const SizedBox(width: 9),
          Text(
            _current.user.handle,
            style: IgText.semibold(size: 13),
          ),
          if (_current.user.isVerified) ...<Widget>[
            const SizedBox(width: 4),
            const VerifiedBadge(size: 11),
          ],
          const SizedBox(width: 8),
          Text(
            _current.stories[_item].timeAgo,
            style: IgText.body(size: 12, color: const Color(0xCCFFFFFF)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                'Send message',
                style: IgText.body(size: 13.5, color: const Color(0xCCFFFFFF)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.favorite_border, size: 24, color: Colors.white),
          const SizedBox(width: 12),
          const Icon(Icons.send_outlined, size: 24, color: Colors.white),
        ],
      ),
    );
  }
}
