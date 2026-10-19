import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'لوحة تحكم أبو زهرة';
  static const String confirmHeadphoneUrl =
      'https://mosalah-maker.github.io/Confirm-your-reservation/';
  static const String confirmExamUrl = 'https://mosalah-maker.github.io/mo/';

  // Collections
  static const String colHeadphones = 'reservations';
  static const String colExams = 'exam_reservations';
  static const String colProducts = 'products';
  static const String colSections = 'exam_sections';
  static const String colSettings = 'settings';
  static const String docSiteSettings = 'siteSettings';

  // Headphone Statuses
  static const List<String> headphoneStatuses = [
    'قيد المراجعة',
    'تم التواصل',
    'تحت التجهيز',
    'تم الانتهاء من التجهيز',
    'تم تسليمه لمندوب الشحن',
    'تم الاستلام',
    'ملغي',
  ];

  static const Set<String> inProgressStatuses = {
    'تم التواصل',
    'تحت التجهيز',
    'تم الانتهاء من التجهيز',
    'تم تسليمه لمندوب الشحن',
  };

  // Exam Statuses
  static const Map<String, String> examStatuses = {
    'pending': 'في انتظار التأكيد',
    'confirmed': 'تم التأكيد',
    'cancelled': 'ملغي',
  };

  // Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color darkBg = Color(0xFF0F172A); // Slate 900
  static const Color darkCard = Color(0xFF1E293B); // Slate 800
  static const Color darkBorder = Color(0xFF334155); // Slate 700
}
