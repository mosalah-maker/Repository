import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();

  List<HeadphoneReservation> _headphones = [];
  List<ExamReservation> _exams = [];
  List<Product> _products = [];
  List<Section> _sections = [];
  SiteSettings _settings = SiteSettings();

  bool _loading = true;
  String? _error;

  StreamSubscription? _subHeadphones;
  StreamSubscription? _subExams;
  StreamSubscription? _subProducts;
  StreamSubscription? _subSections;
  StreamSubscription? _subSettings;

  AdminProvider() {
    _initStreams();
  }

  // Getters
  List<HeadphoneReservation> get headphones => _headphones;
  List<ExamReservation> get exams => _exams;
  List<Product> get products => _products;
  List<Section> get sections => _sections;
  SiteSettings get settings => _settings;
  bool get loading => _loading;
  String? get error => _error;

  // Stats
  int get reviewHeadphonesCount =>
      _headphones.where((h) => h.status == 'قيد المراجعة').length;

  int get pendingExamsCount =>
      _exams.where((e) => e.status == 'pending').length;

  int get proofsCount =>
      _headphones.where((h) => h.needsPaymentReview).length +
      _exams.where((e) => e.needsPaymentReview).length;

  int get inProgressCount => _headphones
      .where((h) =>
          h.status == 'تم التواصل' ||
          h.status == 'تحت التجهيز' ||
          h.status == 'تم الانتهاء من التجهيز' ||
          h.status == 'تم تسليمه لمندوب الشحن')
      .length;

  int get todayHeadphonesCount {
    final now = DateTime.now();
    return _headphones.where((h) {
      if (h.createdAt == null) return false;
      return h.createdAt!.year == now.year &&
          h.createdAt!.month == now.month &&
          h.createdAt!.day == now.day;
    }).length;
  }

  int get todayExamsCount {
    final now = DateTime.now();
    return _exams.where((e) {
      if (e.createdAt == null) return false;
      return e.createdAt!.year == now.year &&
          e.createdAt!.month == now.month &&
          e.createdAt!.day == now.day;
    }).length;
  }

  int get todayProofsCount {
    final now = DateTime.now();
    final hProofs = _headphones.where((h) {
      if (h.paymentSubmittedAt == null) return false;
      return h.paymentSubmittedAt!.year == now.year &&
          h.paymentSubmittedAt!.month == now.month &&
          h.paymentSubmittedAt!.day == now.day;
    }).length;
    final eProofs = _exams.where((e) {
      if (e.paymentSubmittedAt == null) return false;
      return e.paymentSubmittedAt!.year == now.year &&
          e.paymentSubmittedAt!.month == now.month &&
          e.paymentSubmittedAt!.day == now.day;
    }).length;
    return hProofs + eProofs;
  }

  List<ActivityItem> get activities {
    final List<ActivityItem> list = [];

    for (final h in _headphones) {
      if (h.createdAt != null) {
        list.add(ActivityItem(
          key: 'ch-${h.id}',
          kind: 'headphones',
          id: h.id,
          at: h.createdAt!,
          title: h.name.isNotEmpty ? h.name : 'حجز سماعة',
          detail: 'حجز سماعة جديد',
        ));
      }
      if (h.paymentSubmittedAt != null) {
        list.add(ActivityItem(
          key: 'ph-${h.id}',
          kind: 'headphones',
          id: h.id,
          at: h.paymentSubmittedAt!,
          title: h.name.isNotEmpty ? h.name : 'حجز سماعة',
          detail: 'إثبات دفع لسماعة',
        ));
      }
    }

    for (final e in _exams) {
      if (e.createdAt != null) {
        list.add(ActivityItem(
          key: 'ce-${e.id}',
          kind: 'exams',
          id: e.id,
          at: e.createdAt!,
          title: e.name.isNotEmpty ? e.name : 'حجز امتحان',
          detail: 'حجز امتحان جديد',
        ));
      }
      if (e.paymentSubmittedAt != null) {
        list.add(ActivityItem(
          key: 'pe-${e.id}',
          kind: 'exams',
          id: e.id,
          at: e.paymentSubmittedAt!,
          title: e.name.isNotEmpty ? e.name : 'حجز امتحان',
          detail: 'إثبات دفع لامتحان',
        ));
      }
    }

    list.sort((a, b) => b.at.compareTo(a.at));
    return list.take(15).toList();
  }

  void _initStreams() {
    _loading = true;

    _subHeadphones = _service.streamHeadphones().listen(
      (data) {
        _headphones = data;
        _loading = false;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        _loading = false;
        notifyListeners();
      },
    );

    _subExams = _service.streamExams().listen(
      (data) {
        _exams = data;
        notifyListeners();
      },
      onError: (err) {
        _error = err.toString();
        notifyListeners();
      },
    );

    _subProducts = _service.streamProducts().listen(
      (data) {
        _products = data;
        notifyListeners();
      },
    );

    _subSections = _service.streamSections().listen(
      (data) {
        _sections = data;
        notifyListeners();
      },
    );

    _subSettings = _service.streamSettings().listen(
      (data) {
        _settings = data;
        notifyListeners();
      },
    );
  }

  // Operations
  Future<void> updateHeadphoneStatus(String id, String status) =>
      _service.updateHeadphoneStatus(id, status);

  Future<void> reviewHeadphonePayment(
          String id, bool approved, String? currentProof) =>
      _service.reviewHeadphonePayment(id, approved, currentProof);

  Future<void> deleteHeadphone(String id) => _service.deleteHeadphone(id);

  Future<void> updateExamStatus(String id, String status,
          {String? seatNumber, String? examLink}) =>
      _service.updateExamStatus(id, status,
          seatNumber: seatNumber, examLink: examLink);

  Future<void> reviewExamPayment(
          String id, bool approved, String? currentProof) =>
      _service.reviewExamPayment(id, approved, currentProof);

  Future<void> deleteExam(String id) => _service.deleteExam(id);

  Future<void> saveProduct({
    String? id,
    required String name,
    required String description,
    required double price,
    double? originalPrice,
    double? discountPercent,
    String? image,
  }) =>
      _service.saveProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        originalPrice: originalPrice,
        discountPercent: discountPercent,
        image: image,
      );

  Future<void> applyDiscountToAllProducts(double percent) =>
      _service.applyDiscountToAllProducts(_products, percent);

  Future<void> clearProductDiscount() =>
      _service.clearProductDiscount(_products);

  Future<void> deleteProduct(String id) => _service.deleteProduct(id);

  Future<void> saveSection({
    String? id,
    required String name,
    required String examLink,
    required int maxStudents,
  }) =>
      _service.saveSection(
        id: id,
        name: name,
        examLink: examLink,
        maxStudents: maxStudents,
      );

  Future<void> deleteSection(String id) => _service.deleteSection(id);

  Future<void> saveSettings(SiteSettings settings) =>
      _service.saveSettings(settings);

  @override
  void dispose() {
    _subHeadphones?.cancel();
    _subExams?.cancel();
    _subProducts?.cancel();
    _subSections?.cancel();
    _subSettings?.cancel();
    super.dispose();
  }
}
