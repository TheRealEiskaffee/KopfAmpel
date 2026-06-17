import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopfampel/app/app.dart';

void main() {
  testWidgets('app boots and renders calendar tab', (tester) async {
    await tester.pumpWidget(ProviderScope(child: KopfAmpelApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
