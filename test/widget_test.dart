import 'package:flutter_test/flutter_test.dart';
import 'package:delhivery/main.dart';

void main() {
  testWidgets('App renders splash branding test', (WidgetTester tester) async {
    await tester.pumpWidget(const DelhiveryApp());
    expect(find.text('DELHIVERY'), findsOneWidget);
    expect(find.text('UNIVERSAL TRACKER'), findsOneWidget);
  });
}
