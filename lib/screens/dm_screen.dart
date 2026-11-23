import 'package:flutter/material.dart';

import '../data/fixtures.dart' as fixtures;
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';
import 'mock_chat_screen.dart';
import 'stealth_session_screen.dart';

// Pushys app section: wires the public identity row through to the inbox so
// the username pill, the 'Your messages' label and the 'my' note all render
// the signed-in handle (jade12 once someone signs up or logs in) instead of
// the decoy fixture handle.

/// The Messages tab — the decoy inbox.
///
/// Everything here comes from [fixtures]. It is the cover story: ordinary
/// Instagram-looking conversations with the seeded accounts, no backend calls,
/// nothing stored. The real message list lives in the hidden session
/// (`StealthSessionScreen`), which is opened by typing `//open` into this
/// screen's search field.
class DmScreen extends StatefulWidget {
  const DmScreen({super.key});

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _Note {
  _Note(this.user, this.text, {this.mine = false});
  final dynamic user;
  final String text;
  final bool mine;
}

/// Notes that sit above the inbox, same as the real app.
final List<_Note> _notes = <_Note>[
  _Note(AppState.instance.me, '', mine: true),

  _Note(fixtures.wisam, 'match day 🔥'),
  _Note(fixtures.asmaagaber, 'notes are ready 📚'),
  _Note(fixtures.theo, 'streaming at 9'),
  _Note(fixtures.maria, 'new piece tonight 🎨'),
];


class _DmScreenState extends State<DmScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<fixtures.DmThread> get _threads {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return fixtures.dmThreads;
    return fixtures.dmThreads
        .where((fixtures.DmThread thread) =>
            thread.user.handle.toLowerCase().contains(q) ||
            thread.user.name.toLowerCase().contains(q) ||
            thread.preview.toLowerCase().contains(q))
        .toList();
  }

