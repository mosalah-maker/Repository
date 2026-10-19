import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: admin.sections.isEmpty
          ? Center(
              child: Text(
                'لا توجد شُعب دراسية مسجلة',
                style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: admin.sections.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sec = admin.sections[index];
                final studentCount =
                    admin.exams.where((e) => e.section == sec.name).length;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sec.name,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppConstants.primary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$studentCount طالب',
                                style: GoogleFonts.cairo(
                                  color: AppConstants.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (sec.examLink.isNotEmpty)
                          Row(
                            children: [
                              const Icon(LucideIcons.link,
                                  size: 14, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sec.examLink,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppConstants.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const Divider(
                            color: AppConstants.darkBorder, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(LucideIcons.edit2, size: 16),
                              label: Text('تعديل', style: GoogleFonts.cairo()),
                              onPressed: () => _showAddEditSectionModal(
                                  context, admin,
                                  section: sec),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(LucideIcons.trash2,
                                  size: 16, color: AppConstants.danger),
                              label: Text('حذف',
                                  style: GoogleFonts.cairo(
                                      color: AppConstants.danger)),
                              onPressed: () {
                                admin.deleteSection(sec.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تم حذف الشعبة بنجاح')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'إضافة شعبة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showAddEditSectionModal(context, admin),
      ),
    );
  }

  void _showAddEditSectionModal(BuildContext context, AdminProvider admin,
      {Section? section}) {
    final nameCtrl = TextEditingController(text: section?.name ?? '');
    final linkCtrl = TextEditingController(text: section?.examLink ?? '');
    final maxCtrl = TextEditingController(
        text: section?.maxStudents != null && section!.maxStudents > 0
            ? section.maxStudents.toString()
            : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                section == null ? 'إضافة شعبة جديدة' : 'تعديل الشعبة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: AppConstants.darkBorder, height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'اسم الشعبة (مثال: شعبة 1 - السبت) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkCtrl,
                decoration:
                    const InputDecoration(labelText: 'رابط الامتحان الخاص بها'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'الحد الأقصى للطلاب (اختياري)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال اسم الشعبة')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await admin.saveSection(
                    id: section?.id,
                    name: name,
                    examLink: linkCtrl.text.trim(),
                    maxStudents: int.tryParse(maxCtrl.text.trim()) ?? 0,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ الشعبة بنجاح')),
                    );
                  }
                },
                child: const Text('حفظ الشعبة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
