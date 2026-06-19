import 'package:flutter_test/flutter_test.dart';
import 'package:finance_control/app_widget.dart';

void main() {
  testWidgets('App should render login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Entrar'), findsOneWidget);
  });
}
