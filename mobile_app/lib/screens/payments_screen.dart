import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../services/firebase_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    // Collect all payment proofs from headphones and exams
    final hProofs = admin.headphones.where((h) =>
        (h.paymentProofUrl != null && h.paymentProofUrl!.isNotEmpty) ||
        h.paymentConfirmed);
    final eProofs = admin.exams.where((e) =>
        (e.paymentProofUrl != null && e.paymentProofUrl!.isNotEmpty) ||
        e.paymentConfirmed);

    final pendingList = [
      ...admin.headphones.where((h) => h.needsPaymentReview).map((h) => {
            'kind': 'headphones',
            'id': h.id,
            'name': h.name,
            'phone': h.phone,
            'senderPhone': h.senderPhone,
            'proofUrl': h.paymentProofUrl,
            'submittedAt': h.paymentSubmittedAt,
            'state': h.paymentState,
            'label': 'سماعة: ${h.device}',
          }),
      ...admin.exams.where((e) => e.needsPaymentReview).map((e) => {
            'kind': 'exams',
            'id': e.id,
            'name': e.name,
            'phone': e.phone,
            'senderPhone': e.senderPhone,
            'proofUrl': e.paymentProofUrl,
            'submittedAt': e.paymentSubmittedAt,
            'state': e.paymentState,
            'label': 'امتحان: ${e.section}',
          }),
    ];

    final allList = [
      ...hProofs.map((h) => {
            'kind': 'headphones',
            'id': h.id,
            'name': h.name,
            'phone': h.phone,
            'senderPhone': h.senderPhone,
            'proofUrl': h.paymentProofUrl,
            'submittedAt': h.paymentSubmittedAt,
            'state': h.paymentState,
            'label': 'سماعة: ${h.device}',
          }),
      ...eProofs.map((e) => {
            'kind': 'exams',
            'id': e.id,
            'name': e.name,
            'phone': e.phone,
            'senderPhone': e.senderPhone,
            'proofUrl': e.paymentProofUrl,
            'submittedAt': e.paymentSubmittedAt,
            'state': e.paymentState,
            'label': 'امتحان: ${e.section}',
          }),
    ];

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppConstants.darkCard,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppConstants.primary,
            labelColor: AppConstants.primary,
            unselectedLabelColor: const Color(0xFF94A3B8),
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'بانتظار المراجعة (${pendingList.length})'),
              Tab(text: 'كل المعاملات (${allList.length})'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(pendingList, admin, isPendingOnly: true),
          _buildList(allList, admin, isPendingOnly: false),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, AdminProvider admin,
      {required bool isPendingOnly}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.checkCircle,
                size: 48, color: AppConstants.accent),
            const SizedBox(height: 12),
            Text(
              isPendingOnly
                  ? 'لا توجد إثباتات دفع معلقة للمراجعة'
                  : 'لا توجد أي إثباتات دفع مسجلة',
              style: GoogleFonts.cairo(
                color: const Color(0xFF94A3B8),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (c, i) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = items[index];
        final proofUrl = item['proofUrl'] as String?;
        final isHeadphone = item['kind'] == 'headphones';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            item['label'] as String,
                            style: GoogleFonts.cairo(
                              color: AppConstants.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _paymentStateBadge(item['state'] as PaymentState),
                  ],
                ),
                const SizedBox(height: 10),

                // Sender Phone
                if (item['senderPhone'] != null &&
                    (item['senderPhone'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.smartphone,
                            size: 14, color: AppConstants.warning),
                        const SizedBox(width: 6),
                        Text(
                          'رقم المحفظة المحول منها: ${item['senderPhone']}',
                          style: GoogleFonts.cairo(
                            color: AppConstants.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Image Preview
                if (proofUrl != null && proofUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _viewFullImage(context, proofUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CachedNetworkImage(
                            imageUrl: proofUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                              height: 180,
                              color: Colors.black26,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                            errorWidget: (c, u, e) => Container(
                              height: 180,
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(LucideIcons.imageOff,
                                    size: 32, color: Colors.grey),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.maximize2,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'تكبير الإيصال',
                                  style: GoogleFonts.cairo(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Approve & Reject Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.accent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(LucideIcons.check, size: 18),
                        label: const Text('اعتماد الدفع'),
                        onPressed: () async {
                          if (isHeadphone) {
                            await admin.reviewHeadphonePayment(
                                item['id'], true, proofUrl);
                          } else {
                            await admin.reviewExamPayment(
                                item['id'], true, proofUrl);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم اعتماد الدفع بنجاح')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.danger,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(LucideIcons.x, size: 18),
                        label: const Text('رفض الدفع'),
                        onPressed: () async {
                          if (isHeadphone) {
                            await admin.reviewHeadphonePayment(
                                item['id'], false, proofUrl);
                          } else {
                            await admin.reviewExamPayment(
                                item['id'], false, proofUrl);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم رفض الدفع')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _paymentStateBadge(PaymentState state) {
    Color color;
    String text;
    switch (state) {
      case PaymentState.approved:
        color = AppConstants.accent;
        text = 'معتمد';
        break;
      case PaymentState.review:
        color = AppConstants.warning;
        text = 'قيد المراجعة';
        break;
      case PaymentState.rejected:
        color = AppConstants.danger;
        text = 'مرفوض';
        break;
      case PaymentState.none:
        color = const Color(0xFF94A3B8);
        text = 'بدون إثبات';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _viewFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(LucideIcons.x, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
