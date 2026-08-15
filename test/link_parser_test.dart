import 'package:flutter_test/flutter_test.dart';
import 'package:delhivery/services/link_parser.dart';

void main() {
  group('LinkParser Tests', () {
    test('Detects Delhivery URL and extracts tracking ID', () {
      final result = LinkParser.parse('https://www.delhivery.com/track/package/14392810482019');
      expect(result.courier, equals('Delhivery'));
      expect(result.trackingId, equals('14392810482019'));
      expect(result.isAutoTrackable, isTrue);
    });

    test('Detects India Post consignment code via regex', () {
      final result = LinkParser.parse('CP123456789IN');
      expect(result.courier, equals('India Post'));
      expect(result.trackingId, equals('CP123456789IN'));
      expect(result.isAutoTrackable, isTrue);
    });

    test('Detects DTDC tracking number via regex', () {
      final result = LinkParser.parse('Z98765432');
      expect(result.courier, equals('DTDC'));
      expect(result.trackingId, equals('Z98765432'));
      expect(result.isAutoTrackable, isTrue);
    });

    test('Detects Blue Dart 11-digit waybill via regex', () {
      final result = LinkParser.parse('12345678901');
      expect(result.courier, equals('Blue Dart'));
      expect(result.trackingId, equals('12345678901'));
      expect(result.isAutoTrackable, isTrue);
    });

    test('Falls back gracefully for unsupported platforms', () {
      final result = LinkParser.parse('https://www.amazon.in/progress-tracker/package/ref=xyz');
      expect(result.platform, equals('Amazon'));
      expect(result.isAutoTrackable, isFalse);
    });
  });
}
