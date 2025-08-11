import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/transaction_controller.dart';
import 'components/expense_chart.dart';
import 'components/filter_bar.dart';
import 'components/transaction_list_grouped.dart';

class ExpenseReportScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ExpenseReportScreen> createState() =>
      _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  String selectedType = 'All';
  String selectedCategory = 'All';

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('รายงาน',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              Text('สรุปค่าใช้จ่าย',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.pie_chart, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF638889),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: transactionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
                  data: (transactions) {
                    // Filter
                    final filtered = transactions.where((tx) {
                      final matchType = selectedType == 'All' ||
                          (selectedType == 'Income' && tx.type == 'Income') ||
                          (selectedType == 'Expense' && tx.type == 'Expenses');
                      final matchCat = selectedCategory == 'All' ||
                          tx.category == selectedCategory;
                      return matchType && matchCat;
                    }).toList();

                    final categories = [
                      'All',
                      ...{...transactions.map((e) => e.category)}
                    ];

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(transactionListProvider.notifier).refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExpensePieChart(data: filtered),
                            const SizedBox(height: 16),
                            FilterBar(
                              selectedType: selectedType,
                              onTypeChanged: (type) =>
                                  setState(() => selectedType = type),
                              selectedCategory: selectedCategory,
                              categories: categories,
                              onCategoryChanged: (cat) =>
                                  setState(() => selectedCategory = cat),
                            ),
                            const SizedBox(height: 16),
                            TransactionListByCategory(data: filtered),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
