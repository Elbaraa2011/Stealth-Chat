import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:stealth_chat/screens/main_tab_scaffold.dart';
import 'package:stealth_chat/screens/story_viewer_screen.dart';
import 'package:stealth_chat/state/app_state.dart';
import 'package:stealth_chat/theme/ig_theme.dart';
import 'package:stealth_chat/widgets/primitives.dart';

/// Renders every surface at a real phone size. A RenderFlex overflow or any
/// other layout exception fails the pump, so this is the layout regression
/// net that a screenshot would otherwise provide.
/// The signed-in shell. The splash hands off to this once a session
/// exists, so tests mount it directly and skip the boot sequence.
Widget shell() => MaterialApp(
      theme: IgTheme.dark(),
      home: const MainTabScaffold(),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // The reels tab and the story viewer run looping animations, so these
  // tests pump fixed frames instead of waiting for the tree to settle.
  Future<void> settleFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('every tab lays out on a 390x844 phone',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell());
    await settleFrames(tester);
    expect(tester.takeException(), isNull);

    // Home -> Explore -> Reels -> Activity -> Profile -> Home.
    for (final int tab in <int>[1, 2, 3, 4, 0]) {
      AppState.instance.selectTab(tab);
      await settleFrames(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: 'tab $tab produced a layout exception',
      );
    }
  });

  testWidgets('story viewer opens, advances and closes on a phone',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell());
    await settleFrames(tester);

    await tester.tap(find.text('realmadrid').first);
    await settleFrames(tester);
    expect(find.byType(StoryViewerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tapAt(const Offset(300, 400)); // right-hand tap zone
    await settleFrames(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byType(StoryViewerScreen), findsNothing);
  });

  testWidgets('opened story ring turns grey in the tray',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell());
    await settleFrames(tester);

    // `cnn` is not opened by any other test, so its ring starts unviewed.
    expect(AppState.instance.isStoryViewed('cnn'), isFalse);

    await tester.tap(find.text('cnn').first);
    await settleFrames(tester);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(AppState.instance.isStoryViewed('cnn'), isTrue);

    // The tile's own ring must be the one that repainted grey.
    final Finder cnnTile = find
        .ancestor(
          of: find.text('cnn').first,
          matching: find.byType(GestureDetector),
        )
        .first;
    expect(
      find.descendant(
        of: cnnTile,
        matching:
            find.byWidgetPredicate((Widget w) => w is StoryRing && w.viewed),
      ),
      findsOneWidget,
      reason: 'the tray ring must repaint grey after the story is opened',
    );
  });

  testWidgets('messages tab lays out and the hidden session opens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(shell());
    await settleFrames(tester);

    // Messages lives on tab 3 of the bottom bar and shows the decoy inbox.
    AppState.instance.selectTab(3);
    await settleFrames(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Messages'), findsOneWidget);

    // Typing the hidden word into the inbox search reaches the real session.
    await tester.enterText(find.byType(TextField), '//open');
    await settleFrames(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Sign in to open the session'), findsOneWidget);
  });
}
