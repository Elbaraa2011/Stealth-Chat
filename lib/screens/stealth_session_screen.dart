import 'package:flutter/material.dart';

import '../backend/contacts_service.dart';
import '../backend/dm_message.dart';
import '../backend/messages_service.dart';
import '../backend/models.dart';
import '../backend/supabase_client.dart';
import '../backend/users_service.dart';
import '../state/app_state.dart';
import '../theme/ig_theme.dart';
import '../widgets/primitives.dart';
import 'secret_chat_screen.dart';

/// The hidden session: the real message list.
/// This is the screen the app exists for, and it is deliberately not a tab.
/// Type `//open` into the Messages search field to open it. Every row comes
/// from `dm_contacts` / `dm_messages`, the friend search reads `users`, and an
/// empty list says so — there are no seeded conversations past this door.
class StealthSessionScreen extends StatefulWidget {
  const StealthSessionScreen({super.key});

  @override
  State<StealthSessionScreen> createState() => _StealthSessionScreenState();
}

class _Row {
  _Row({required this.user, this.latest, this.unread = 0});

  final StealthUser user;
  final DmMessage? latest;
  final int unread;

  String get age => latest == null ? '' : formatAge(latest!.sentAt);
}

class _StealthSessionScreenState extends State<StealthSessionScreen> {
  List<_Row> _rows = <_Row>[];
  bool _loading = true;
  String? _error;

