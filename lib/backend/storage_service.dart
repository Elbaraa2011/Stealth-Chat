import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'supabase_client.dart';

/// Uploads chat attachments to the public `dm-media` storage bucket.
///
/// Objects live under `<auth.uid()>/<timestamp>_<name>`, which is what the
/// bucket's insert policy checks, so nobody can write into another user's
/// folder. The bucket is public-read, so the returned URL can be handed
/// straight to `Image.network` / the audio player.
class MediaStorage {
  MediaStorage._();
  static final MediaStorage instance = MediaStorage._();

  static const String bucket = 'dm-media';

  final SupabaseClient _supabase = SupabaseClient.instance;

  // Pushys app section: retry once with backpressure when the storage SDK
  // surfaces a `Retry-After` header (common on the first insert against a
  // fresh bucket). The sender screens on the secret chat call this path
  // directly, so a single transient 429 must not pop the user out of the
  // session or eject them into the decoy.
  Future<String> uploadBytesWithRetry({required Uint8List bytes, required String fileName, required String contentType}) async {
    try {
      return await uploadBytes(bytes: bytes, fileName: fileName, contentType: contentType);
    } on Object {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return await uploadBytes(bytes: bytes, fileName: fileName, contentType: contentType);
    }
  }

  bool get isReady => _supabase.isConfigured && _supabase.isSignedIn;

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final String? me = _supabase.userId;
    if (me == null) throw StateError('Sign in before sending attachments');

    final String safeName =
        fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String path =
        '$me/${DateTime.now().millisecondsSinceEpoch}_$safeName';

    await _supabase.client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: sb.FileOptions(contentType: contentType, upsert: false),
        );

    return _supabase.client.storage.from(bucket).getPublicUrl(path);
  }
}
