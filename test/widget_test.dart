import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xox_madvise/view/games/game_scaffold.dart';

void main() {
  testWidgets('game scaffold renders title and child content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TestableGameScaffold());
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Test Game'), findsOneWidget);
    expect(find.text('Test subtitle'), findsOneWidget);
    expect(find.text('Body content'), findsOneWidget);
  });
}

class TestableGameScaffold extends StatelessWidget {
  const TestableGameScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: GameScaffold(
        title: 'Test Game',
        subtitle: 'Test subtitle',
        accent: [Color(0xff000000), Color(0xff222222)],
        child: Text('Body content'),
      ),
    );
  }
}
