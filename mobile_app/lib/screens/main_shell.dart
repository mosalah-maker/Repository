import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../services/auth_service.dart';
import 'booking_detail_screen.dart';
import 'exams_screen.dart';
import 'headphones_screen.dart';
import 'home_screen.dart';
import 'payments_screen.dart';
import 'products_screen.dart';
import 'sections_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'الرئيسية',
    'حجوزات السماعات',
    'حجوزات الامتحانات',
    'مراجعة المدفوعات',
    'المنتجات والخصومات',
    'الشُعب الدراسية',
    'إعدادات النظام',
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    final List<Widget> screens = [
      HomeScreen(onNavigate: (index) => setState(() => _currentIndex = index)),
      const HeadphonesScreen(),
      const ExamsScreen(),
      const PaymentsScreen(),
      const ProductsScreen(),
      const SectionsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () => _showQuickSearch(context, admin),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.bell),
                onPressed: () => _showNotifications(context, admin),
              ),
              if (admin.proofsCount + admin.reviewHeadphonesCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppConstants.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${admin.proofsCount + admin.reviewHeadphonesCount}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppConstants.darkBg,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppConstants.darkCard,
                border: Border(bottom: BorderSide(color: AppConstants.darkBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.shieldCheck,
                      color: AppConstants.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'أبو زهرة للإلكترونيات',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'تطبيق الإدارة الموحد',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _drawerTile(
              index: 0,
              icon: LucideIcons.layoutDashboard,
              title: 'الرئيسية',
            ),
            _drawerTile(
              index: 1,
              icon: LucideIcons.headphones,
              title: 'السماعات',
              badge: admin.reviewHeadphonesCount,
            ),
            _drawerTile(
              index: 2,
              icon: LucideIcons.graduationCap,
              title: 'الامتحانات',
              badge: admin.pendingExamsCount,
            ),
            _drawerTile(
              index: 3,
              icon: LucideIcons.wallet,
              title: 'المدفوعات والإثباتات',
              badge: admin.proofsCount,
            ),
            _drawerTile(
              index: 4,
              icon: LucideIcons.box,
              title: 'المنتجات',
            ),
            _drawerTile(
              index: 5,
              icon: LucideIcons.layers,
              title: 'الشُعب الدراسية',
            ),
            _drawerTile(
              index: 6,
              icon: LucideIcons.settings,
              title: 'الإعدادات',
            ),
            const Divider(color: AppConstants.darkBorder),
            ListTile(
              leading:
                  const Icon(LucideIcons.logOut, color: AppConstants.danger),
              title: Text(
                'تسجيل الخروج',
                style: GoogleFonts.cairo(
                  color: AppConstants.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 3 ? 4 : _currentIndex,
        onTap: (index) {
          if (index == 4) {
            _showMoreMenu(context);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(LucideIcons.headphones),
                if (admin.reviewHeadphonesCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppConstants.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'السماعات',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(LucideIcons.graduationCap),
                if (admin.pendingExamsCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppConstants.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'الامتحانات',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(LucideIcons.wallet),
                if (admin.proofsCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppConstants.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'المدفوعات',
          ),
          const BottomNavigationBarItem(
            icon: Icon(LucideIcons.menu),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required int index,
    required IconData icon,
    required String title,
    int? badge,
  }) {
    final isSelected = _currentIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppConstants.primary.withOpacity(0.12),
      leading: Icon(
        icon,
        color: isSelected ? AppConstants.primary : const Color(0xFF94A3B8),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: (badge != null && badge > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badge',
                style: GoogleFonts.cairo(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context);
      },
    );
  }

  void _showMoreMenu(BuildContext context) {
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
            children: [
              ListTile(
                leading: const Icon(LucideIcons.box, color: AppConstants.primary),
                title: Text('المنتجات والخصومات', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 4);
                },
              ),
              ListTile(
                leading:
                    const Icon(LucideIcons.layers, color: AppConstants.secondary),
                title: Text('الشُعب الدراسية', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 5);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.settings,
                    color: Color(0xFF94A3B8)),
                title: Text('إعدادات النظام', style: GoogleFonts.cairo()),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 6);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, AdminProvider admin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'التنبيهات العاجلة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: AppConstants.darkBorder, height: 20),
              ListTile(
                leading: const Icon(LucideIcons.wallet,
                    color: AppConstants.warning),
                title: Text(
                  '${admin.proofsCount} إثبات دفع بانتظار المراجعة',
                  style: GoogleFonts.cairo(),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 3);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.headphones,
                    color: AppConstants.primary),
                title: Text(
                  '${admin.reviewHeadphonesCount} حجز سماعة قيد المراجعة',
                  style: GoogleFonts.cairo(),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.graduationCap,
                    color: AppConstants.secondary),
                title: Text(
                  '${admin.pendingExamsCount} حجز امتحان بانتظار التأكيد',
                  style: GoogleFonts.cairo(),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _currentIndex = 2);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickSearch(BuildContext context, AdminProvider admin) {
    showSearch(
      context: context,
      delegate: _AppSearchDelegate(admin),
    );
  }
}

class _AppSearchDelegate extends SearchDelegate {
  final AdminProvider admin;

  _AppSearchDelegate(this.admin);

  @override
  String get searchFieldLabel => 'ابحث في كل الحجوزات...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppConstants.darkBg,
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowRight),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().length < 2) {
      return Center(
        child: Text(
          'أدخل حرفين على الأقل للبحث بالاسم أو الهاتف',
          style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
        ),
      );
    }

    final q = query.trim().toLowerCase();

    final hResults = admin.headphones
        .where((h) =>
            h.name.toLowerCase().contains(q) ||
            h.phone.contains(q) ||
            h.device.toLowerCase().contains(q))
        .toList();

    final eResults = admin.exams
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.phone.contains(q) ||
            e.section.toLowerCase().contains(q))
        .toList();

    if (hResults.isEmpty && eResults.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج مطابقة لـ "$query"',
          style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hResults.isNotEmpty) ...[
          Text('حجوزات السماعات (${hResults.length})',
              style: GoogleFonts.cairo(
                  color: AppConstants.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...hResults.map((h) => Card(
                child: ListTile(
                  title: Text(h.name,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle: Text('${h.device} • ${h.phone}',
                      style: GoogleFonts.cairo(fontSize: 12)),
                  trailing: Text(h.status,
                      style: GoogleFonts.cairo(
                          color: AppConstants.primary, fontSize: 11)),
                  onTap: () {
                    close(context, null);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(
                          kind: 'headphones',
                          item: h,
                        ),
                      ),
                    );
                  },
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (eResults.isNotEmpty) ...[
          Text('حجوزات الامتحانات (${eResults.length})',
              style: GoogleFonts.cairo(
                  color: AppConstants.secondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...eResults.map((e) => Card(
                child: ListTile(
                  title: Text(e.name,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle: Text('${e.section} • ${e.phone}',
                      style: GoogleFonts.cairo(fontSize: 12)),
                  trailing: Text(e.statusLabel,
                      style: GoogleFonts.cairo(
                          color: AppConstants.secondary, fontSize: 11)),
                  onTap: () {
                    close(context, null);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailScreen(
                          kind: 'exams',
                          item: e,
                        ),
                      ),
                    );
                  },
                ),
              )),
        ],
      ],
    );
  }
}
