import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import '../backend/dm_message.dart';
import '../backend/messages_service.dart';
import '../backend/models.dart';
import '../backend/storage_service.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';

/// A one-to-one stealth conversation against the `dm_messages` table.
///
/// Messages are text, a photo from the gallery, or a recorded voice note.
/// Attachments are uploaded to the `dm-media` bucket first and the row stores
/// only the public URL, so the thread stays small.
class SecretChatScreen extends StatefulWidget {
  const SecretChatScreen({super.key, required this.peer});

  /// The registered user this thread is with.
  final StealthUser peer;

  @override
  State<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends State<SecretChatScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  List<DmMessage> _thread = <DmMessage>[];
  Timer? _poll;
  Timer? _recordTicker;

  bool _loading = true;
  bool _sending = false;
  bool _recording = false;
  String? _error;
  String? _sendError;
  int _recordSeconds = 0;

  @override
  void initState() {
    super.initState();
    _load();
    MessagesService.instance
        .markRead(otherUsername: widget.peer.username)
        .catchError((Object _) {});
    _poll = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    _recordTicker?.cancel();
    _recorder.dispose();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final List<DmMessage> messages =
          await MessagesService.instance.threadWith(widget.peer.username);
      if (!mounted) return;
      setState(() {
        _thread = messages;
        _loading = false;
        _error = null;
      });
      if (!silent) _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent) {
          _error = 'Could not load messages: $error';
        }
      });
    }
  }

  // --------------------------------------------------------------- sending

  Future<void> _sendText() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    _input.clear();
    setState(() {});
    await _send(body: text);
  }

  Future<void> _send({
    String body = '',
    String? mediaUrl,
    String? mediaType,
    int? durationMs,
  }) async {
    if (_sending) return;
    await _sendMessage(
      body: body,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      durationMs: durationMs,
    );
  }

  /// Writes the row and refreshes the thread. Media sends set [_sending] while
  /// they upload, so they call this directly instead of going through the
  /// guarded [_send] above.
  Future<void> _sendMessage({
    String body = '',
    String? mediaUrl,
    String? mediaType,
    int? durationMs,
  }) async {
    if (!mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await MessagesService.instance.sendDm(
        targetUsername: widget.peer.username,
        body: body,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        durationMs: durationMs,
        from: AppState.instance.me,
      );
      await _load(silent: true);
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Photo that stays inside the secret chat, either taken with the camera or
  /// picked from the gallery. On any failure the UI keeps the user inside this
  /// screen and surfaces the chat's error line rather than unwinding back to the
  /// decoy tab.
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_sending) return;
    XFile? file;
    try {
      // Keep the covert session alive while the camera/gallery is on screen.
      file = await AppState.instance.keepSessionWhile(
        () => _picker.pickImage(
          source: source,
          maxWidth: 1800,
          imageQuality: 85,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _sendError = source == ImageSource.camera
            ? 'Could not open the camera: $error'
            : 'Could not open the gallery: $error';
      });
      return;
    }
    if (file == null) return;

    setState(() {
      _sending = true;
      _error = null;
      _sendError = null;
    });
    try {
      final String url = await MediaStorage.instance.uploadBytesWithRetry(
        bytes: await file.readAsBytes(),
        fileName: file.name.isEmpty ? 'photo.jpg' : file.name,
        contentType: file.mimeType ?? 'image/jpeg',
      );
      await _sendMessage(mediaUrl: url, mediaType: 'image');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = 'Could not send the photo: $error';
      });
    }
  }

  /// Hold-to-record voice note. Recording failures, permission issues and
  /// send failures stay inside this chat and surface on the chat's error line.
  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopAndSendVoice();
      return;
    }
    if (_sending) return;
    try {
      if (!await AppState.instance.keepSessionWhile(_recorder.hasPermission)) {
        if (!mounted) return;
        setState(() {
          _error = 'Microphone permission is required';
          _sendError = null;
        });
        return;
      }
      final Directory dir = await getTemporaryDirectory();
      final String path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await AppState.instance.keepSessionWhile(
        () => _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
          path: path,
        ),
      );
      if (!mounted) return;
      setState(() {
        _recording = true;
        _recordSeconds = 0;
        _error = null;
        _sendError = null;
      });
      _recordTicker?.cancel();
      _recordTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not start recording: $error';
        _sendError = null;
      });
    }
  }

  Future<void> _cancelRecording() async {
    _recordTicker?.cancel();
    try {
      await _recorder.cancel();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordSeconds = 0;
    });
  }

  Future<void> _stopAndSendVoice() async {
    _recordTicker?.cancel();
    final int seconds = _recordSeconds;
    String? path;
    try {
      path = await _recorder.stop();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _recording = false;
        _recordSeconds = 0;
        _error = 'Could not finish the recording: $error';
        _sendError = null;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _recording = false;
      _recordSeconds = 0;
    });
    if (path == null) return;

    if (seconds < 1) {
      if (mounted) {
        setState(() {
          _error = 'Hold on a little longer — voice notes need at least a second';
          _sendError = null;
        });
      }
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _sendError = null;
    });
    try {
      final String url = await MediaStorage.instance.uploadBytesWithRetry(
        bytes: await File(path).readAsBytes(),
        fileName: 'voice.m4a',
        contentType: 'audio/mp4',
      );
      await _sendMessage(
        mediaUrl: url,
        mediaType: 'voice',
        durationMs: seconds * 1000,
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = null;
        _sendError = 'Could not send the voice note: $error';
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  // ------------------------------------------------------------------ ui

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IgColors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _header(),
            const Divider(height: 1, color: IgColors.divider),
            if (_error != null || _sendError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _error ?? _sendError!,
                  textAlign: TextAlign.center,
                  style: IgText.body(size: 11.5, color: IgColors.red),
                ),
              ),
            Expanded(child: _messageList()),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 3, 12, 3),
      child: SizedBox(
        height: 51,
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back, size: 23),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                if (!mounted) return;
                final bool exit = await _confirmExit();
                if (!mounted) return;
                if (exit) {
                  Navigator.of(context).maybePop();
                }
              },
            ),
            const SizedBox(width: 3),
            UserAvatar(
              name: widget.peer.username,
              url: widget.peer.avatar,
              size: 33,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.peer.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IgText.semibold(size: 14),
                  ),
                  Text(
                    '@${widget.peer.username} · Stealth chat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IgText.body(size: 11, color: IgColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (_sending)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: IgColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _messageList() {
    if (_loading && _thread.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: IgColors.textSecondary,
          ),
        ),
      );
    }
    if (_thread.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'No messages yet. Say hello — only the two of you can see this '
            'thread.',
            textAlign: TextAlign.center,
            style: IgText.body(size: 13, color: IgColors.textTertiary),
          ),
        ),
      );
    }

    final String me = AppState.instance.me.username;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
      itemCount: _thread.length,
      itemBuilder: (BuildContext context, int index) {
        final DmMessage message = _thread[index];
        return ChatBubble(
          message: message,
          mine: message.fromUsername == me,
          time: _clock(message.sentAt),
        );
      },
    );
  }

  Widget _composer() {
    if (_recording) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: IgColors.divider, width: 0.6)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 9,
              height: 9,
              decoration:
                  const BoxDecoration(color: IgColors.red, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Text(
              'Recording ${formatDuration(Duration(seconds: _recordSeconds))}',
              style: IgText.semibold(size: 13.5),
            ),
            const Spacer(),
            TextButton(
              onPressed: _cancelRecording,
              child: Text('Cancel',
                  style:
                      IgText.semibold(size: 13, color: IgColors.textSecondary)),
            ),
            IconButton(
              tooltip: 'Send voice note',
              onPressed: _stopAndSendVoice,
              icon: const Icon(Icons.send, size: 22, color: IgColors.blue),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 9),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: IgColors.divider, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          IconButton(
            tooltip: 'Take photo',
            onPressed: _sending
                ? null
                : () => _pickAndSendImage(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined, size: 23),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 38, height: 40),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            tooltip: 'Add photo',
            onPressed: _sending
                ? null
                : () => _pickAndSendImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_outlined, size: 23),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 34, height: 40),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 42),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: IgColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: IgColors.divider, width: 0.6),
              ),
              child: TextField(
                controller: _input,
                focusNode: _focus,
                style: IgText.body(size: 14),
                cursorColor: IgColors.textPrimary,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (String _) => setState(() {}),
                onSubmitted: (String _) => _sendText(),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle:
                      IgText.body(size: 14, color: IgColors.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          if (_input.text.trim().isNotEmpty)
            GestureDetector(
              onTap: _sendText,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _sending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: IgColors.blue,
                        ),
                      )
                    : Text('Send',
                        style: IgText.semibold(size: 14, color: IgColors.blue)),
              ),
            )
          else
            IconButton(
              tooltip: 'Record voice note',
              onPressed: _sending ? null : _toggleRecording,
              icon: const Icon(Icons.mic_none, size: 23),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 38, height: 40),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  static String _clock(DateTime time) {
    final int hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Called when the in-chat back gesture would eject the user into the
  /// decoy. We confirm before allowing it so a mis-tap cannot drop the user
  /// out of the secret session.
  Future<bool> _confirmExit() async {
    final bool ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: IgColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            title: Text('Leave stealth chat?',
                style: IgText.semibold(size: 16)),
            content: Text(
                'Unsent messages and recordings will be lost.',
                style: IgText.body(size: 13.5)),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel',
                    style: IgText.medium(size: 14, color: IgColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Leave',
                    style: IgText.medium(size: 14, color: IgColors.red)),
              ),
            ],
          ),
        ) ==
        true;
    return ok;
  }
}

