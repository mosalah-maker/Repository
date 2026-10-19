import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  if (value is Map) {
    if (value['seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch((value['seconds'] as int) * 1000);
    }
    if (value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch((value['_seconds'] as int) * 1000);
    }
  }
  return null;
}

String formatDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('yyyy/MM/dd hh:mm a', 'ar').format(date);
}

String cleanPhoneForWhatsApp(String phone) {
  String cleaned = phone.replaceAll(RegExp(r'[\s\-+()]'), '');
  if (cleaned.startsWith('00')) cleaned = cleaned.substring(2);
  if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
  if (cleaned.startsWith('0')) cleaned = '20${cleaned.substring(1)}';
  if (!cleaned.startsWith('20')) cleaned = '20$cleaned';
  return cleaned;
}

enum PaymentState { approved, review, rejected, none }

class HeadphoneReservation {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String device;
  final String status;
  final String deliveryDate;
  final String question;
  final String? paymentProofUrl;
  final String? senderPhone;
  final bool paymentConfirmed;
  final bool paymentRejected;
  final DateTime? paymentSubmittedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  HeadphoneReservation({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.device,
    required this.status,
    required this.deliveryDate,
    required this.question,
    this.paymentProofUrl,
    this.senderPhone,
    required this.paymentConfirmed,
    required this.paymentRejected,
    this.paymentSubmittedAt,
    this.createdAt,
    required this.raw,
  });

  factory HeadphoneReservation.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return HeadphoneReservation(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      device: (data['device'] ?? '').toString(),
      status: (data['status'] ?? 'قيد المراجعة').toString(),
      deliveryDate: (data['delivery_date'] ?? '').toString(),
      question: (data['question'] ?? '').toString(),
      paymentProofUrl: data['payment_proof_url']?.toString(),
      senderPhone: data['sender_phone']?.toString(),
      paymentConfirmed: data['payment_confirmed'] == true,
      paymentRejected: data['payment_rejected'] == true,
      paymentSubmittedAt: parseDate(data['payment_submitted_at']),
      createdAt: parseDate(data['created_at']),
      raw: data,
    );
  }

  PaymentState get paymentState {
    if (paymentConfirmed) return PaymentState.approved;
    if (paymentProofUrl != null &&
        paymentProofUrl!.isNotEmpty &&
        !paymentRejected) {
      return PaymentState.review;
    }
    if (paymentRejected) return PaymentState.rejected;
    return PaymentState.none;
  }

  bool get needsPaymentReview =>
      paymentProofUrl != null &&
      paymentProofUrl!.isNotEmpty &&
      !paymentConfirmed &&
      !paymentRejected;

  String get paymentLabel {
    switch (paymentState) {
      case PaymentState.approved:
        return 'الدفع معتمد';
      case PaymentState.review:
        return 'بانتظار مراجعة الدفع';
      case PaymentState.rejected:
        return 'الدفع مرفوض';
      case PaymentState.none:
        return 'لا يوجد إثبات';
    }
  }
}

class ExamReservation {
  final String id;
  final String name;
  final String phone;
  final String section;
  final String status;
  final String? seatNumber;
  final String? examLink;
  final String? paymentProofUrl;
  final String? senderPhone;
  final bool paymentConfirmed;
  final bool paymentRejected;
  final DateTime? paymentSubmittedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  ExamReservation({
    required this.id,
    required this.name,
    required this.phone,
    required this.section,
    required this.status,
    this.seatNumber,
    this.examLink,
    this.paymentProofUrl,
    this.senderPhone,
    required this.paymentConfirmed,
    required this.paymentRejected,
    this.paymentSubmittedAt,
    this.createdAt,
    required this.raw,
  });

  factory ExamReservation.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ExamReservation(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      seatNumber: data['seat_number']?.toString(),
      examLink: data['exam_link']?.toString(),
      paymentProofUrl: data['payment_proof_url']?.toString(),
      senderPhone: data['sender_phone']?.toString(),
      paymentConfirmed: data['payment_confirmed'] == true,
      paymentRejected: data['payment_rejected'] == true,
      paymentSubmittedAt: parseDate(data['payment_submitted_at']),
      createdAt: parseDate(data['created_at']),
      raw: data,
    );
  }

  PaymentState get paymentState {
    if (paymentConfirmed) return PaymentState.approved;
    if (paymentProofUrl != null &&
        paymentProofUrl!.isNotEmpty &&
        !paymentRejected) {
      return PaymentState.review;
    }
    if (paymentRejected) return PaymentState.rejected;
    return PaymentState.none;
  }

  bool get needsPaymentReview {
    if (paymentProofUrl == null || paymentProofUrl!.isEmpty) return false;
    if (paymentConfirmed || paymentRejected) return false;
    if (status == 'cancelled' || status == 'confirmed') return false;
    return true;
  }

  String get statusLabel => AppConstants.examStatuses[status] ?? status;
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final double? discountPercent;
  final String? image;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.discountPercent,
    this.image,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Product(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      originalPrice: (data['original_price'] is num)
          ? (data['original_price'] as num).toDouble()
          : null,
      discountPercent: (data['discount_percent'] is num)
          ? (data['discount_percent'] as num).toDouble()
          : null,
      image: data['image']?.toString(),
    );
  }
}

class Section {
  final String id;
  final String name;
  final String examLink;
  final int maxStudents;

  Section({
    required this.id,
    required this.name,
    required this.examLink,
    required this.maxStudents,
  });

  factory Section.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Section(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      examLink: (data['exam_link'] ?? '').toString(),
      maxStudents: (data['max_students'] is num)
          ? (data['max_students'] as num).toInt()
          : 0,
    );
  }
}

class SiteSettings {
  final String whatsapp;
  final String cashNumber;
  final String cashAmount;
  final String examAmount;
  final String productDiscount;

  SiteSettings({
    this.whatsapp = '',
    this.cashNumber = '',
    this.cashAmount = '',
    this.examAmount = '',
    this.productDiscount = '0',
  });

  factory SiteSettings.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return SiteSettings(
      whatsapp: (data['whatsapp'] ?? '').toString(),
      cashNumber: (data['cashNumber'] ?? '').toString(),
      cashAmount: (data['cashAmount'] ?? '').toString(),
      examAmount: (data['examAmount'] ?? '').toString(),
      productDiscount: (data['productDiscount'] ?? '0').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'whatsapp': whatsapp.trim(),
        'cashNumber': cashNumber.trim(),
        'cashAmount': cashAmount.trim(),
        'examAmount': examAmount.trim(),
        'productDiscount': productDiscount.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}

class ActivityItem {
  final String key;
  final String kind; // 'headphones' | 'exams'
  final String id;
  final DateTime at;
  final String title;
  final String detail;

  ActivityItem({
    required this.key,
    required this.kind,
    required this.id,
    required this.at,
    required this.title,
    required this.detail,
  });
}
