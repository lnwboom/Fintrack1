import 'package:flutter/material.dart';
import 'package:fintrack/data/models/transaction_model.dart';

class TransactionListByCategory extends StatelessWidget {
  final List<TransactionModel> data;

  const TransactionListByCategory({required this.data});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TransactionModel>>{};
    for (var tx in data) {
      grouped.putIfAbsent(tx.category, () => []).add(tx);
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: grouped.entries.map((entry) {
        final total = entry.value.fold<double>(
          0.0,
          (sum, tx) => sum + tx.amount,
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${entry.key} (${entry.value.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${total.toStringAsFixed(2)} ฿',
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.w500)),
              ],
            ),
            children: entry.value.map(_buildTransactionItem).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tx.type == 'Income'
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: tx.type == 'Income' ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.category,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(tx.description ?? '-',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${tx.amount.toStringAsFixed(2)} บาท',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(
                    '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
      ],
    );
  }
}
