import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/home/transaction_controller.dart';

class XpenseForm extends ConsumerWidget {
  final TextEditingController amountController;
  final TextEditingController noteController;
  final String selectedType;
  final Function(String) onTypeSelected;
  final List<Map<String, String>> categories;
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;
  final VoidCallback onBillTap;
  final VoidCallback onSubmit;
  final VoidCallback onRequestBillTap;

  const XpenseForm({
    Key? key,
    required this.amountController,
    required this.noteController,
    required this.selectedType,
    required this.onTypeSelected,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onBillTap,
    required this.onRequestBillTap,
    required this.onSubmit,
  }) : super(key: key);

  /// A small helper to build the icon buttons in the form.
  Widget _buildIconButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense Type Selection
          const Text('ประเภทรายการ',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Income', 'Expenses'].map((type) {
              bool isSelected = type == selectedType;
              return GestureDetector(
                onTap: () => onTypeSelected(type),
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: isSelected ? Colors.white : Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(type,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Expense Details
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      DateTime.now().toString().substring(0, 16),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('จำนวนเงิน',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF638889),
                        value: categories
                                .any((c) => c['value'] == selectedCategory)
                            ? selectedCategory
                            : null,
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category['value'],
                            child: Text(
                              category['label'] ?? category['value']!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: onCategoryChanged,
                        iconEnabledColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: noteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Note :',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.8)),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIconButton(
                        Icons.download,
                        'สร้างบิล',
                        Colors.white,
                        onTap: onBillTap,
                      ),
                      _buildIconButton(
                        Icons.account_balance_wallet,
                        'เรียกเก็บเงิน',
                        Colors.white,
                        onTap: onRequestBillTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Submit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () async {
                  if (amountController.text.isEmpty ||
                      selectedCategory == 'หมวดหมู่') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
                    );
                    return;
                  }

                  try {
                    final amount = double.parse(amountController.text);
                    await ref.read(transactionListProvider.notifier).create(
                          type: selectedType,
                          amount: amount,
                          category: selectedCategory!,
                          description: noteController.text,
                        );

                    if (context.mounted) {
                      amountController.clear();
                      noteController.clear();
                      onTypeSelected('รายรับ');
                      onCategoryChanged('หมวดหมู่');

                      await ref
                          .read(transactionListProvider.notifier)
                          .refresh();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกรายการสำเร็จ')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                      );
                    }
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A6D8C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'บันทึก',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
