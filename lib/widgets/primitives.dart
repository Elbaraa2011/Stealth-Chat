import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/ig_theme.dart';

/// User-provided local image. An empty path intentionally leaves a neutral
/// placeholder until the user supplies media.
class NetImage extends StatelessWidget {
  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _blank();
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            _blank(),
      );
    }
    return _blank();
  }

  Widget _blank() => SizedBox(
        width: width,
        height: height,
        child: const ColoredBox(color: IgColors.mediaPlaceholder),
      );
}

/// Avatar for a backend user.
///
/// Draws the profile photo when one is set, and otherwise a neutral circle with
/// the first letter of the handle — real accounts start with no photo.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.url,
    this.size = 46,
  });

  final String name;
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = ColoredBox(
      color: IgColors.surfaceHigh,
      child: Center(
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: IgText.semibold(
            size: size * 0.42,
            color: IgColors.textSecondary,
          ),
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stack) =>
                    fallback,
              ),
      ),
    );
  }
}

/// Blue check next to verified handles.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 12});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.verified, size: size, color: Color(0xFF0095F6));
}

/// Gradient ring around story and profile avatars. Viewed stories drop
/// to a flat divider-grey ring. Authentic Instagram dimensions:
/// outer container 86×86, stroke 2.5px, inner gap 3px, inner avatar 74×74.
/// If [closeFriend] is true, a neon-green ring (#10D642) is drawn instead
/// of the gradient.
class StoryRing extends StatelessWidget {
  const StoryRing({
    super.key,
    required this.child,
    this.size = 86,
    this.viewed = false,
    this.strokeWidth = 2.5,
    this.gap = 3,
    this.closeFriend = false,
  });

  final Widget child;
  final double size;
  final bool viewed;
  final double strokeWidth;
  final double gap;
  final bool closeFriend;

  @override
  Widget build(BuildContext context) {
    final Color ringColor = viewed
        ? IgColors.divider
        : closeFriend
            ? IgColors.online
            : Colors.transparent;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ringColor == Colors.transparent ? IgColors.storyRing : null,
        color: ringColor == Colors.transparent ? null : ringColor,
      ),
      padding: EdgeInsets.all(strokeWidth),
      child: Container(
        padding: EdgeInsets.all(gap),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: IgColors.bg,
        ),
        child: ClipOval(child: child),
      ),
    );
  }
}

/// Presence dot used across the DM list and profile headers.
class OnlineDot extends StatelessWidget {
  const OnlineDot({super.key, this.size = 12});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1CD14F),
        border: Border.all(color: Color(0xFF000000), width: 2),
      ),
    );
  }
}

/// Reels glyph drawn to match Instagram's rounded-square play mark.
class IgSvgIcon extends StatelessWidget {
  const IgSvgIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.color = IgColors.textPrimary,
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        fit: BoxFit.contain,
      );
}

class ReelsIcon extends StatelessWidget {
  const ReelsIcon({
    super.key,
    required this.size,
    required this.color,
    required this.filled,
  });

  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _ReelsPainter(color: color, filled: filled),
      );
}

class _ReelsPainter extends CustomPainter {
  _ReelsPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double inset = w * 0.06;
    final Rect rect = Rect.fromLTRB(inset, inset, w - inset, h - inset);
    final RRect body = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.28));

    if (filled) {
      canvas.drawRRect(body, Paint()..color = color);
      final Path detail = Path()
        ..moveTo(inset, h * 0.31)
        ..lineTo(w - inset, h * 0.31)
        ..moveTo(w * 0.34, inset)
        ..lineTo(w * 0.47, h * 0.31)
        ..moveTo(w * 0.62, inset)
        ..lineTo(w * 0.75, h * 0.31);
      canvas.drawPath(
        detail,
        Paint()
          ..color = Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.075,
      );
      final Path play = Path()
        ..moveTo(w * 0.43, h * 0.44)
        ..lineTo(w * 0.43, h * 0.76)
        ..lineTo(w * 0.71, h * 0.60)
        ..close();
      canvas.drawPath(play, Paint()..color = Color(0xFF000000));
      return;
    }

    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.078
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(body, stroke);

    final Path detail = Path()
      ..moveTo(inset, h * 0.31)
      ..lineTo(w - inset, h * 0.31)
      ..moveTo(w * 0.34, inset)
      ..lineTo(w * 0.47, h * 0.31)
      ..moveTo(w * 0.62, inset)
      ..lineTo(w * 0.75, h * 0.31);
    canvas.drawPath(detail, stroke);

    final Path play = Path()
      ..moveTo(w * 0.44, h * 0.45)
      ..lineTo(w * 0.44, h * 0.75)
      ..lineTo(w * 0.70, h * 0.60)
      ..close();
    canvas.drawPath(
      play,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.075
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ReelsPainter old) =>
      old.color != color || old.filled != filled;
}

/// Rotating record badge in the action column.
class _VinylDisc extends StatefulWidget {
  const _VinylDisc({required this.url});

  final String url;

  @override
  State<_VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<_VinylDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              NetImage(url: widget.url),
              Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000),
                    shape: BoxShape.circle,
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

/// Ping-pong marquee for the audio attribution line.
class _TickerText extends StatefulWidget {
  const _TickerText(this.text);

  final String text;

  @override
  State<_TickerText> createState() => _TickerTextState();
}

class _TickerTextState extends State<_TickerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scroll = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(fontSize: 12, color: Colors.white);
    return ClipRect(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final TextPainter painter = TextPainter(
            text: TextSpan(text: widget.text, style: style),
            maxLines: 1,
            textDirection: Directionality.of(context),
          )..layout();
          final double overflow = painter.width - constraints.maxWidth;
          if (overflow <= 0) {
            return Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            );
          }
          return AnimatedBuilder(
            animation: _scroll,
            builder: (BuildContext context, Widget? _) {
              final double t = _scroll.value * 2;
              final double phase = t <= 1 ? t : 2 - t;
              return Transform.translate(
                offset: Offset(-(overflow + 16) * phase, 0),
                child: Text(
                  widget.text,
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
