import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:stealth_chat/backend/dm_message.dart';
import 'package:stealth_chat/main.dart';
import 'package:stealth_chat/screens/main_tab_scaffold.dart';
import 'package:stealth_chat/screens/dm_screen.dart';
import 'package:stealth_chat/screens/secret_chat_screen.dart';
import 'package:stealth_chat/screens/stealth_session_screen.dart';
import 'package:stealth_chat/state/app_state.dart';
import 'package:stealth_chat/theme/ig_theme.dart';

/// The signed-in shell. The splash hands off to this once a session
/// exists, so tests mount it directly and skip the boot sequence.
Widget shell() => MaterialApp(
      theme: IgTheme.dark(),
      home: const MainTabScaffold(),
    );

void main() {
  setUpAll(() {
    // Never reach for the network inside the test harness.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Messages lives on tab 3 of the bottom bar.
  Future<void> openMessages(WidgetTester tester) async {
    AppState.instance.selectTab(3);
    await tester.pumpAndSettle();
    expect(find.byType(DmScreen), findsOneWidget);
  }

  testWidgets('decoy feed renders', (WidgetTester tester) async {
    await tester.pumpWidget(shell());
    await tester.pump();

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Your story'), findsOneWidget);
    expect(find.text('brfootball'), findsWidgets);
  });

  testWidgets('messages tab shows the decoy inbox',
      (WidgetTester tester) async {
    await tester.pumpWidget(shell());
    await tester.pump();

    await openMessages(tester);

    // The visible inbox is the seeded cover story, never the real threads.
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('@wisam.k123 · 2m'), findsOneWidget);
    expect(find.text('Add friends to start chatting'), findsNothing);
    expect(find.byType(StealthSessionScreen), findsNothing);
  });

  testWidgets('typing //open in the inbox search opens the real session',
      (WidgetTester tester) async {
    await tester.pumpWidget(shell());
    await tester.pump();

    await openMessages(tester);
    await tester.enterText(find.byType(TextField), '//open');
    await tester.pumpAndSettle();

    expect(find.byType(StealthSessionScreen), findsOneWidget);
    // No signed-in backend in the harness, so the session asks for a session
    // instead of listing fixtures.
    expect(find.text('Sign in to open the session'), findsOneWidget);
    expect(find.text('Add friends to start chatting'), findsNothing);
    expect(find.byType(SecretChatScreen), findsNothing);
  });

  testWidgets('backgrounding the app returns to the feed',
      (WidgetTester tester) async {
    // The lifecycle observer lives on the app root, so this one needs the real
    // shell widget rather than the signed-in helper.
    await tester.pumpWidget(const StealthChatApp());
    await tester.pump();

    AppState.instance.selectTab(3);
    await tester.pumpAndSettle();

    // Walk the legal transition path the OS uses when the app is minimised.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(AppState.instance.tabIndex, 0);

    // Let the splash's boot timer drain so the test ends with no pending work.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('voice-note bubble builds without crashing',
      (WidgetTester tester) async {
    // Regression: building a voice bubble before playback started used to
    // force-unwrap a null VideoPlayerController and take the whole list down
    // to a red error box.
    final DmMessage voice = DmMessage(
      id: 'voice-1',
      fromUsername: 'barbarinio2011',
      toUsername: 'me',
      body: '',
      sentAt: DateTime(2026, 11, 12, 10, 28),
      mediaUrl: 'https://example.com/voice.m4a',
      mediaType: 'voice',
      durationMs: 2000,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: IgTheme.dark(),
        home: Scaffold(
          backgroundColor: IgColors.bg,
          body: ChatBubble(
            message: voice,
            mine: false,
            time: '10:28 AM',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // The fallback length comes from durationMs, not the missing controller.
    expect(find.text('0:02'), findsOneWidget);
  });

  testWidgets(
      'an open picker keeps the session while real backgrounding resets it',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StealthChatApp());
    await tester.pump();

    AppState.instance.selectTab(3);
    await tester.pump();

    // Opening our own camera/gallery holds the session. The async body runs
    // synchronously up to its first await, so the guard is armed immediately.
    final Completer<void> picker = Completer<void>();
    final Future<void> held =
        AppState.instance.keepSessionWhile<void>(() => picker.future);
    expect(AppState.instance.panicSuspended, isTrue);

    // Android reports these while the picker surface is in front.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(AppState.instance.tabIndex, 3,
        reason: 'a picker must not drop the covert session to the decoy');
    expect(AppState.instance.panicSuspended, isTrue);

    // Picker returns; the app is foregrounded again and the guard releases.
    picker.complete();
    await held;
    expect(AppState.instance.panicSuspended, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // With no guard, a genuine trip to the background still resets.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(AppState.instance.tabIndex, 0);

    // Drain the splash boot timer triggered by the reset.
    await tester.pump(const Duration(seconds: 1));
  });
}
