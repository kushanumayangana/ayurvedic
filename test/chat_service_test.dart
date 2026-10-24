import 'package:flutter_test/flutter_test.dart';
import 'package:ayurvedic_app/services/chat_service.dart';

void main() {
  group('ChatService', () {
    test('uses the same conversation id regardless of participant order', () {
      expect(
        ChatService.conversationIdFor('customer-1', 'seller-1'),
        ChatService.conversationIdFor('seller-1', 'customer-1'),
      );
    });

    test('creates separate conversations for different participant pairs', () {
      expect(
        ChatService.conversationIdFor('customer-1', 'seller-1'),
        isNot(ChatService.conversationIdFor('customer-1', 'doctor-1')),
      );
    });
  });
}
