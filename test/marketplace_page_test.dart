import 'package:ayurvedic_app/screens/marketplace/marketplace_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketplacePage.matchesProduct', () {
    const product = {
      'title': 'Brahmi Massage Oil',
      'category': 'Oils',
      'description': 'Herbal oil for daily massage',
      'ownerName': 'Ayurveda Store',
    };

    test('matches products by category without case sensitivity', () {
      expect(
        MarketplacePage.matchesProduct(
          product: product,
          category: 'oils',
          query: '',
        ),
        isTrue,
      );
      expect(
        MarketplacePage.matchesProduct(
          product: product,
          category: 'Balms',
          query: '',
        ),
        isFalse,
      );
    });

    test('matches singular balm and oil category labels', () {
      expect(
        MarketplacePage.matchesProduct(
          product: const {'category': 'Balm'},
          category: 'Balms',
          query: '',
        ),
        isTrue,
      );
      expect(
        MarketplacePage.matchesProduct(
          product: const {'category': 'Oil'},
          category: 'Oils',
          query: '',
        ),
        isTrue,
      );
    });

    test('searches title, category, description, and vendor', () {
      expect(
        MarketplacePage.matchesProduct(
          product: product,
          category: 'All',
          query: 'massage',
        ),
        isTrue,
      );
      expect(
        MarketplacePage.matchesProduct(
          product: product,
          category: 'All',
          query: 'store',
        ),
        isTrue,
      );
      expect(
        MarketplacePage.matchesProduct(
          product: product,
          category: 'All',
          query: 'tablet',
        ),
        isFalse,
      );
    });
  });
}
