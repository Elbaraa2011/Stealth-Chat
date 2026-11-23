/// The shape of a user in the stealth chat backend.
///
/// One row per sign-up, mirrored from `auth.users` into `public.users` by the
/// `handle_new_user` trigger. `username` is the public handle people type into
/// the DM search box to add each other; `displayName` is the friendly name
/// shown in the header.
class StealthUser {
  const StealthUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatar = '',
    required this.registeredAt,
  });

  final String id;
  final String username;
  final String displayName;
  final String avatar;
  final DateTime registeredAt;

  String get atHandle => '@$username';

  /// Alias used across the decoy UI widgets, which were written against
  /// [IgUser.handle] before the backend identity existed.
  String get handle => username;

  factory StealthUser.fromMap(Map<String, dynamic> map) {
    return StealthUser(
      id: map['id'] as String,
      username: (map['username'] as String?)?.trim() ?? '',
      displayName: (map['display_name'] as String?)?.trim() ??
          (map['username'] as String?) ??
          'User',
      avatar: (map['avatar'] as String?) ?? '',
      registeredAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '')?.toLocal() ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar': avatar,
    };
  }

  StealthUser copyWith({
    String? username,
    String? displayName,
    String? avatar,
  }) {
    return StealthUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      registeredAt: registeredAt,
    );
  }

  @override
  String toString() => 'StealthUser($id, @$username)';
}
