import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../providers/admin_provider.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final currentDiscount = admin.settings.productDiscount;

    return Scaffold(
      backgroundColor: AppConstants.darkBg,
      body: Column(
        children: [
          // Global Discount Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppConstants.darkCard,
            child: Row(
              children: [
                const Icon(LucideIcons.tag, color: AppConstants.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خصم المتجر العام: ${currentDiscount.isNotEmpty && currentDiscount != "0" ? "$currentDiscount%" : "لا يوجد خصم"}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'يطبق الخصم على جميع المنتجات دفعة واحدة',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showDiscountDialog(context, admin),
                  child: Text(
                    'تعديل الخصم',
                    style: GoogleFonts.cairo(
                      color: AppConstants.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: admin.products.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد منتجات مسجلة في المتجر',
                      style: GoogleFonts.cairo(color: const Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: admin.products.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final prod = admin.products[index];
                      return _buildProductCard(context, prod, admin);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(
          'إضافة منتج',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        onPressed: () => _showAddEditProductModal(context, admin),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, Product prod, AdminProvider admin) {
    final hasDiscount = prod.originalPrice != null && prod.originalPrice! > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: prod.image != null && prod.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: prod.image!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.black26,
                        child: const Icon(LucideIcons.box,
                            color: Color(0xFF94A3B8)),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.black26,
                      child: const Icon(LucideIcons.box,
                          color: Color(0xFF94A3B8)),
                    ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prod.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  if (prod.description.isNotEmpty)
                    Text(
                      prod.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${prod.price.toStringAsFixed(0)} ج.م',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.accent,
                          fontSize: 15,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${prod.originalPrice!.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(
                            decoration: TextDecoration.lineThrough,
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppConstants.danger.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'خصم ${(prod.discountPercent ?? 0).toStringAsFixed(0)}%',
                            style: GoogleFonts.cairo(
                              color: AppConstants.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions Menu
            PopupMenuButton(
              icon: const Icon(LucideIcons.moreVertical,
                  size: 18, color: Color(0xFF94A3B8)),
              color: AppConstants.darkCard,
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.edit2, size: 16),
                      const SizedBox(width: 8),
                      Text('تعديل', style: GoogleFonts.cairo()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.trash2,
                          size: 16, color: AppConstants.danger),
                      const SizedBox(width: 8),
                      Text('حذف',
                          style:
                              GoogleFonts.cairo(color: AppConstants.danger)),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddEditProductModal(context, admin, product: prod);
                } else if (val == 'delete') {
                  admin.deleteProduct(prod.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المنتج بنجاح')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, AdminProvider admin) {
    final ctrl = TextEditingController(text: admin.settings.productDiscount);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: Text(
          'تحديد نسبة الخصم العام (%)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'مثال: 15',
                suffixText: '%',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await admin.clearProductDiscount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إلغاء الخصم بنجاح')),
                );
              }
            },
            child: Text('إلغاء الخصم',
                style: GoogleFonts.cairo(color: AppConstants.danger)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pct = double.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(ctx);
              if (pct > 0) {
                await admin.applyDiscountToAllProducts(pct);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تطبيق خصم $pct% على المنتجات')),
                  );
                }
              }
            },
            child: const Text('تطبيق الخصم'),
          ),
        ],
      ),
    );
  }

  void _showAddEditProductModal(BuildContext context, AdminProvider admin,
      {Product? product}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final priceCtrl = TextEditingController(
        text: product?.price != null ? product!.price.toStringAsFixed(0) : '');
    final imgCtrl = TextEditingController(text: product?.image ?? '');

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
                product == null ? 'إضافة منتج جديد' : 'تعديل المنتج',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: AppConstants.darkBorder, height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المنتج *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر (ج.م) *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'وصف المنتج'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imgCtrl,
                decoration: const InputDecoration(
                    labelText: 'رابط صورة المنتج (URL اختياري)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                  if (name.isEmpty || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('يرجى إدخال اسم وسعر صحيحين')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await admin.saveProduct(
                    id: product?.id,
                    name: name,
                    description: descCtrl.text.trim(),
                    price: price,
                    image: imgCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ المنتج بنجاح')),
                    );
                  }
                },
                child: const Text('حفظ المنتج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
