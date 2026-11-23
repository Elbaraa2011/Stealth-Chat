import 'package:flutter/foundation.dart';

import '../backend/models.dart';
import '../data/fixtures.dart' as fixtures;

StealthUser fakeAppMe() {
  // Local-only fallback when Supabase isn't configured yet — keeps the app
  // open using the hard-coded decoy identity.
  return StealthUser(
    id: 'local',
    username: fixtures.me.handle,
    displayName: fixtures.me.name,
    avatar: fixtures.me.avatar,
    registeredAt: DateTime.now(),
  );
}

/// All interactive state lives here, in RAM only. Nothing is written to disk,
/// so killing the process erases likes, follows, comments and every message.
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  int _tabIndex = 0;
  int get tabIndex => _tabIndex;

  StealthUser _me = fakeAppMe();

  StealthUser get me => _me;

  void setMe(StealthUser user) {
    if (_me.id == user.id) return;
    _me = user;
    notifyListeners();
  }

  bool get hasSession => _me != fakeAppMe();

  final Set<String> _viewedStories = <String>{};
  final Set<String> _likedPosts = <String>{};
  final Set<String> _savedReels = <String>{};
  final Set<String> _following = <String>{};
  final Map<String, List<IgComment>> _appendedComments =
      <String, List<IgComment>>{};

  void selectTab(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    notifyListeners();
  }

  // ------------------------------------------------------------- stories

  bool isStoryViewed(String handle) => _viewedStories.contains(handle);

  void markStoryViewed(String handle) {
    if (_viewedStories.add(handle)) notifyListeners();
  }

  // --------------------------------------------------------------- likes

  bool isLiked(String postId) => _likedPosts.contains(postId);

  void like(String postId) {
    if (_likedPosts.add(postId)) notifyListeners();
  }

  void toggleLike(String postId) {
    if (!_likedPosts.remove(postId)) _likedPosts.add(postId);
    notifyListeners();
  }

  int likeDelta(String postId) => _likedPosts.contains(postId) ? 1 : 0;

  // --------------------------------------------------------------- saves

  bool isReelSaved(String reelId) => _savedReels.contains(reelId);

  void toggleReelSaved(String reelId) {
    if (!_savedReels.remove(reelId)) _savedReels.add(reelId);
    notifyListeners();
  }

  // ------------------------------------------------------------- follows

  bool isFollowing(String handle) => _following.contains(handle);

  void toggleFollow(String handle) {
    if (!_following.remove(handle)) _following.add(handle);
    notifyListeners();
  }

  // ------------------------------------------------------------ comments

  List<IgComment> commentsFor(String postId, List<IgComment> seed) =>
      <IgComment>[...seed, ...?_appendedComments[postId]];

  void addComment(String postId, IgComment comment) {
    _appendedComments.putIfAbsent(postId, () => <IgComment>[]).add(comment);
    notifyListeners();
  }

  // ------------------------------------------------------- panic guard

  int _panicSuspensions = 0;

  /// True while a camera, gallery or recorder surface we opened is on screen.
  ///
  /// Android reports `inactive`/`paused` for those too, and the decoy reset
  /// must not treat them as the user leaving the app.
  bool get panicSuspended => _panicSuspensions > 0;

  Future<T> keepSessionWhile<T>(Future<T> Function() action) async {
    _panicSuspensions++;
    try {
      return await action();
    } finally {
      _panicSuspensions--;
    }
  }
}

/// A comment on a post or story.
class IgComment {
  IgComment(this.text, this.user, {this.age = '', this.likes = 0});
  final String text;
  final fixtures.IgUser user;
  final String age;
  final int likes;
}