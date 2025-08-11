import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/auth/auth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'components/profile_screen.dart';
import 'package:fintrack/features/home/transaction_controller.dart';
import 'package:fintrack/data/models/transaction_model.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF638889),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            _buildImagePickerCard(context),
            _buildTransactionSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    debugPrint('Current user: ${user?.name}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              Text(
                user?.name ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF72c7cc),
                borderRadius: BorderRadius.circular(10.77),
              ),
              child: Center(
                child: Text(
                  user != null && user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 48,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF9F9F9), width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'เลือกภาพจากแกลเลอรี',
            style: TextStyle(
              color: Color(0xFF3A3451),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _pickImage(context),
            child: const Text('เลือกภาพGGGG'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF638889),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(transactionListProvider);

    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(transactionState),
            const SizedBox(height: 20),
            Text(
              'Transaction History',
              style: TextStyle(
                color: const Color(0xFF080422).withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactionState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
                data: (transactions) => ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildTransactionItem(transactions[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.category,
                        style: const TextStyle(
                          color: Color(0xFF080422),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        tx.description ?? '-',
                        style: TextStyle(
                          color: const Color(0xFF080422).withOpacity(0.5),
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.amount.toStringAsFixed(2)} บาท',
                style: const TextStyle(
                  color: Color(0xFF080422),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (tx.createdAt != null)
                Text(
                  '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                  style: TextStyle(
                    color: const Color(0xFF080422).withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      AsyncValue<List<TransactionModel>> transactionState) {
    double earned = 0;
    double spent = 0;

    transactionState.whenData((transactions) {
      for (var tx in transactions) {
        if (tx.type == 'Income') {
          earned += tx.amount;
        } else {
          spent += tx.amount;
        }
      }
    });

    return Container(
      width: double.infinity,
      height: 83,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.11),
            offset: const Offset(0, 10),
            blurRadius: 50,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBalanceColumn(
              'Earned', earned.toStringAsFixed(2), const Color(0xFF086F3E)),
          _buildBalanceColumn(
              'Spent', spent.toStringAsFixed(2), const Color(0xFFFF7171)),
        ],
      ),
    );
  }

  Widget _buildBalanceColumn(String title, String amount, Color amountColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF080422).withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    // Implementation of _pickImage method
  }
}
