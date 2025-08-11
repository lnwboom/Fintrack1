import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fintrack/data/models/transaction_model.dart';

class ExpensePieChart extends StatelessWidget {
  final List<TransactionModel> data;

  const ExpensePieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categorySums = {};
    double totalAmount = 0;

    for (var tx in data) {
      double amount = tx.amount;
      categorySums[tx.category] = (categorySums[tx.category] ?? 0) + amount;
      totalAmount += amount;
    }

    final filteredEntries =
        categorySums.entries.where((e) => e.value > 0).toList();
    final colors = _generateColors(filteredEntries.length);
    final List<PieChartSectionData> sections = [];

    for (int i = 0; i < filteredEntries.length; i++) {
      final entry = filteredEntries[i];
      final percent = totalAmount > 0 ? (entry.value / totalAmount) * 100 : 0;
      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${entry.key} ${percent.toStringAsFixed(1)}%',
          titlePositionPercentageOffset: 1.2,
          showTitle: true,
          radius: 70,
          color: colors[i],
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สัดส่วนรายจ่ายแต่ละหมวด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 3,
                    borderData: FlBorderData(show: false),
                    startDegreeOffset: -90,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'รวมทั้งหมด: ${totalAmount.toStringAsFixed(2)} บาท',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _generateColors(int count) {
    final random = Random();
    return List.generate(count, (_) {
      return Color.fromARGB(
        255,
        100 + random.nextInt(155),
        100 + random.nextInt(155),
        100 + random.nextInt(155),
      );
    });
  }
}
