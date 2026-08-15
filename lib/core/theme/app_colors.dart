import 'package:flutter/material.dart';

class AppColors {
  // Main Monochrome Palette (Reference: Dark Flight Booking UI)
  static const Color background = Color(0xFF08080A);     // Ultra-dark near black
  static const Color surface = Color(0xFF121215);        // Dark surface container
  static const Color cardBg = Color(0xFF1A1A1E);         // Card surface
  static const Color cardBorder = Color(0xFF2C2C32);     // Subtle 1px card border

  // Premium Accent Colors (Crisp White & Off-White/Silver - No Green)
  static const Color accentPrimary = Color(0xFFFFFFFF);     // High contrast white for CTAs & highlights
  static const Color accentSecondary = Color(0xFFE5E5EA);   // Light silver highlight
  static const Color accentGlow = Color(0x22FFFFFF);        // Translucent white glow

  // Typography Hierarchy
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF545458);

  // Status Colors (Subtle & Understated)
  static const Color statusOrdered = Color(0xFF8E8E93);       // Silver grey
  static const Color statusShipped = Color(0xFFD1D1D6);       // Light silver
  static const Color statusOutForDelivery = Color(0xFFFFFFFF);// Pure white glow
  static const Color statusDelivered = Color(0xFF34C759);     // Soft muted green indicator only for status text if needed, or white
  static const Color statusDelayed = Color(0xFFFF453A);       // Soft muted red
  static const Color statusUnknown = Color(0xFF636366);       // Muted grey

  // Platform Branding subtle colors
  static const Color amazon = Color(0xFFF2A900);
  static const Color flipkart = Color(0xFF2874F0);
  static const Color myntra = Color(0xFFFF3F6C);
  static const Color ajio = Color(0xFFAAAAAA);
  static const Color purplle = Color(0xFFAB47BC);
  static const Color genericPlatform = Color(0xFF8E8E93);
}
