import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/fixtures.dart' as fixtures;
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';

/// A decoy conversation opened from the Messages tab.
///
/// Like the inbox, everything in here is fixture text held in memory: sending a
/// message only appends to this screen's local list. The encrypted threads the
/// app is actually for live behind the hidden session.
class MockChatScreen extends StatefulWidget {
  const MockChatScreen({super.key, required this.thread});

  final fixtures.DmThread thread;

  @override
  State<MockChatScreen> createState() => _MockChatScreenState();
}

class _MockLine {
  _MockLine({
    this.text = '',
    required this.mine,
    this.time = '',
    this.day,
    this.imagePath,
    this.reaction,
    this.edited = false,
  });

  final String text;
  final bool mine;
  final String time;

  /// Rendered as the centred grey separator above the line, e.g. `THU 9:04 PM`.
  final String? day;
  final String? imagePath;
  final String? reaction;
  final bool edited;
}

/// Conversation history per handle, so each thread opens on its own messages
/// instead of the same two lines everywhere.
final Map<String, List<_MockLine>> _seedLines = <String, List<_MockLine>>{
  'r2d1q': <_MockLine>[
    _MockLine(text: 'Nah', mine: false, time: '9:04 PM', day: 'THU 9:04 PM'),
    _MockLine(text: 'Yo', mine: true, time: '10:11 PM', day: 'THU 10:11 PM'),
    _MockLine(
      text: "Tmr we're going beach after jummah",
      mine: true,
      time: '10:11 PM',
    ),
    _MockLine(
      text: 'Me to gng with my fam',
      mine: false,
      time: '8:13 AM',
      day: 'YESTERDAY 8:13 AM',
    ),
    _MockLine(text: 'But which beach ?mm', mine: false, time: '8:14 AM'),
    _MockLine(text: '??', mine: false, time: '8:14 AM'),
    _MockLine(text: 'Seminar', mine: true, time: '8:16 AM'),
    _MockLine(text: 'Semisma', mine: true, time: '8:16 AM'),
    _MockLine(
      text: "I wont be able to come",
      mine: false,
      time: '8:19 AM',
      reaction: '👍',
      edited: true,
    ),
  ],
  'wisam.k123': <_MockLine>[
    _MockLine(
      text: 'Haha that was class 😂',
      mine: false,
      time: '6:20 PM',
      day: 'THU 6:20 PM',
    ),
    _MockLine(text: 'Bro the keeper was asleep', mine: false, time: '6:21 PM'),
    _MockLine(
      text: "Still can't believe it went in",
      mine: true,
      time: '6:24 PM',
    ),
    _MockLine(
      text: 'You watching the late one?',
      mine: true,
      time: '9:31 AM',
      day: 'TODAY 9:31 AM',
    ),
    _MockLine(text: 'Yeah, ping me at 10', mine: false, time: '9:33 AM'),
  ],
  'asmaagaber22': <_MockLine>[
    _MockLine(
      text: 'Sent you the notes 📚',
      mine: false,
      time: '4:05 PM',
      day: 'YESTERDAY 4:05 PM',
    ),
    _MockLine(text: "You're a lifesaver", mine: true, time: '4:07 PM'),
    _MockLine(
      text: 'Which chapter did the doctor stop at?',
      mine: true,
      time: '4:07 PM',
    ),
    _MockLine(text: 'Chapter 7, page 142', mine: false, time: '4:12 PM'),
    _MockLine(
      text: 'Also the summary slide is the important one',
      mine: false,
      time: '4:12 PM',
      reaction: '❤️',
    ),
    _MockLine(text: 'Got it, thanks 🙏', mine: true, time: '4:15 PM'),
  ],
  'keithlasono': <_MockLine>[
    _MockLine(
      text: 'Nehemiah 8:10 ✝️',
      mine: false,
      time: '7:42 AM',
      day: 'TODAY 7:42 AM',
    ),
    _MockLine(
      text: 'The joy of the Lord is your strength',
      mine: false,
      time: '7:42 AM',
    ),
    _MockLine(text: 'Needed this today', mine: true, time: '7:55 AM'),
    _MockLine(text: 'Praying for you bro', mine: false, time: '7:58 AM'),
  ],
  'gabar.mohammad': <_MockLine>[
    _MockLine(
      text: 'Replied to your story',
      mine: false,
      time: '2:18 PM',
      day: 'YESTERDAY 2:18 PM',
    ),
    _MockLine(text: 'Haha that photo was old', mine: true, time: '2:20 PM'),
    _MockLine(text: 'From 2019 right?', mine: false, time: '2:21 PM'),
    _MockLine(text: 'Yeah, graduation day', mine: true, time: '2:23 PM'),
    _MockLine(text: 'You look the same fr', mine: false, time: '2:24 PM'),
  ],
  'fwmoayaad': <_MockLine>[
    _MockLine(
      text: 'you around later?',
      mine: true,
      time: '11:02 AM',
      day: 'YESTERDAY 11:02 AM',
    ),
    _MockLine(text: 'Yeah, after 6', mine: false, time: '11:09 AM'),
    _MockLine(text: "Cool, I'll pass by", mine: true, time: '11:10 AM'),
    _MockLine(
      text: "Don't come empty handed 😂",
      mine: false,
      time: '11:11 AM',
      reaction: '😂',
    ),
  ],
  'ahmad_elsous': <_MockLine>[
    _MockLine(
      text: 'Co-founder call at 7?',
      mine: false,
      time: '8:15 AM',
      day: 'TODAY 8:15 AM',
    ),
    _MockLine(text: '7 works', mine: true, time: '8:17 AM'),
    _MockLine(text: "I'll send the deck before", mine: false, time: '8:18 AM'),
    _MockLine(text: "Let's keep it 30 mins max", mine: true, time: '8:20 AM'),
  ],
  'xelshiekh_7': <_MockLine>[
    _MockLine(
      text: '📍 Doha',
      mine: false,
      time: '12:40 PM',
      day: 'TODAY 12:40 PM',
    ),
    _MockLine(text: "How's the weather", mine: true, time: '12:44 PM'),
    _MockLine(text: 'Hot. Obviously 😅', mine: false, time: '12:45 PM'),
  ],
  'wtv.ysf11': <_MockLine>[
    _MockLine(
      text: 'Liked a message',
      mine: false,
      time: '5:12 PM',
      day: 'MON 5:12 PM',
    ),
    _MockLine(text: 'Appreciate you 🙌', mine: true, time: '5:20 PM'),
    _MockLine(text: 'Anytime', mine: false, time: '5:21 PM'),
  ],
  'txaha14': <_MockLine>[
    _MockLine(text: '🇵🇸', mine: true, time: '9:02 PM', day: 'SUN 9:02 PM'),
    _MockLine(text: 'Always 🇵🇸', mine: false, time: '9:05 PM'),
    _MockLine(text: 'Free Palestine', mine: true, time: '9:06 PM'),
  ],
};

