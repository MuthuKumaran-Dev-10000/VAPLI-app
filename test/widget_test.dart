import 'package:flutter_test/flutter_test.dart';
import 'package:vapli/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LubeMonitorApp());
    expect(find.byType(LubeMonitorApp), findsOneWidget);
  });
}
