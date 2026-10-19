import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _waCtrl;
  late TextEditingController _cashNumCtrl;
  late TextEditingController _cashAmtCtrl;
  late TextEditingController _examAmtCtrl;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final s = context.read<AdminProvider>().settings;
      _waCtrl = TextEditingController(text: s.whatsapp);
      _cashNumCtrl = TextEditingController(text: s.cashNumber);
      _cashAmtCtrl = TextEditingController(text: s.cashAmount);
      _examAmtCtrl = TextEditingController(text: s.examAmount);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _waCtrl.dispose();
    _cashNumCtrl.dispose();
    _cashAmtCtrl.dispose();
    _examAmtCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final admin = context.read<AdminProvider>();
    setState(() => _saving = true);

    final newSettings = SiteSettings(
      whatsapp: _waCtrl.text.trim(),
      cashNumber: _cashNumCtrl.text.trim(),
      cashAmount: _cashAmtCtrl.text.trim(),
      examAmount: _examAmtCtrl.text.trim(),
      productDiscount: admin.settings.productDiscount,
    );

    try {
      await admin.saveSettings(newSettings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ الإعدادات')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.phoneCall,
                              color: Color(0xFF25D366)),
                          const SizedBox(width: 8),
                          Text(
                            'أرقام التواصل والتحويل',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppConstants.darkBorder, height: 20),
                      Text(
                        'رقم الواتساب الرسمي (بدون مسافات)',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _waCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '010XXXXXXXX',
                          prefixIcon: Icon(LucideIcons.messageCircle, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'رقم فودافون كاش لاستلام التأمينات',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cashNumCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '010XXXXXXXX',
                          prefixIcon: Icon(LucideIcons.wallet, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.coins,
                              color: AppConstants.warning),
                          const SizedBox(width: 8),
                          Text(
                            'مبالغ التأمين والرسوم',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppConstants.darkBorder, height: 20),
                      Text(
                        'مبلغ تأمين شحن السماعة (جنيه مصري)',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cashAmtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'مثال: 50',
                          suffixText: 'ج.م',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'مبلغ تأكيد حجز الامتحان (جنيه مصري)',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _examAmtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'مثال: 30',
                          suffixText: 'ج.م',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.save),
                label: const Text('حفظ الإعدادات'),
                onPressed: _saving ? null : _handleSave,
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.danger,
                  side: const BorderSide(color: AppConstants.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.logOut),
                label: Text(
                  'تسجيل الخروج من الحساب',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await AuthService().signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