class _MockChatScreenState extends State<MockChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late final List<_MockLine> _lines = <_MockLine>[
    ...?_seedLines[widget.thread.user.handle],
    if (!_seedLines.containsKey(widget.thread.user.handle))
      _MockLine(
        text: widget.thread.preview.replaceFirst('You: ', ''),
        mine: widget.thread.preview.startsWith('You: '),
        time: widget.thread.age,
        day: widget.thread.age.toUpperCase(),
      ),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _lines.add(_MockLine(text: text, mine: true, time: 'now'));
      _input.clear();
    });
  }

  Future<void> _sendImage(ImageSource source) async {
    XFile? file;
    try {
      // Opening the picker pauses the app; don't let that reset the session.
      file = await AppState.instance.keepSessionWhile(
        () => _picker.pickImage(
          source: source,
          maxWidth: 1600,
          imageQuality: 85,
        ),
      );
    } on Object {
      return;
    }
    if (file == null || !mounted) return;
    setState(() {
      _lines.add(_MockLine(mine: true, time: 'now', imagePath: file!.path));
    });
  }

  @override
  Widget build(BuildContext context) {
    final fixtures.IgUser user = widget.thread.user;

    return Scaffold(
      backgroundColor: IgColors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _header(user),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(13, 4, 13, 10),
                itemCount: _lines.length,
                itemBuilder: (BuildContext context, int index) => _line(
                  _lines[index],
                  _showAvatar(index),
                ),
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  /// A received line shows the peer's avatar unless the next received line
  /// continues the same burst.
  bool _showAvatar(int index) {
    final _MockLine line = _lines[index];
    if (line.mine) return false;
    final bool nextIsPeer = index + 1 < _lines.length && !_lines[index + 1].mine;
    return !nextIsPeer;
  }

  Widget _header(fixtures.IgUser user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      child: SizedBox(
        height: 54,
        child: Row(
          children: <Widget>[
            _circleButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 10),
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: NetImage(url: user.avatar),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          user.name.isEmpty ? user.handle : user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: IgText.semibold(size: 15),
                        ),
                      ),
                      if (user.isVerified) ...<Widget>[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 11),
                      ],
                      const Icon(Icons.chevron_right,
                          size: 16, color: IgColors.textSecondary),
                    ],
                  ),
                  Text(
                    user.isOnline ? 'Active now' : 'Active 18m ago',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        IgText.body(size: 11.5, color: IgColors.textSecondary),
                  ),
                ],
              ),
            ),
            _circleButton(
              icon: Icons.music_note,
              tooltip: 'Profile',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _circleButton(
              icon: Icons.call_outlined,
              tooltip: 'Call',
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _circleButton(
              icon: Icons.videocam_outlined,
              tooltip: 'Video call',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: IgColors.divider, width: 0.8),
          ),
          child: Icon(icon, size: 19, color: IgColors.textPrimary),
        ),
      ),
    );
  }

  Widget _line(_MockLine line, bool showAvatar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (line.day != null)
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: Text(
              line.day!,
              textAlign: TextAlign.center,
              style: IgText.medium(size: 11, color: IgColors.textSecondary),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            mainAxisAlignment:
                line.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              if (!line.mine)
                SizedBox(
                  width: 30,
                  child: showAvatar
                      ? ClipOval(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: NetImage(url: widget.thread.user.avatar),
                          ),
                        )
                      : null,
                ),
              if (!line.mine) const SizedBox(width: 7),
              Flexible(
                child: Column(
                  crossAxisAlignment: line.mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: <Widget>[
                    if (line.edited)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 4),
                        child: Text(
                          'Edited',
                          style: IgText.medium(size: 11, color: IgColors.blue),
                        ),
                      ),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                      ),
                      padding: line.imagePath == null
                          ? const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10)
                          : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        gradient: line.mine ? IgColors.sentBubble : null,
                        color: line.mine ? null : IgColors.bubbleIn,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(line.mine ? 20 : 6),
                          bottomRight: Radius.circular(line.mine ? 6 : 20),
                        ),
                      ),
                      clipBehavior: line.imagePath == null
                          ? Clip.none
                          : Clip.antiAlias,
                      child: line.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(line.mine ? 20 : 6),
                                bottomRight:
                                    Radius.circular(line.mine ? 6 : 20),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: 220, maxHeight: 280),
                                child: Image.file(
                                  File(line.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context,
                                          Object error, StackTrace? stack) =>
                                      Container(
                                    width: 180,
                                    height: 130,
                                    color: IgColors.surface,
                                    child: const Center(
                                      child: Icon(Icons.broken_image_outlined,
                                          color: IgColors.textTertiary),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              line.text,
                              style: IgText.body(
                                  size: 14.5, color: Colors.white, height: 1.3),
                            ),
                    ),
                    if (line.reaction != null)
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: const BoxDecoration(
                            color: IgColors.surfaceHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Text(line.reaction!,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                  ],
                ),
              ),
              if (line.mine) const SizedBox(width: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () => _sendImage(ImageSource.camera),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: IgColors.sentBubble,
              ),
              child: const Icon(Icons.photo_camera,
                  size: 20, color: Colors.white),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: IgColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: IgColors.divider, width: 0.6),
              ),
              child: TextField(
                controller: _input,
                style: IgText.body(size: 14),
                cursorColor: IgColors.textPrimary,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (String _) => setState(() {}),
                onSubmitted: (String _) => _send(),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle:
                      IgText.body(size: 14.5, color: IgColors.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 9),
                ),
              ),
            ),
          ),
          if (_input.text.trim().isNotEmpty)
            GestureDetector(
              onTap: _send,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('Send',
                    style: IgText.semibold(size: 14, color: IgColors.blue)),
              ),
            )
          else ...<Widget>[
            IconButton(
              tooltip: 'Voice note',
              onPressed: () {},
              icon: const Icon(Icons.mic_none, size: 24),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 38, height: 40),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              tooltip: 'Gallery',
              onPressed: () => _sendImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_outlined, size: 23),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 34, height: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
