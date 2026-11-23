import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

import '../data/fixtures.dart' as fx;
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';

/// Full-screen vertical reel player. Each page owns a real
/// [VideoPlayerController]; every controller is initialized before it is
/// drawn, which is what makes the videos actually play instead of showing
/// only the overlay.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final AppState _state = AppState.instance;
  final PageController _pages = PageController();
  final List<VideoPlayerController> _controllers = <VideoPlayerController>[];
  final List<bool> _ready = <bool>[];

  List<fx.IgReel> get _reels => fx.reels;

  int _index = 0;
  bool _muted = false;
  bool _paused = false;
  bool _pausedByTab = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _reels.length; i++) {
      _controllers.add(VideoPlayerController.asset(_reels[i].video));
      _ready.add(false);
    }
    AppState.instance.addListener(_onAppStateChanged);
    // Defer the first play until the tab is actually visible, so Reel 1's
    // audio cannot start before the user has entered the Reels tab.
    _prepare(playFirst: false);
  }

  /// The tab shell keeps every tab alive in an [IndexedStack], so a reel would
  /// otherwise keep playing sound while the user is on some other tab.
  void _onAppStateChanged() {
    if (!mounted) return;
    final bool onReelsTab = AppState.instance.tabIndex == 2;
    if (!onReelsTab && !_pausedByTab) {
      _pausedByTab = true;
      if (_index < _controllers.length && _ready[_index]) {
        _controllers[_index].pause();
        setState(() {});
      }
    } else if (onReelsTab && _pausedByTab) {
      _pausedByTab = false;
      _paused = false;
      if (_index < _controllers.length && _ready[_index]) {
        _controllers[_index].play();
        setState(() {});
      }
    }
  }

  Future<void> _prepare({bool playFirst = true}) async {
    for (int i = 0; i < _controllers.length; i++) {
      final VideoPlayerController controller = _controllers[i];
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(_muted ? 0 : 1);
        if (!mounted) return;
        setState(() => _ready[i] = true);
        if (i == _index && playFirst) {
          _playCurrent();
        }
      } catch (error) {
        debugPrint('Reel ${_reels[i].id} failed to load: $error');
      }
    }
  }

  void _playCurrent() {
    if (_index < _controllers.length && _ready[_index]) {
      _controllers[_index].play();
    }
  }

  void _togglePlayback() {
    if (_index >= _controllers.length || !_ready[_index]) return;
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _controllers[_index].pause();
      } else {
        _controllers[_index].play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      for (final VideoPlayerController controller in _controllers) {
        if (controller.value.isInitialized) {
          controller.setVolume(_muted ? 0 : 1);
        }
      }
    });
  }

  String _count(int value) {
    if (value >= 1000000) {
      final String v = (value / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return '${v}M';
    }
    if (value >= 1000) {
      final String v = (value / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return '${v}K';
    }
    return '$value';
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onAppStateChanged);
    _pages.dispose();
    for (final VideoPlayerController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int next) {
    if (_index < _controllers.length && _ready[_index]) {
      _controllers[_index].pause();
    }
    _index = next;
    _paused = false;
    _playCurrent();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _pages,
            scrollDirection: Axis.vertical,
            itemCount: _reels.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (BuildContext context, int index) => _page(index),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                child: Row(
                  children: <Widget>[
                    Text('Reels', style: IgText.bold(size: 20)),
                    const Spacer(),
                    _circleButton(
                      icon: _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      onTap: _toggleMute,
                    ),
                    const SizedBox(width: 6),
                    _circleButton(
                      icon: Icons.camera_alt_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0x33000000),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: Colors.white),
      ),
    );
  }

  Widget _page(int index) {
    final fx.IgReel reel = _reels[index];
    final VideoPlayerController controller = _controllers[index];
    final bool ready = _ready[index];

    return GestureDetector(
      onTap: _togglePlayback,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (ready && controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 54,
                  color: Colors.white24,
                ),
              ),
            ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: IgColors.reelScrim),
            ),
          ),
          if (_paused && index == _index)
            IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 84,
                  color: Colors.white70,
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 84,
            bottom: 22,
            child: _info(reel),
          ),
          Positioned(
            right: 8,
            bottom: 26,
            child: _rail(reel),
          ),
        ],
      ),
    );
  }

  Widget _info(fx.IgReel reel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            ClipOval(
              child: SizedBox(
                width: 32,
                height: 32,
                child: reel.user.avatar.isEmpty
                    ? const ColoredBox(
                        color: IgColors.surfaceHigh,
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: IgColors.textSecondary,
                        ),
                      )
                    : NetImage(url: reel.user.avatar),
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                reel.user.handle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: IgText.semibold(size: 13.5, color: Colors.white),
              ),
            ),
            if (reel.verified || reel.user.isVerified) ...<Widget>[
              const SizedBox(width: 4),
              const VerifiedBadge(size: 12),
            ],
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Follow',
                style: IgText.semibold(size: 11.5, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          reel.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: IgText.body(size: 13.5, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const Icon(Icons.music_note, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '${reel.audio} · ${reel.audioUser}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: IgText.body(size: 11.5, color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rail(fx.IgReel reel) {
    final bool liked = _state.isLiked(reel.id);
    final bool saved = _state.isReelSaved(reel.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _railAction(
          asset: 'assets/icons/like.svg',
          color: liked ? IgColors.red : Colors.white,
          label: _count(reel.likes + (liked ? 1 : 0)),
          onTap: () {
            _state.toggleLike(reel.id);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        _railAction(
          asset: 'assets/icons/comment.svg',
          label: _count(reel.comments),
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _railAction(
          asset: 'assets/icons/share.svg',
          label: 'Share',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _railAction(
          asset: 'assets/icons/repost.svg',
          color: saved ? Colors.white : Colors.white70,
          label: saved ? 'Saved' : 'Save',
          onTap: () {
            _state.toggleReelSaved(reel.id);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        _audioDisc(),
      ],
    );
  }

  Widget _railAction({
    required String asset,
    required VoidCallback onTap,
    String label = '',
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IgSvgIcon(asset: asset, size: 27, color: color),
          if (label.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              label,
              style: IgText.semibold(size: 11, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _audioDisc() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: IgColors.surfaceHigh,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.music_note, size: 15, color: Colors.white),
    );
  }
}
