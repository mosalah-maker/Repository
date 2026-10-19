import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../services/firebase_service.dart';
import 'booking_detail_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String _selectedStatus = 'الكل';
  String _selectedSection = 'كل الشعب';
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    var list = admin.exams;

    // Filter by status
    if (_selectedStatus != 'الكل') {
      list = list.where((e) => e.status == _selectedStatus).toList();
    }

    // Filter by section
    if (_selectedSection != 'كل الشعب') {
      list = list.where((e) => e.section == _selectedSection).toList();
    }

    // Filter by search query
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.phone.contains(q) ||
            e.section.toLowerCase().contains(q) ||
            (e.seatNumber?.contains(q) ?? false);
      }).toList();
    }

    final sectionsList = ['كل الشعب', ...admin.sections.map((s) => s.name)];

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، الهاتف، الشعبة، رقم الجلوس...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filters Row: Status Chips & Section Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildStatusChip('الكل', 'الكل', admin.exams.length),
                        _buildStatusChip(
                            'pending',
                            'بانتظار التأكيد',
                            admin.exams
                                .where((e) => e.status == 'pending')
                                .length),
                        _buildStatusChip(
                            'confirmed',
                            'تم التأكيد',
                            admin.exams
                                .where((e) => e.status == 'confirmed')
                                .length),
                        _buildStatusChip(
                            'cancelled',
                            'ملغي',
                            admin.exams
                                .where((e) => e.status == 'cancelled')
                                .length),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sectionsList.contains(_selectedSection)
                      ? _selectedSection
                      : 'كل الشعب',
                  dropdownColor: AppConstants.darkCard,
                  underline: const SizedBox(),
                  icon: const Icon(LucideIcons.filter, size: 18),
                  items: sectionsList.map((sec) {
                    return DropdownMenuItem(
                      value: sec,
                      child: Text(
                        sec,
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSection = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exams List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد حجوزات امتحانات مطابقة',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF94A3B8),
                        fontSize: 15,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return _buildExamCard(context, item, admin);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, int count) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        labelStyle: GoogleFonts.cairo(
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppConstants.darkCard,
        selectedColor: AppConstants.secondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppConstants.secondary : AppConstants.darkBorder,
          ),
        ),
        onSelected: (val) => setState(() => _selectedStatus = value),
      ),
    );
  }

  Widget _buildExamCard(
      BuildContext context, ExamReservation item, AdminProvider admin) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                kind: 'exams',
                item: item,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name.isNotEmpty ? item.name : 'بدون اسم',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showStatusPicker(context, item, admin),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(item.status).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _statusColor(item.status).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.statusLabel,
                            style: GoogleFonts.cairo(
                              color: _statusColor(item.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronDown,
                              size: 14, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Section & Seat Number
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.section.isNotEmpty ? item.section : 'بدون شعبة',
                      style: GoogleFonts.cairo(
                        color: AppConstants.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (item.seatNumber != null && item.seatNumber!.isNotEmpty)
                    Text(
                      'جلوس: ${item.seatNumber}',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFCBD5E1),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const Divider(color: AppConstants.darkBorder, height: 20),

              // Bottom Actions
              Row(
                children: [
                  _paymentBadge(item.paymentState),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.fileEdit,
                        size: 18, color: AppConstants.primary),
                    onPressed: () => _editExamDetails(context, item, admin),
                  ),
                  if (item.phone.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(LucideIcons.phone,
                          size: 18, color: AppConstants.accent),
                      onPressed: () => FirebaseService.makePhoneCall(item.phone),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.messageCircle,
                          size: 18, color: Color(0xFF25D366)),
                      onPressed: () {
                        final msg =
                            'مرحباً ${item.name}،\nبخصوص حجز الامتحان في أبو زهرة (شعبة: ${item.section}).\nرابط المتابعة: ${AppConstants.confirmExamUrl}?id=${item.id}';
                        FirebaseService.openWhatsApp(item.phone, msg);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'confirmed') return AppConstants.accent;
    if (status == 'cancelled') return AppConstants.danger;
    return AppConstants.warning;
  }

  Widget _paymentBadge(PaymentState state) {
    Color color;
    String text;
    switch (state) {
      case PaymentState.approved:
        color = AppConstants.accent;
        text = 'الدفع معتمد';
        break;
      case PaymentState.review:
        color = AppConstants.warning;
        text = 'مراجعة الدفع';
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(color: color, fontSize: 11),
      ),
    );
  }

  void _showStatusPicker(
      BuildContext context, ExamReservation item, AdminProvider admin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'تغيير حالة الامتحان: ${item.name}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: AppConstants.darkBorder, height: 20),
              ...AppConstants.examStatuses.entries.map((entry) {
                final isCurrent = item.status == entry.key;
                return ListTile(
                  title: Text(
                    entry.value,
                    style: GoogleFonts.cairo(
                      color: isCurrent ? AppConstants.secondary : Colors.white,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(LucideIcons.check,
                          color: AppConstants.secondary)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await admin.updateExamStatus(item.id, entry.key);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('تم تغيير الحالة إلى: ${entry.value}')),
                      );
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _editExamDetails(
      BuildContext context, ExamReservation item, AdminProvider admin) {
    final seatCtrl = TextEditingController(text: item.seatNumber ?? '');
    final linkCtrl = TextEditingController(text: item.examLink ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: Text(
          'تعديل بيانات الامتحان',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('رقم الجلوس', style: GoogleFonts.cairo(fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: seatCtrl,
              decoration: const InputDecoration(hintText: 'مثال: 104'),
            ),
            const SizedBox(height: 14),
            Text('رابط الامتحان الخاص به',
                style: GoogleFonts.cairo(fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: linkCtrl,
              decoration:
                  const InputDecoration(hintText: 'https://forms.gle/...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await admin.updateExamStatus(
                item.id,
                item.status,
                seatNumber: seatCtrl.text.trim(),
                examLink: linkCtrl.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث البيانات بنجاح')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
