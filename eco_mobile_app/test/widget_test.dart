import 'package:flutter_test/flutter_test.dart';
import 'package:eco_mobile_app/main.dart';

void main() {
  testWidgets('EcoProjectApp renders main navigation and home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EcoProjectApp());
    await tester.pump();

    expect(find.text("EcoProject Talaba"), findsOneWidget);
    expect(find.text("Keshbek Balansingiz"), findsOneWidget);
    expect(find.text("Bosh sahifa"), findsOneWidget);
  });
}
