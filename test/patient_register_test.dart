import 'package:ayurvedic_app/screens/patien/register_patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPatientRegister(WidgetTester tester) {
    return tester.pumpWidget(const MaterialApp(home: RegisterPatient()));
  }

  testWidgets('registration requires a name, valid email, and password', (
    tester,
  ) async {
    await pumpPatientRegister(tester);

    final submitButton = find.text('Create patient account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('registration rejects weak passwords', (tester) async {
    await pumpPatientRegister(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ravi Patient');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ravi@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'abcdefgh');
    final submitButton = find.text('Create patient account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Include at least one letter and one number'),
      findsOneWidget,
    );
  });

  testWidgets('registration rejects malformed email addresses', (tester) async {
    await pumpPatientRegister(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ravi Patient');
    await tester.enterText(find.byType(TextFormField).at(1), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');
    final submitButton = find.text('Create patient account');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('login requires email and password but not registration name', (
    tester,
  ) async {
    await pumpPatientRegister(tester);

    final toggle = find.text('Already have an account? Sign in');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final submitButton = find.text('Sign in');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Enter your name'), findsNothing);
  });
}
