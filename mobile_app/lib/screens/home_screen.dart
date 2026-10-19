import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import 'booking_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        // Stream updates automatically
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Welcome
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppConstants.primary.withOpacity(0.2),
                  child: const Icon(LucideIcons.user, color: AppConstants.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً بك في لوحة تحكم أبو زهرة',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'إحصائيات فورية ومباشرة من Firebase',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Urgent Tasks Grid
            Text(
              'ما يحتاج تدخلك الآن',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                _buildTaskCard(
                  title: 'سماعات جديدة',
                  count: admin.reviewHeadphonesCount,
                  subtitle: 'قيد المراجعة',
                  icon: LucideIcons.headphones,
                  color: AppConstants.primary,
                  onTap: () => onNavigate(1), // Headphones screen
                ),
                _buildTaskCard(
                  title: 'امتحانات جديدة',
                  count: admin.pendingExamsCount,
                  subtitle: 'بانتظار التأكيد',
                  icon: LucideIcons.graduationCap,
                  color: AppConstants.secondary,
                  onTap: () => onNavigate(2), // Exams screen
                ),
                _buildTaskCard(
                  title: 'إثباتات للمراجعة',
                  count: admin.proofsCount,
                  subtitle: 'إيصالات كاش معلقة',
                  icon: LucideIcons.wallet,
                  color: AppConstants.warning,
                  onTap: () => onNavigate(3), // Payments screen
                ),
                _buildTaskCard(
                  title: 'طلبات قيد التنفيذ',
                  count: admin.inProgressCount,
                  subtitle: 'جاري التجهيز والشحن',
                  icon: LucideIcons.truck,
                  color: AppConstants.accent,
                  onTap: () => onNavigate(1), // Headphones screen
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Today's summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar,
                            color: AppConstants.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ملخص نشاط اليوم',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppConstants.darkBorder, height: 20),
                    _summaryRow('حجوزات سماعات اليوم', admin.todayHeadphonesCount),
                    _summaryRow('حجوزات امتحان اليوم', admin.todayExamsCount),
                    _summaryRow('إثباتات دفع تم رفعها اليوم', admin.todayProofsCount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent activity
            Text(
              'آخر الحجوزات والتحديثات',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (admin.activities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'لا توجد أنشطة مسجلة حتى الآن.',
                      style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: admin.activities.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final act = admin.activities[index];
                  final isHeadphone = act.kind == 'headphones';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isHeadphone
                            ? AppConstants.primary.withOpacity(0.2)
                            : AppConstants.secondary.withOpacity(0.2),
                        child: Icon(
                          isHeadphone
                              ? LucideIcons.headphones
                              : LucideIcons.graduationCap,
                          color: isHeadphone
                              ? AppConstants.primary
                              : AppConstants.secondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        act.title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${act.detail} • ${formatDate(act.at)}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      trailing: const Icon(LucideIcons.chevronLeft,
                          size: 18, color: Color(0xFF94A3B8)),
                      onTap: () {
                        if (isHeadphone) {
                          final item = admin.headphones.firstWhere(
                            (h) => h.id == act.id,
                            orElse: () => HeadphoneReservation(
                              id: act.id,
                              name: act.title,
                              phone: '',
                              address: '',
                              device: '',
                              status: '',
                              deliveryDate: '',
                              question: '',
                              paymentConfirmed: false,
                              paymentRejected: false,
                              raw: {},
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(
                                kind: 'headphones',
                                item: item,
                              ),
                            ),
                          );
                        } else {
                          final item = admin.exams.firstWhere(
                            (e) => e.id == act.id,
                            orElse: () => ExamReservation(
                              id: act.id,
                              name: act.title,
                              phone: '',
                              section: '',
                              status: '',
                              paymentConfirmed: false,
                              paymentRejected: false,
                              raw: {},
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(
                                kind: 'exams',
                                item: item,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: GoogleFonts.cairo(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
