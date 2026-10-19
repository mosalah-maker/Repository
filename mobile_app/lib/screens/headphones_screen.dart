import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../services/firebase_service.dart';
import 'booking_detail_screen.dart';

class HeadphonesScreen extends StatefulWidget {
  const HeadphonesScreen({super.key});

  @override
  State<HeadphonesScreen> createState() => _HeadphonesScreenState();
}

class _HeadphonesScreenState extends State<HeadphonesScreen> {
  String _selectedStatus = 'الكل';
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

    var list = admin.headphones;

    // Filter by status
    if (_selectedStatus != 'الكل') {
      list = list.where((h) => h.status == _selectedStatus).toList();
    }

    // Filter by search query
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((h) {
        return h.name.toLowerCase().contains(q) ||
            h.phone.contains(q) ||
            h.device.toLowerCase().contains(q) ||
            h.address.toLowerCase().contains(q);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، الهاتف، الجهاز، العنوان...',
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

          // Horizontal status filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildChip('الكل', admin.headphones.length),
                ...AppConstants.headphoneStatuses.map((st) {
                  final count = admin.headphones.where((h) => h.status == st).length;
                  return _buildChip(st, count);
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Reservations List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد حجوزات مطابقة',
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
                      return _buildHeadphoneCard(context, item, admin);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int count) {
    final isSelected = _selectedStatus == label;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        labelStyle: GoogleFonts.cairo(
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppConstants.darkCard,
        selectedColor: AppConstants.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? AppConstants.primary : AppConstants.darkBorder,
          ),
        ),
        onSelected: (val) => setState(() => _selectedStatus = label),
      ),
    );
  }

  Widget _buildHeadphoneCard(
      BuildContext context, HeadphoneReservation item, AdminProvider admin) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                kind: 'headphones',
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
              // Top Row: Name and Status Chip
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
                            item.status,
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

              // Device & Address
              if (item.device.isNotEmpty)
                Row(
                  children: [
                    const Icon(LucideIcons.box,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.device,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ],
                ),
              if (item.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.mapPin,
                          size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.address,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(color: AppConstants.darkBorder, height: 20),

              // Bottom Actions Row: Phone, WhatsApp, Payment Badge
              Row(
                children: [
                  _paymentBadge(item.paymentState),
                  const Spacer(),
                  if (item.phone.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(LucideIcons.phone,
                          size: 18, color: AppConstants.accent),
                      onPressed: () =>
                          FirebaseService.makePhoneCall(item.phone),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.messageCircle,
                          size: 18, color: Color(0xFF25D366)),
                      onPressed: () {
                        final msg =
                            'مرحباً ${item.name}،\nنشكرك على حجزك في أبو زهرة للإلكترونيات.\nلتأكيد حجز السماعة حوّل مبلغ تأمين الشحن على فودافون كاش: ${admin.settings.cashNumber}\nرابط الحجز: ${AppConstants.confirmHeadphoneUrl}?id=${item.id}';
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
    if (status == 'ملغي') return AppConstants.danger;
    if (status == 'تم الاستلام') return AppConstants.accent;
    if (AppConstants.inProgressStatuses.contains(status)) {
      return AppConstants.warning;
    }
    return AppConstants.primary;
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
      BuildContext context, HeadphoneReservation item, AdminProvider admin) {
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
                  'تغيير حالة حجز: ${item.name}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: AppConstants.darkBorder, height: 20),
              ...AppConstants.headphoneStatuses.map((st) {
                final isCurrent = item.status == st;
                return ListTile(
                  title: Text(
                    st,
                    style: GoogleFonts.cairo(
                      color: isCurrent ? AppConstants.primary : Colors.white,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isCurrent
                      ? const Icon(LucideIcons.check,
                          color: AppConstants.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await admin.updateHeadphoneStatus(item.id, st);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تغيير الحالة إلى: $st')),
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
}
