import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ayurvedic_app/screens/marketplace/product_detail_page.dart';

void main() {
  testWidgets('Product detail page shows product name and details', (WidgetTester tester) async {
    final product = {
      'title': 'Herbal Teas',
      'category': 'Herbal Teas',
      'price': 200.0,
      'description': 'Natural wellness tea blend',
      'stock': 12,
      'imageUrls': ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(product: product),
      ),
    );

    expect(find.text('Herbal Teas'), findsWidgets);
    expect(find.text('Natural wellness tea blend'), findsOneWidget);
    expect(find.text('LKR 200.0'), findsOneWidget);
  });
}
