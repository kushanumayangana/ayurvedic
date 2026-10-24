import 'package:flutter_test/flutter_test.dart';
import 'package:ayurvedic_app/screens/marketplace/product_detail_page.dart';

void main() {
  test('Vendor name resolver falls back when metadata is missing', () {
    expect(
      ProductDetailPage.resolveVendorName(
        profile: const {},
        product: const {},
        isSeller: true,
      ),
      'Marketplace seller',
    );

    expect(
      ProductDetailPage.resolveVendorName(
        profile: const {},
        product: const {},
        isSeller: false,
      ),
      'Ayurvedic doctor',
    );
  });
}