  bool get _signedIn =>
      SupabaseClient.instance.isConfigured && SupabaseClient.instance.isSignedIn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_signedIn) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rows = <_Row>[];
        _error = null;
      });
      return;
    }
    try {
      final List<StealthUser> contacts =
          await ContactsService.instance.myContacts();
      final List<DmConversation> threads =
          await MessagesService.instance.conversations();

      final Map<String, DmConversation> byId = <String, DmConversation>{
        for (final DmConversation thread in threads) thread.otherUser.id: thread,
      };

      final List<_Row> rows = <_Row>[];
      final Set<String> seen = <String>{};
      for (final StealthUser contact in contacts) {
        final DmConversation? thread = byId[contact.id];
        rows.add(_Row(
          user: contact,
          latest: thread?.latestMessage,
          unread: thread?.unreadCount ?? 0,
        ));
        seen.add(contact.id);
      }
      // A thread can exist for someone removed from the friend list; it stays
      // visible so the conversation is never silently lost.
      for (final DmConversation thread in threads) {
        if (seen.contains(thread.otherUser.id)) continue;
        rows.add(_Row(
          user: thread.otherUser,
          latest: thread.latestMessage,
          unread: thread.unreadCount,
        ));
      }

      rows.sort((_Row a, _Row b) {
        final DateTime aTime =
            a.latest?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.latest?.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rows = <_Row>[];
        _error = '$error';
      });
    }
  }

  void _openThread(StealthUser user) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SecretChatScreen(peer: user),
      ),
    );
  }

  Future<void> _openAddFriend() async {
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IgColors.surface,
      builder: (_) => const _AddFriendSheet(),
    );
    if (added == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IgColors.bg,
      appBar: AppBar(
        backgroundColor: IgColors.bg,
        title: Text('Messages', style: IgText.semibold(size: 16)),
        actions: <Widget>[
          if (_signedIn)
            IconButton(
              tooltip: 'Add friends',
              onPressed: _openAddFriend,
              icon: const Icon(Icons.person_add_alt, size: 22),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: IgColors.textSecondary,
          backgroundColor: IgColors.surface,
          onRefresh: _load,
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (!_signedIn) return _signedOut();
    if (_loading) {
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
    if (_error != null) {
      return _centerMessage(
        icon: Icons.error_outline,
        title: 'Could not load your messages',
        detail: _error,
      );
    }
    if (_rows.isEmpty) return _empty();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _rows.length,
      itemBuilder: (BuildContext context, int index) {
        final _Row row = _rows[index];
        return _ThreadRow(row: row, onTap: () => _openThread(row.user));
      },
    );
  }

  Widget _signedOut() {
    return _centerMessage(
      icon: Icons.lock_outline,
      title: 'Sign in to open the session',
      detail: 'The real inbox lives behind your account, not the decoy one.',
    );
  }

  Widget _empty() {
    return _centerMessage(
      icon: Icons.forum_outlined,
      title: 'Add friends to start chatting',
      detail: 'Search a username and add them — only people in your list '
          'show up here.',
      action: TextButton(
        onPressed: _openAddFriend,
        child: Text('Add friends', style: IgText.semibold(size: 13.5)),
      ),
    );
  }

  Widget _centerMessage({
    required IconData icon,
    required String title,
    String? detail,
    Widget? action,
  }) {
    return ListView(
      children: <Widget>[
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 34, color: IgColors.textTertiary),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center, style: IgText.semibold(size: 15)),
              if (detail != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: IgText.body(size: 12.5, color: IgColors.textTertiary),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: 10),
                action,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A thread row in the session list.
class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.row, required this.onTap});

  final _Row row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DmMessage? latest = row.latest;
    final bool mine =
        latest != null && latest.fromUsername == AppState.instance.me.username;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Row(
          children: <Widget>[
            UserAvatar(
              name: row.user.username,
              url: row.user.avatar,
              size: 52,
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
                          row.user.displayName.isEmpty
                              ? row.user.username
                              : row.user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: IgText.semibold(size: 13.5),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        row.age,
                        style: IgText.body(
                            size: 11.5, color: IgColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          previewFor(latest),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: IgText.body(
                            size: 12.5,
                            color: row.unread > 0
                                ? IgColors.textPrimary
                                : IgColors.textSecondary,
                            weight: row.unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (row.unread > 0)
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
                  const SizedBox(height: 2),
                  Text(
                    '@${row.user.username} · ${mine ? 'You' : 'Stealth chat'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IgText.body(size: 11, color: IgColors.textTertiary),
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

/// Username search that adds a person to `dm_contacts`.
class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet();

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final TextEditingController _query = TextEditingController();
  List<StealthUser> _results = <StealthUser>[];
  final Set<String> _added = <String>{};
  final Set<String> _loadingIds = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    setState(() => _loading = true);
    try {
      final List<StealthUser> found =
          await UsersService.instance.searchUsernames(value);
      final Set<String> contacts = await ContactsService.instance.contactIds();
      if (!mounted) return;
      setState(() {
        _results = found;
        _added
          ..clear()
          ..addAll(contacts);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = <StealthUser>[];
        _loading = false;
      });
    }
  }

  Future<void> _add(StealthUser user) async {
    setState(() => _loadingIds.add(user.id));
    try {
      await ContactsService.instance.add(user);
      if (!mounted) return;
      setState(() {
        _added.add(user.id);
        _loadingIds.remove(user.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingIds.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 14),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: IgColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: <Widget>[
                  Text('Add friends', style: IgText.semibold(size: 15)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Done',
                        style: IgText.semibold(
                            size: 13, color: IgColors.blue)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: IgColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _query,
                  autofocus: true,
                  style: IgText.body(size: 13.5),
                  cursorColor: IgColors.textPrimary,
                  onChanged: _search,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Search usernames',
                    hintStyle: IgText.body(
                        size: 13.5, color: IgColors.textTertiary),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 340,
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: IgColors.textSecondary,
                        ),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'No users found',
                            style: IgText.body(
                                size: 13, color: IgColors.textTertiary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          itemCount: _results.length,
                          itemBuilder: (BuildContext context, int index) {
                            final StealthUser user = _results[index];
                            final bool already = _added.contains(user.id);
                            final bool busy = _loadingIds.contains(user.id);
                            return _PersonRow(
                              user: user,
                              trailing: already
                                  ? Text('Added',
                                      style: IgText.semibold(
                                          size: 12.5,
                                          color: IgColors.textTertiary))
                                  : GestureDetector(
                                      onTap: busy ? null : () => _add(user),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: IgColors.blue,
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                        child: busy
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 1.8,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : Text('Add',
                                                style: IgText.semibold(
                                                    size: 12.5,
                                                    color: Colors.white)),
                                      ),
                                    ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A registered user row (search results).
class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.user, required this.trailing});

  final StealthUser user;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: <Widget>[
          UserAvatar(name: user.username, url: user.avatar, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: IgText.semibold(size: 13)),
                if (user.displayName.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: IgText.body(
                          size: 12, color: IgColors.textTertiary)),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}