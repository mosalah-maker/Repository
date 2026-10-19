import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../services/firebase_service.dart';

class BookingDetailScreen extends StatelessWidget {
  final String kind; // 'headphones' | 'exams'
  final dynamic item; // HeadphoneReservation or ExamReservation

  const BookingDetailScreen({
    super.key,
    required this.kind,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final isHeadphone = kind == 'headphones';

    final name = isHeadphone
        ? (item as HeadphoneReservation).name
        : (item as ExamReservation).name;
    final phone = isHeadphone
        ? (item as HeadphoneReservation).phone
        : (item as ExamReservation).phone;
    final status = isHeadphone
        ? (item as HeadphoneReservation).status
        : (item as ExamReservation).statusLabel;
    final paymentState = isHeadphone
        ? (item as HeadphoneReservation).paymentState
        : (item as ExamReservation).paymentState;
    final proofUrl = isHeadphone
        ? (item as HeadphoneReservation).paymentProofUrl
        : (item as ExamReservation).paymentProofUrl;
    final createdAt = isHeadphone
        ? (item as HeadphoneReservation).createdAt
        : (item as ExamReservation).createdAt;

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: Text(isHeadphone ? 'تفاصيل حجز السماعة' : 'تفاصيل حجز الامتحان'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppConstants.danger),
            onPressed: () => _confirmDelete(context, admin, isHeadphone, item.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name.isNotEmpty ? name : 'بدون اسم',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(LucideIcons.phone, size: 16, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          phone.isNotEmpty ? phone : 'لا يوجد رقم',
                          style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
                        ),
                        const Spacer(),
                        if (phone.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(LucideIcons.phoneCall, color: AppConstants.accent),
                            onPressed: () => FirebaseService.makePhoneCall(phone),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.messageCircle, color: Color(0xFF25D366)),
                            onPressed: () => FirebaseService.openWhatsApp(
                              phone,
                              isHeadphone
                                  ? 'مرحباً $name، بخصوص حجز السماعة الخاص بكم في أبو زهرة...'
                                  : 'مرحباً $name، بخصوص حجز الامتحان في أبو زهرة...',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Specific fields card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات الطلب',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Divider(color: AppConstants.darkBorder, height: 24),
                    if (isHeadphone) ...[
                      _rowInfo('الجهاز المطلوب', (item as HeadphoneReservation).device),
                      _rowInfo('العنوان', (item as HeadphoneReservation).address),
                      _rowInfo('موعد التسليم', (item as HeadphoneReservation).deliveryDate),
                      _rowInfo('ملاحظات العميل', (item as HeadphoneReservation).question),
                    ] else ...[
                      _rowInfo('الشعبة الدراسية', (item as ExamReservation).section),
                      _rowInfo('رقم الجلوس', (item as ExamReservation).seatNumber ?? 'لم يحدد'),
                      _rowInfo('رابط الامتحان', (item as ExamReservation).examLink ?? 'لم يحدد'),
                    ],
                    _rowInfo('تاريخ الحجز', formatDate(createdAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Payment proof card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'إثبات الدفع والتحويل',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        _buildPaymentBadge(paymentState),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (proofUrl != null && proofUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: proofUrl,
                          fit: BoxFit.cover,
                          height: 220,
                          width: double.infinity,
                          placeholder: (c, u) => Container(
                            height: 220,
                            color: Colors.black26,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (c, u, e) => Container(
                            height: 220,
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(LucideIcons.imageOff, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.accent,
                              ),
                              icon: const Icon(LucideIcons.checkCheck),
                              label: const Text('اعتماد الدفع'),
                              onPressed: () async {
                                if (isHeadphone) {
                                  await admin.reviewHeadphonePayment(item.id, true, proofUrl);
                                } else {
                                  await admin.reviewExamPayment(item.id, true, proofUrl);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم اعتماد الدفع بنجاح')),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.danger,
                              ),
                              icon: const Icon(LucideIcons.xCircle),
                              label: const Text('رفض الدفع'),
                              onPressed: () async {
                                if (isHeadphone) {
                                  await admin.reviewHeadphonePayment(item.id, false, proofUrl);
                                } else {
                                  await admin.reviewExamPayment(item.id, false, proofUrl);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم رفض الدفع')),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'لم يتم رفع صورة إيصال فودافون كاش أو إنستاباي بعد.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.primary.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(PaymentState state) {
    Color color;
    String text;
    switch (state) {
      case PaymentState.approved:
        color = AppConstants.accent;
        text = 'الدفع معتمد';
        break;
      case PaymentState.review:
        color = AppConstants.warning;
        text = 'بانتظار المراجعة';
        break;
      case PaymentState.rejected:
        color = AppConstants.danger;
        text = 'الدفع مرفوض';
        break;
      case PaymentState.none:
        color = const Color(0xFF94A3B8);
        text = 'لا يوجد إثبات';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AdminProvider admin, bool isHeadphone, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: Text(
          'تأكيد الحذف',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف هذا الحجز نهائياً من قاعدة البيانات؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              if (isHeadphone) {
                await admin.deleteHeadphone(id);
              } else {
                await admin.deleteExam(id);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الحجز بنجاح')),
                );
              }
            },
            child: Text('حذف', style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
