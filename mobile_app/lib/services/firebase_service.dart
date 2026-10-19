import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../models/models.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Streams
  Stream<List<HeadphoneReservation>> streamHeadphones() {
    return _db.collection(AppConstants.colHeadphones).snapshots().map((snap) {
      final list =
          snap.docs.map((doc) => HeadphoneReservation.fromFirestore(doc)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Stream<List<ExamReservation>> streamExams() {
    return _db.collection(AppConstants.colExams).snapshots().map((snap) {
      final list =
          snap.docs.map((doc) => ExamReservation.fromFirestore(doc)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Stream<List<Product>> streamProducts() {
    return _db.collection(AppConstants.colProducts).snapshots().map((snap) {
      return snap.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Section>> streamSections() {
    return _db.collection(AppConstants.colSections).snapshots().map((snap) {
      return snap.docs.map((doc) => Section.fromFirestore(doc)).toList();
    });
  }

  Stream<SiteSettings> streamSettings() {
    return _db
        .collection(AppConstants.colSettings)
        .doc(AppConstants.docSiteSettings)
        .snapshots()
        .map((doc) =>
            doc.exists ? SiteSettings.fromFirestore(doc) : SiteSettings());
  }

  // Headphone Actions
  Future<void> updateHeadphoneStatus(String id, String status) async {
    await _db
        .collection(AppConstants.colHeadphones)
        .doc(id)
        .update({'status': status, 'updated_at': FieldValue.serverTimestamp()});
  }

  Future<void> reviewHeadphonePayment(
      String id, bool approved, String? currentProof) async {
    final Map<String, dynamic> data = {
      'payment_confirmed': approved,
      'payment_rejected': !approved,
      'payment_reviewed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (!approved && currentProof != null) {
      data['payment_rejected_proof_url'] = currentProof;
      data['payment_proof_url'] = FieldValue.delete();
    }
    await _db.collection(AppConstants.colHeadphones).doc(id).update(data);
  }

  Future<void> deleteHeadphone(String id) async {
    await _db.collection(AppConstants.colHeadphones).doc(id).delete();
  }

  // Exam Actions
  Future<void> updateExamStatus(String id, String status,
      {String? seatNumber, String? examLink}) async {
    final Map<String, dynamic> data = {
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (seatNumber != null) data['seat_number'] = seatNumber;
    if (examLink != null) data['exam_link'] = examLink;
    await _db.collection(AppConstants.colExams).doc(id).update(data);
  }

  Future<void> reviewExamPayment(
      String id, bool approved, String? currentProof) async {
    final Map<String, dynamic> data = {
      'payment_confirmed': approved,
      'payment_rejected': !approved,
      'payment_reviewed_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (!approved && currentProof != null) {
      data['payment_rejected_proof_url'] = currentProof;
      data['payment_proof_url'] = FieldValue.delete();
    }
    await _db.collection(AppConstants.colExams).doc(id).update(data);
  }

  Future<void> deleteExam(String id) async {
    await _db.collection(AppConstants.colExams).doc(id).delete();
  }

  // Product Actions
  Future<void> saveProduct({
    String? id,
    required String name,
    required String description,
    required double price,
    double? originalPrice,
    double? discountPercent,
    String? image,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (originalPrice != null) data['original_price'] = originalPrice;
    if (discountPercent != null && discountPercent > 0) {
      data['discount_percent'] = discountPercent;
    }
    if (image != null && image.isNotEmpty) data['image'] = image;

    if (id != null && id.isNotEmpty) {
      await _db.collection(AppConstants.colProducts).doc(id).update(data);
    } else {
      data['created_at'] = FieldValue.serverTimestamp();
      await _db.collection(AppConstants.colProducts).add(data);
    }
  }

  Future<void> applyDiscountToAllProducts(
      List<Product> products, double percent) async {
    final batch = _db.batch();
    for (final prod in products) {
      final basePrice = prod.originalPrice ?? prod.price;
      final salePrice = basePrice - (basePrice * (percent / 100));
      batch.update(_db.collection(AppConstants.colProducts).doc(prod.id), {
        'original_price': basePrice,
        'price': double.parse(salePrice.toStringAsFixed(2)),
        'discount_percent': percent,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    batch.set(
      _db
          .collection(AppConstants.colSettings)
          .doc(AppConstants.docSiteSettings),
      {
        'productDiscount': percent.toString(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> clearProductDiscount(List<Product> products) async {
    final batch = _db.batch();
    for (final prod in products) {
      if (prod.originalPrice != null) {
        batch.update(_db.collection(AppConstants.colProducts).doc(prod.id), {
          'price': prod.originalPrice,
          'original_price': FieldValue.delete(),
          'discount_percent': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.set(
      _db
          .collection(AppConstants.colSettings)
          .doc(AppConstants.docSiteSettings),
      {
        'productDiscount': '0',
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection(AppConstants.colProducts).doc(id).delete();
  }

  // Section Actions
  Future<void> saveSection({
    String? id,
    required String name,
    required String examLink,
    required int maxStudents,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'exam_link': examLink.trim(),
      'max_students': maxStudents,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (id != null && id.isNotEmpty) {
      await _db.collection(AppConstants.colSections).doc(id).update(data);
    } else {
      data['created_at'] = FieldValue.serverTimestamp();
      await _db.collection(AppConstants.colSections).add(data);
    }
  }

  Future<void> deleteSection(String id) async {
    await _db.collection(AppConstants.colSections).doc(id).delete();
  }

  // Settings Actions
  Future<void> saveSettings(SiteSettings settings) async {
    await _db
        .collection(AppConstants.colSettings)
        .doc(AppConstants.docSiteSettings)
        .set(settings.toMap(), SetOptions(merge: true));
  }

  // External launchers (WhatsApp, Phone call)
  static Future<void> openWhatsApp(String phone, String message) async {
    final formattedPhone = cleanPhoneForWhatsApp(phone);
    final uri = Uri.parse(
        'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
