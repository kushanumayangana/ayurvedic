import 'package:flutter_test/flutter_test.dart';
import 'package:ayurvedic_app/services/order_identity_service.dart';

void main() {
  group('OrderIdentityService', () {
    test(
      'prefers seller profile before patient record when both share the same buyerId',
      () {
        final order = {
          'buyerId': 'user-1',
          'buyerRole': 'seller',
          'buyerName': 'Umayan',
          'buyerImage': 'doctor-photo',
        };

        final profileMap = {
          'sellers': {
            'user-1': {
              'fullName': 'Krish',
              'profileImage': 'seller-photo',
              'email': 'krish@example.com',
              'phone': '0771234567',
            },
          },
          'patients': {
            'user-1': {
              'fullName': 'Umayan',
              'profileImage': 'doctor-photo',
              'email': 'umayan@example.com',
              'phone': '0770000000',
            },
          },
        };

        final resolved = OrderIdentityService.resolvePreferredProfile(
          order,
          profileMap,
        );

        expect(resolved['buyerName'], 'Krish');
        expect(resolved['buyerImage'], 'seller-photo');
        expect(resolved['buyerRole'], 'seller');
        expect(resolved['buyerEmail'], 'krish@example.com');
        expect(resolved['buyerProfile']['fullName'], 'Krish');
      },
    );

    test(
      'does not use the product doctor profile as a seller buyer profile',
      () {
        final order = {
          'buyerId': 'seller-1',
          'buyerRole': 'seller',
          'buyerName': 'Seller',
          'buyerImage': 'seller-photo',
          'doctorId': 'doctor-1',
          'ownerType': 'doctor',
        };
        final profileMap = {
          'doctors': {
            'doctor-1': {'fullName': 'Doctor', 'profileImage': 'doctor-photo'},
          },
        };

        final resolved = OrderIdentityService.resolvePreferredProfile(
          order,
          profileMap,
        );

        expect(resolved['buyerName'], 'Seller');
        expect(resolved['buyerImage'], 'seller-photo');
        expect(resolved['buyerRole'], 'seller');
      },
    );
  });
}
