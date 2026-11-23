import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Asks for the device permissions the chat needs as soon as the user signs in,
/// so the camera and voice-note prompts do not interrupt a conversation later.
class PermissionService {
  PermissionService._();

  static Future<void> requestChatPermissions() async {
    final List<Permission> wanted = <Permission>[
      Permission.camera,
      Permission.microphone,
      // `photos` maps to READ_MEDIA_IMAGES on Android 13+ and to the photo
      // library on iOS; `storage` covers Android 12 and older, where the
      // granular media permissions do not exist.
      Permission.photos,
      if (!Platform.isIOS) Permission.storage,
    ];
    try {
      await wanted.request();
    } on Object {
      // A refusal or an unsupported platform must never block sign-in; the
      // individual features surface their own message if access is missing.
    }
  }
}