/// One message bubble. Public so the voice/image build paths can be exercised
/// directly in widget tests.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.time,
  });

  final DmMessage message;
  final bool mine;
  final String time;

  @override
  Widget build(BuildContext context) {
    final Color surface = mine ? Colors.transparent : IgColors.bubbleIn;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.74),
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              gradient: mine && !message.isImage ? IgColors.sentBubble : null,
              color: message.isImage ? IgColors.surface : surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(mine ? 20 : 6),
                bottomRight: Radius.circular(mine ? 6 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (message.isImage)
                  ImageAttachment(url: message.mediaUrl!, mine: mine),
                if (message.isVoice)
                  VoiceAttachment(
                    url: message.mediaUrl!,
                    duration: message.voiceLength,
                    mine: mine,
                  ),
                if (message.body.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Text(
                      message.body,
                      style: IgText.body(
                          size: 14, color: Colors.white, height: 1.32),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(time,
                style: IgText.body(size: 9.5, color: IgColors.textTertiary)),

          ),
        ],
      ),
    );
  }
}

/// Photo inside a bubble, tap for full screen.
class ImageAttachment extends StatelessWidget {
  const ImageAttachment({super.key, required this.url, required this.mine});

  final String url;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: Colors.black,
        builder: (BuildContext context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stack) =>
                    Text('Photo unavailable',
                        style: IgText.body(
                            size: 13, color: IgColors.textTertiary)),
              ),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(mine ? 20 : 6),
          bottomRight: Radius.circular(mine ? 6 : 20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230, maxHeight: 300),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? progress) {
              if (progress == null) return child;
              return const SizedBox(
                width: 230,
                height: 180,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: IgColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) =>
                    const SizedBox(
              width: 200,
              height: 120,
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    color: IgColors.textTertiary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Voice note with inline playback.
class VoiceAttachment extends StatefulWidget {
  const VoiceAttachment({
    super.key,
    required this.url,
    required this.duration,
    required this.mine,
  });

  final String url;
  final Duration duration;
  final bool mine;

  @override
  State<VoiceAttachment> createState() => _VoiceAttachmentState();
}

class _VoiceAttachmentState extends State<VoiceAttachment> {
  VideoPlayerController? _controller;
  bool _playing = false;
  bool _loading = false;
  String? _failure;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_loading) return;
    try {
      if (_controller == null) {
        setState(() => _loading = true);
        final VideoPlayerController controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.url));
        await controller.initialize();
        controller.addListener(_onTick);
        if (!mounted) {
          controller.dispose();
          return;
        }
        _controller = controller;
        setState(() => _loading = false);
      }

      final VideoPlayerController controller = _controller!;
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        if (controller.value.position >= controller.value.duration) {
          await controller.seekTo(Duration.zero);
        }
        await controller.play();
      }
      if (mounted) {
        setState(() => _playing = controller.value.isPlaying);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = 'Playback failed';
      });
    }
  }

  void _onTick() {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !mounted) return;
    if (!controller.value.isPlaying && _playing) {
      setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The controller only exists once the user starts playback, so fall back
    // to the recorded length until then. Reading `_controller!` here used to
    // throw and take the whole message list down to a red error box.
    final Duration reported = _controller?.value.duration ?? Duration.zero;
    final Duration total =
        reported.inMilliseconds > 0 ? reported : widget.duration;
    final Duration position = _controller?.value.position ?? Duration.zero;
    final double progress = total.inMilliseconds == 0
        ? 0
        : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                onTap: _failure == null ? _toggle : null,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _playing
                              ? Icons.pause
                              : (_failure != null
                                  ? Icons.error_outline
                                  : Icons.play_arrow),
                          size: 21,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 96,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _failure ?? formatDuration(total),
                    style: IgText.body(size: 10.5, color: Colors.white70),
                  ),
                ],
              ),
            ],

          ),
        ],
      ),
    );
  }
}
