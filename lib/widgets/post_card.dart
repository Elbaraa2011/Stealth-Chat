import 'package:flutter/material.dart';

import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import 'comments_sheet.dart';
import 'primitives.dart' as primitives;

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, this.showHeader = true});

  final IgPost post;
  final bool showHeader;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  final AppState _state = AppState.instance;
  final PageController _pages = PageController();

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return count.toString();
  }

  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  late final Animation<double> _burstScale = Tween<double>(
    begin: 0.35,
    end: 1.85,
  ).animate(CurvedAnimation(parent: _burst, curve: Curves.elasticOut));
  late final Animation<double> _burstFade = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 52,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 38,
      ),
    ],
  ).animate(_burst);

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    _burst.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    final String id = widget.post.id;
    if (!_state.isLiked(id)) _state.like(id);
    _burst.forward(from: 0);
    _bounce.forward(from: 0);
    setState(() {});
  }

  void _toggleLike() {
    _state.toggleLike(widget.post.id);
    _bounce.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final IgPost post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (widget.showHeader) _header(post),
        _media(post),
        _actions(post),
        _meta(post),
        const SizedBox(height: 12),
      ],
    );
  }

  // ---------------------------------------------------------------- header

  Widget _header(IgPost post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 33,
              height: 33,
              child: primitives.NetImage(url: post.user.avatar),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        post.user.handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: IgText.semibold(size: 13.5),
                      ),
                    ),
                    if (post.user.isVerified) ...<Widget>[
                      const SizedBox(width: 4),
                      const primitives.VerifiedBadge(size: 12),
                    ],
                  ],
                ),
                if (post.location != null)
                  Text(
                    post.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IgText.body(size: 11.5),
                  ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, size: 22),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- media

  Widget _media(IgPost post) {
    final bool multi = post.media.length > 1;
    return AspectRatio(
      // 4:5 is the portrait crop Instagram itself uses in the feed, so the
      // real post graphics are shown whole instead of being trimmed square.
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onDoubleTap: _doubleTapLike,
            child: PageView.builder(
              controller: _pages,
              itemCount: post.media.length,
              onPageChanged: (int index) => setState(() => _page = index),
              itemBuilder: (BuildContext context, int index) =>
                  primitives.NetImage(url: post.media[index]),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _burst,
              builder: (BuildContext context, Widget? child) {
                return Opacity(
                  opacity: _burstFade.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _burstScale.value,
                    child: child,
                  ),
                );
              },
              child: const Center(
                child: Icon(
                  Icons.favorite,
                  size: 96,
                  color: Colors.white,
                  shadows: <Shadow>[
                    Shadow(color: Color(0x66000000), blurRadius: 14),
                  ],
                ),
              ),
            ),
          ),
          if (multi)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_page + 1}/${post.media.length}',
                  style: IgText.semibold(size: 11, color: Colors.white),
                ),
              ),
            ),
          if (multi)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(post.media.length, (int i) {
                  final bool active = i == _page;
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? Colors.white : const Color(0x80FFFFFF),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- actions

  Widget _actions(IgPost post) {
    final bool liked = _state.isLiked(post.id);
    final bool saved = _state.isReelSaved(post.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: <Widget>[
          _iconButton(
            animation: _bounce,
            onTap: _toggleLike,
            child: liked
                ? Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: IgColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 20,
                      color: Colors.white,
                    ),
                  )
                : const primitives.IgSvgIcon(
                    asset: 'assets/icons/like.svg',
                    size: 27,
                    color: IgColors.textPrimary,
                  ),
          ),
          _iconButton(
            onTap: () => showCommentsSheet(context, post),
            child: const primitives.IgSvgIcon(
              asset: 'assets/icons/comment.svg',
              size: 25,
              color: IgColors.textPrimary,
            ),
          ),
          _iconButton(
            onTap: () {},
            child: const primitives.IgSvgIcon(
              asset: 'assets/icons/share.svg',
              size: 25,
              color: IgColors.textPrimary,
            ),
          ),
          const Spacer(),
          _iconButton(
            onTap: () {
              _state.toggleReelSaved(post.id);
              setState(() {});
            },
            child: saved
                ? Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      const primitives.IgSvgIcon(
                        asset: 'assets/icons/repost.svg',
                        size: 26,
                        color: IgColors.textPrimary,
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: const BoxDecoration(
                            color: IgColors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                : const primitives.IgSvgIcon(
                    asset: 'assets/icons/repost.svg',
                    size: 26,
                    color: IgColors.textTertiary,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required Widget child,
    required VoidCallback onTap,
    Animation<double>? animation,
  }) {
    Widget content = child;
    if (animation != null) {
      content = AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? inner) {
          final double t = animation.value;
          final double scale = 1 + 0.3 * (t < 0.5 ? t * 2 : (1 - t) * 2);
          return Transform.scale(scale: scale, child: inner);
        },
        child: content,
      );
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: content,
      ),
    );
  }

  // ------------------------------------------------------------------ meta

  Widget _meta(IgPost post) {
    final int likes = post.likes + _state.likeDelta(post.id);
    final List<IgComment> comments = _state.commentsFor(post.id, []);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${_formatCount(likes)} likes',
            style: IgText.semibold(size: 13.5),
          ),
          const SizedBox(height: 4),
          _caption(post),
          if (comments.isNotEmpty) ...<Widget>[
            const SizedBox(height: 5),
            GestureDetector(
              onTap: () => showCommentsSheet(context, post),
              child: Text(
                'View all ${_formatCount(comments.length + 14)} comments',
                style: IgText.body(
                  size: 13,
                  color: IgColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 3),
            for (final IgComment comment in comments.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _commentLine(comment),
              ),
          ],
          const SizedBox(height: 5),
          Text(
            post.age ?? '—',
            style: IgText.body(size: 10.5, color: IgColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _caption(IgPost post) {
    return RichText(
      text: TextSpan(
        style: IgText.body(size: 13.5),
        children: <InlineSpan>[
          TextSpan(
            text: '${post.user.handle} ',
            style: IgText.semibold(size: 13.5),
          ),
          TextSpan(text: post.caption),
        ],
      ),
    );
  }

  Widget _commentLine(IgComment comment) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: IgText.body(size: 13),
        children: <InlineSpan>[
          TextSpan(
            text: '${comment.user.handle} ',
            style: IgText.semibold(size: 13),
          ),
          TextSpan(text: comment.text),
        ],
      ),
    );
  }
}
