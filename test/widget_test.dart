import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_final_dam/main.dart';

void main() {
  testWidgets('Auth screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SpotBookingApp());
    expect(find.text('ESPACIOS'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsWidgets);
  });
}
