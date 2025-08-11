import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final String selectedType;
  final void Function(String) onTypeChanged;
  final String selectedCategory;
  final List<String> categories;
  final void Function(String) onCategoryChanged;

  const FilterBar({
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeOptions = ['All', 'Income', 'Expense'];
    final typeIcons = {
      'All': Icons.list_alt,
      'Income': Icons.arrow_downward,
      'Expense': Icons.arrow_upward,
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'กรองข้อมูล',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: typeOptions.map((type) {
                final isSelected = selectedType == type;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcons[type],
                          size: 16,
                          color: isSelected ? Colors.white : Colors.teal),
                      const SizedBox(width: 4),
                      Text(type),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: Colors.teal,
                  backgroundColor: Colors.grey[200],
                  onSelected: (_) => onTypeChanged(type),
                  labelStyle:
                      TextStyle(color: isSelected ? Colors.white : Colors.teal),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.category, color: Colors.teal, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade100),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        items: categories
                            .map((cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onCategoryChanged(value);
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.teal),
                        isExpanded: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
