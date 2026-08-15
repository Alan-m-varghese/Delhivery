class ParsedLinkResult {
  final String trackingId;
  final String courier;
  final String platform;
  final String trackingUrl;
  final bool isAutoTrackable;

  ParsedLinkResult({
    required this.trackingId,
    required this.courier,
    required this.platform,
    required this.trackingUrl,
    required this.isAutoTrackable,
  });
}

class LinkParser {
  // Known Supported Auto-tracked Couriers
  static const List<String> supportedCouriers = [
    'Delhivery',
    'India Post',
    'DTDC',
    'Ecom Express',
    'Blue Dart',
  ];

  // Known Platforms
  static const List<String> knownPlatforms = [
    'Amazon',
    'Flipkart',
    'Myntra',
    'Ajio',
    'Purplle',
    'Meesho',
    'Nykaa',
    'Other',
  ];

  static ParsedLinkResult parse(String input) {
    final rawText = input.trim();
    if (rawText.isEmpty) {
      return ParsedLinkResult(
        trackingId: '',
        courier: 'Unknown',
        platform: 'Other',
        trackingUrl: '',
        isAutoTrackable: false,
      );
    }

    String extractedId = rawText;
    String detectedCourier = 'Unknown';
    String detectedPlatform = 'Other';
    String trackingUrl = rawText.startsWith('http') ? rawText : '';

    // Check URL patterns
    final lower = rawText.toLowerCase();

    // Platforms detection
    if (lower.contains('amazon.in') || lower.contains('amazon.com')) {
      detectedPlatform = 'Amazon';
    } else if (lower.contains('flipkart.com')) {
      detectedPlatform = 'Flipkart';
    } else if (lower.contains('myntra.com')) {
      detectedPlatform = 'Myntra';
    } else if (lower.contains('ajio.com')) {
      detectedPlatform = 'Ajio';
    } else if (lower.contains('purplle.com')) {
      detectedPlatform = 'Purplle';
    } else if (lower.contains('meesho.com')) {
      detectedPlatform = 'Meesho';
    } else if (lower.contains('nykaa.com')) {
      detectedPlatform = 'Nykaa';
    }

    // Courier Detection from URL or Regex
    if (lower.contains('delhivery.com')) {
      detectedCourier = 'Delhivery';
      final match = RegExp(r'track(?:ing)?/package/([A-Za-z0-9]+)').firstMatch(rawText);
      if (match != null) {
        extractedId = match.group(1)!;
      }
    } else if (lower.contains('indiapost.gov.in')) {
      detectedCourier = 'India Post';
      final match = RegExp(r'([A-Z]{2}[0-9]{9}IN)', caseSensitive: false).firstMatch(rawText);
      if (match != null) {
        extractedId = match.group(1)!.toUpperCase();
      }
    } else if (lower.contains('dtdc')) {
      detectedCourier = 'DTDC';
      final match = RegExp(r'strTrkNo=([A-Za-z0-9]+)').firstMatch(rawText);
      if (match != null) {
        extractedId = match.group(1)!;
      }
    } else if (lower.contains('ecomexpress.in')) {
      detectedCourier = 'Ecom Express';
      final match = RegExp(r'awb_number=([0-9]+)').firstMatch(rawText);
      if (match != null) {
        extractedId = match.group(1)!;
      }
    } else if (lower.contains('bluedart.com')) {
      detectedCourier = 'Blue Dart';
      final match = RegExp(r'waybill=([0-9]+)').firstMatch(rawText);
      if (match != null) {
        extractedId = match.group(1)!;
      }
    }

    // If Courier not detected via URL domain, try matching AWB regex pattern on raw string
    if (detectedCourier == 'Unknown') {
      final cleanText = rawText.replaceAll(RegExp(r'\s+'), '');

      // India Post: standard 13 char code (e.g. CP123456789IN or EM123456789IN)
      final indiaPostRegex = RegExp(r'^[A-Za-z]{2}\d{9}IN$', caseSensitive: false);
      if (indiaPostRegex.hasMatch(cleanText)) {
        detectedCourier = 'India Post';
        extractedId = cleanText.toUpperCase();
      }

      // Delhivery: 12 to 14 digit numeric starting with 1, 2, 6, etc., or starting with 'DEL'
      else if (RegExp(r'^(DEL\d+|\d{12,14})$', caseSensitive: false).hasMatch(cleanText)) {
        detectedCourier = 'Delhivery';
        extractedId = cleanText;
      }

      // DTDC: typically letter + 8 digits (e.g., Z12345678, D12345678, B12345678)
      else if (RegExp(r'^[A-Za-z]\d{8}$').hasMatch(cleanText)) {
        detectedCourier = 'DTDC';
        extractedId = cleanText.toUpperCase();
      }

      // Blue Dart: 11 digit waybill number
      else if (RegExp(r'^\d{11}$').hasMatch(cleanText)) {
        detectedCourier = 'Blue Dart';
        extractedId = cleanText;
      }

      // Ecom Express: 9 or 10 digit number starting with 1, 8 or 9
      else if (RegExp(r'^[189]\d{8,9}$').hasMatch(cleanText)) {
        detectedCourier = 'Ecom Express';
        extractedId = cleanText;
      }
    }

    // Construct default tracking URL if not provided as URL
    if (trackingUrl.isEmpty && extractedId.isNotEmpty) {
      trackingUrl = getTrackingUrlForCourier(detectedCourier, extractedId);
    }

    final isSupported = supportedCouriers.contains(detectedCourier);

    return ParsedLinkResult(
      trackingId: extractedId,
      courier: detectedCourier,
      platform: detectedPlatform,
      trackingUrl: trackingUrl,
      isAutoTrackable: isSupported,
    );
  }

  static String getTrackingUrlForCourier(String courier, String trackingId) {
    switch (courier) {
      case 'Delhivery':
        return 'https://www.delhivery.com/track/package/$trackingId';
      case 'India Post':
        return 'https://www.indiapost.gov.in/_layouts/15/dop.portal.tracking/trackconsignment.aspx';
      case 'DTDC':
        return 'https://www.dtdc.in/tracking/shipment-tracking.asp?strTrkNo=$trackingId';
      case 'Ecom Express':
        return 'https://ecomexpress.in/tracking/?awb_number=$trackingId';
      case 'Blue Dart':
        return 'https://www.bluedart.com/tracking?waybill=$trackingId';
      default:
        return 'https://www.google.com/search?q=track+$trackingId+$courier';
    }
  }
}
