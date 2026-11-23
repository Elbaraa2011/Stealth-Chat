import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/fixtures.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import 'primitives.dart';

Future<void> showCommentsSheet(BuildContext context, IgPost post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: IgColors.surface,
    barrierColor: const Color(0x99000000),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (BuildContext context) => CommentsSheet(post: post),
  );
}

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.post});

  final IgPost post;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  static const List<String> _emojis = <String>[
    '❤️',
    '🙌',
    '🔥',
    '👏',
    '🥰',
    '😍',
    '😮',
    '😂',
    '💯',
  ];

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit([String? preset]) {
    final String text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    AppState.instance.addComment(
      widget.post.id,
      IgComment(text, me, age: 'now'),
    );
    _controller.clear();
    setState(() {});
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double available =
        media.size.height - media.viewInsets.bottom - media.padding.top - 24;
    final double sheetHeight =
        math.min(media.size.height * 0.74, math.max(320, available));
    final List<IgComment> comments =
        AppState.instance.commentsFor(widget.post.id, []);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: IgColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Comments',
              style: IgText.semibold(size: 14),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: IgColors.divider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: comments.length,
                itemBuilder: (BuildContext context, int index) =>
                    _CommentRow(comment: comments[index]),
              ),
            ),
            const Divider(height: 1, color: IgColors.divider),
            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _emojis.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    onTap: () => _submit(_emojis[index]),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Center(
                        child: Text(
                          _emojis[index],
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _composer(media),
          ],
        ),
      ),
    );
  }

  Widget _composer(MediaQueryData media) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + (media.viewInsets.bottom > 0 ? 6 : media.padding.bottom + 6),
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: IgColors.divider, width: 0.6)),
      ),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 30,
              height: 30,
              child: NetImage(url: me.avatar),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              style: IgText.body(size: 13.5),
              textInputAction: TextInputAction.send,
              onSubmitted: (String _) => _submit(),
              decoration: InputDecoration(
                hintText: 'Add a comment for ${widget.post.user.handle}...',
                hintStyle: IgText.body(
                  size: 13.5,
                  color: IgColors.textTertiary,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (BuildContext context, TextEditingValue value, Widget? _) {
              final bool enabled = value.text.trim().isNotEmpty;
              return TextButton(
                onPressed: enabled ? _submit : null,
                style: TextButton.styleFrom(
                  foregroundColor: IgColors.blue,
                  minimumSize: const Size(48, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  'Post',
                  style: IgText.semibold(
                    size: 13.5,
                    color: enabled
                        ? IgColors.blue
                        : IgColors.blue.withValues(alpha: 0.4),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final IgComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: NetImage(url: comment.user.avatar),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    style: IgText.body(size: 13.5),
                    children: <InlineSpan>[
                      TextSpan(
                        text: '${comment.user.handle} ',
                        style: IgText.semibold(size: 13),
                      ),
                      TextSpan(text: comment.text),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Text(
                      comment.age,
                      style: IgText.body(
                        size: 11,
                        color: IgColors.textTertiary,
                      ),
                    ),
                    if (comment.likes > 0) ...<Widget>[
                      const SizedBox(width: 12),
                      Text(
                        '${comment.likes} likes',
                        style: IgText.semibold(
                          size: 11,
                          color: IgColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Text(
                      'Reply',
                      style: IgText.semibold(
                        size: 11,
                        color: IgColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 4),
            child: Icon(Icons.favorite_border, size: 14),
          ),
        ],
      ),
    );
  }
}
