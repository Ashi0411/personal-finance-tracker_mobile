import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import 'category_icon_helper.dart';
import 'custom_text_field.dart';

class CategoryManagementDialog extends StatefulWidget {
  const CategoryManagementDialog({super.key});

  @override
  State<CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<CategoryManagementDialog> with SingleTickerProviderStateMixin {
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

  void _openAddEditDialog([CategoryModel? categoryToEdit, String defaultType = 'expense']) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    String type = categoryToEdit?.type ?? defaultType;
    String selectedIcon = categoryToEdit?.icon ?? (type == 'income' ? 'briefcase' : 'utensils');
    String selectedColor = categoryToEdit?.color ?? (type == 'income' ? '#0284C7' : '#EF4444');

    final availableIcons = [
      'briefcase', 'trending-up', 'laptop', 'gift', 'zap', 'utensils', 'car',
      'home', 'shopping-bag', 'film', 'heart', 'book', 'shield', 'plane', 'coffee', 'target'
    ];

    final availableColors = [
      '#EF4444', '#F43F5E', '#EC4899', '#8B5CF6', '#6366F1', '#3B82F6',
      '#0284C7', '#06B6D4', '#14B8A6', '#10B981', '#F59E0B', '#F97316'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                categoryToEdit == null ? 'Add New Category' : 'Edit Category',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Toggle
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Expense')),
                              selected: type == 'expense',
                              selectedColor: AppColors.expense,
                              labelStyle: TextStyle(
                                color: type == 'expense' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() {
                                    type = 'expense';
                                    if (selectedColor == '#0284C7') selectedColor = '#EF4444';
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Income')),
                              selected: type == 'income',
                              selectedColor: AppColors.income,
                              labelStyle: TextStyle(
                                color: type == 'income' ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w700,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setDialogState(() {
                                    type = 'income';
                                    if (selectedColor == '#EF4444') selectedColor = '#0284C7';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: nameController,
                        label: 'Category Name',
                        hint: 'e.g. Groceries or Freelance',
                        validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableIcons.map((ic) {
                          final isSel = selectedIcon == ic;
                          final currentColor = CategoryIconHelper.parseColor(selectedColor);
                          return InkWell(
                            onTap: () => setDialogState(() => selectedIcon = ic),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSel ? currentColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                                border: Border.all(color: isSel ? currentColor : Colors.transparent, width: 2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CategoryIconHelper.getIcon(ic),
                                size: 20,
                                color: isSel ? currentColor : Colors.grey.shade700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableColors.map((hex) {
                          final isSel = selectedColor == hex;
                          final color = CategoryIconHelper.parseColor(hex);
                          return InkWell(
                            onTap: () => setDialogState(() => selectedColor = hex),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSel ? Border.all(color: Colors.black87, width: 3) : null,
                              ),
                              child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

                    if (categoryToEdit == null) {
                      await txProvider.addCategory(
                        name: nameController.text.trim(),
                        type: type,
                        icon: selectedIcon,
                        color: selectedColor,
                      );
                    } else {
                      await txProvider.updateCategory(
                        id: categoryToEdit.id,
                        name: nameController.text.trim(),
                        type: type,
                        icon: selectedIcon,
                        color: selectedColor,
                      );
                    }
                    if (context.mounted) {
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(categoryToEdit == null ? 'Category added!' : 'Category updated!'),
                          backgroundColor: AppColors.income,
                        ),
                      );
                    }
                  },
                  child: Text(categoryToEdit == null ? 'Add Category' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = Provider.of<TransactionProvider>(context);

    final expenseCategories = txProvider.categories.where((c) => c.type == 'expense').toList();
    final incomeCategories = txProvider.categories.where((c) => c.type == 'income').toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.category_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Manage Categories',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Tabs Segmented Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D6366F1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(height: 38, text: 'Expenses'),
                  Tab(height: 38, text: 'Income'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Categories List
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(expenseCategories, 'expense', isDark),
                  _buildCategoryList(incomeCategories, 'income', isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openAddEditDialog(
                  null,
                  _tabController.index == 0 ? 'expense' : 'income',
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add New Category', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, String type, bool isDark) {
    if (categories.isEmpty) {
      return Center(
        child: Text('No $type categories yet. Tap Add New Category to create!'),
      );
    }

    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = CategoryIconHelper.parseColor(cat.color);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(CategoryIconHelper.getIcon(cat.icon), color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cat.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openAddEditDialog(cat, type),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Category'),
                      content: Text('Are you sure you want to delete "${cat.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await txProvider.deleteCategory(cat.id);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
