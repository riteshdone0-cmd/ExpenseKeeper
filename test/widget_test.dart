import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';

void main() {
  testWidgets('shows authentication screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FinanceApp());
    expect(find.text('AI Expense Intelligence'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