  /// The hidden door: typing `//open` in the search box opens the real
  /// session. The text is consumed so the decoy inbox never filters on it.
  void _onSearchChanged(String value) {
    if (value.trim().toLowerCase() == '//open') {
      _search.clear();
      setState(() => _query = '');
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const StealthSessionScreen()),
      );
      return;
    }
    setState(() => _query = value);
  }

  void _openThread(fixtures.DmThread thread) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => MockChatScreen(thread: thread)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IgColors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 14),
                children: <Widget>[
                  _searchField(),
                  _notesRow(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                    child: Row(
                      children: <Widget>[
                        Text('Messages', style: IgText.semibold(size: 15)),
                        const Spacer(),
                        Text('Requests',
                            style: IgText.body(
                                size: 13, color: IgColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (_threads.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 34, 16, 0),
                      child: Column(
                        children: <Widget>[
                          const Icon(Icons.search_off,
                              size: 30, color: IgColors.textTertiary),
                          const SizedBox(height: 10),
                          Text('No results found.',
                              style: IgText.body(
                                  size: 13, color: IgColors.textTertiary)),
                        ],
                      ),
                    )
                  else
                    for (final fixtures.DmThread thread in _threads)
                      _ThreadRow(
                        thread: thread,
                        onTap: () => _openThread(thread),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                AppState.instance.me.handle,
                style: IgText.semibold(size: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.keyboard_arrow_down,
                size: 20, color: null),
            const Spacer(),
            IconButton(
              tooltip: 'New message',
              onPressed: () {},
              icon: const Icon(Icons.edit_square, size: 22),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: IgColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            const IgSvgIcon(
              asset: 'assets/icons/search.svg',
              size: 15,
              color: IgColors.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _search,
                style: IgText.body(size: 13.5),
                cursorColor: IgColors.textPrimary,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search',
                  hintStyle:
                      IgText.body(size: 13.5, color: IgColors.textTertiary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notesRow() {
    return SizedBox(
      height: 166,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 0),
        itemCount: _notes.length,
        itemBuilder: (BuildContext context, int index) =>
            _NoteTile(note: _notes[index]),
      ),
    );
  }
}

/// One note in the row: a large avatar circle with the note itself in a speech
/// bubble overlapping its top-left corner, and the author's name under it —
/// the layout Instagram uses above the inbox.
class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final _Note note;

  static const double _tile = 124;
  static const double _avatar = 88;

  @override
  Widget build(BuildContext context) {
    final bool empty = note.text.trim().isEmpty;
    final bool online = note.user is fixtures.IgUser &&
        (note.user as fixtures.IgUser).isOnline;
    final String label = note.mine ? 'Your note' : (note.user.name as String);

    return SizedBox(
      width: _tile,
      height: 148,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: _NoteBubble.bodyHeight - _NoteBubble.tailHeight,
            left: (_tile - _avatar) / 2,
            child: _NoteAvatar(url: note.user.avatar, online: online),
          ),
          Positioned(
            top: 0,
            left: 7,
            child: _NoteBubble(
              text: empty ? 'Your thoughts go here...' : note.text,
              placeholder: empty,
            ),
          ),
          Positioned(
            top: 130,
            left: 0,
            width: _tile,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: IgText.body(size: 13.5, color: IgColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The avatar circle under the bubble, with a thin ring and a presence dot.
class _NoteAvatar extends StatelessWidget {
  const _NoteAvatar({required this.url, required this.online});

  final String url;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _NoteTile._avatar,
      height: _NoteTile._avatar,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: IgColors.bg,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF272B30), width: 1.5),
              ),
              child: ClipOval(child: NetImage(url: url)),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: IgColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(color: IgColors.bg, width: 3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The note itself: a rounded speech bubble with a short tail at the
/// bottom-left, like Instagram's notes.
class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.text, required this.placeholder});

  final String text;
  final bool placeholder;

  static const double width = 106;
  static const double bodyHeight = 46;
  static const double tailHeight = 10;
  static const double radius = 15.6;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _NoteBubblePainter(),
      child: SizedBox(
        width: width,
        height: bodyHeight + tailHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(11, 9, 11, 0),
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: IgText.body(
              size: 12.5,
              color: placeholder ? const Color(0xFFA6A9B2) : IgColors.textPrimary,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline from the reference: #2b3036 fill, #55585e 1.1pt stroke, and the
/// tail curving down from the bottom-left edge.
class _NoteBubblePainter extends CustomPainter {
  const _NoteBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double body = _NoteBubble.bodyHeight;
    final double r = _NoteBubble.radius;
    final double w = size.width;
    final Path path = Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, body - r)
      ..quadraticBezierTo(w, body, w - r, body)
      ..lineTo(25.5, body)
      ..cubicTo(19, body, 15.8, body + 4, 14.9, body + 9.6)
      ..cubicTo(14.5, body + 11.3, 13.1, body + 11, 12.6, body + 9)
      ..lineTo(12, body)
      ..lineTo(r, body)
      ..quadraticBezierTo(0, body, 0, body - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2B3036)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF55585E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _NoteBubblePainter oldDelegate) => false;
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onTap});

  final fixtures.DmThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fixtures.IgUser user = thread.user;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: <Widget>[
                  ClipOval(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: NetImage(url: user.avatar),
                    ),
                  ),
                  if (user.isOnline)
                    const Positioned(right: 1, bottom: 1, child: OnlineDot()),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          user.name.isEmpty ? user.handle : user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: IgText.semibold(size: 13.5),
                        ),
                      ),
                      if (user.isVerified) ...<Widget>[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 11),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.handle} · ${thread.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IgText.body(size: 11.5, color: IgColors.textTertiary),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          thread.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: IgText.body(
                            size: 12.5,
                            color: thread.unread
                                ? IgColors.textPrimary
                                : IgColors.textSecondary,
                            weight: thread.unread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (thread.seen && !thread.unread)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.done_all,
                              size: 14, color: IgColors.textTertiary),
                        ),
                      if (thread.unread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 7),
                          decoration: const BoxDecoration(
                            color: IgColors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
