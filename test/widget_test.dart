import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_flutter/main.dart';

void main() {
  testWidgets('muestra la bienvenida al iniciar', (WidgetTester tester) async {
    await tester.pumpWidget(const TuAliadoApp());

    expect(find.text('MedFlow'), findsOneWidget);
    expect(find.text('COMENZAR'), findsOneWidget);
  });
}
