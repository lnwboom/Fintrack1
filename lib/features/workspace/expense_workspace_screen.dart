import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/auth/auth_controller.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/data/models/bills_model.dart';
import 'components/all_bills_screen.dart';
import '../add_expense/components/bill_detail_round_screen.dart';
import '../add_expense/components/bill_sheet.dart';
import 'components/edit_bill_payment_screen.dart';
import 'package:fintrack/features/add_expense/service/bill_service.dart';
import 'package:fintrack/features/add_expense/bill_controller.dart';

class ExpenseWorkspaceScreen extends ConsumerWidget {
  final WorkspaceModel workspace;

  const ExpenseWorkspaceScreen({Key? key, required this.workspace})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final bills = ref.watch(billListProvider(workspace.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638889),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(
              workspace.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${workspace.members.length} สมาชิก',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryCard(bills),
          Expanded(
            child: bills.when(
              data: (bills) {
                bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    final isCurrentUser = bill.creator.isNotEmpty &&
                        bill.creator.first.userId == user?.id;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditBillPaymentScreen(bill: bill),
                          ),
                        );
                      },
                      child: _buildBillCard(bill, isCurrentUser),
                    );
                  },
                );
              },
              error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllBillsScreen(workspace: workspace),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt),
                  label: const Text('ดูบิลทั้งหมด'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A6D8C),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showBillSheet(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('สร้างบิลใหม่'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF638889),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillCard(Bill bill, bool isCurrentUser) {
    final Map<String, double> userTotals = {};
    final Map<String, String> userNames = {};

    for (final item in bill.items) {
      for (final shared in item.sharedWith) {
        userTotals[shared.name] =
            (userTotals[shared.name] ?? 0) + shared.shareAmount;
        userNames[shared.name] = shared.name;
      }
    }

    final workspaceId = bill.workspace is String
        ? bill.workspace
        : (bill.workspace is Map
            ? bill.workspace['_id']?.toString() ?? ''
            : '');

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 280,
        ),
        margin: EdgeInsets.only(
          bottom: 16,
          left: isCurrentUser ? 64 : 0,
          right: isCurrentUser ? 0 : 64,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFF3A6D8C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bill.note,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${bill.items.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(0)} บาท',
              style: TextStyle(
                fontSize: 14,
                color: isCurrentUser ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            ...userTotals.entries.map((entry) {
              final name = entry.key;
              final total = entry.value;
              SharedWith? shared;
              try {
                shared = bill.items
                    .expand((item) => item.sharedWith)
                    .firstWhere((s) => s.name == name);
              } catch (e) {
                shared = null;
              }
              String userId = '';
              if (shared?.user is String) {
                userId = shared!.user;
              } else if (shared?.user is Map && shared!.user['_id'] != null) {
                userId = shared!.user['_id'];
              } else if (shared?.user is Map && shared!.user['\$oid'] != null) {
                userId = shared!.user['\$oid'];
              }

              final status = shared?.status ?? 'pending';
              Color badgeColor;
              String statusText;
              switch (status) {
                case 'paid':
                  badgeColor = Colors.green;
                  statusText = 'จ่ายแล้ว';
                  break;
                case 'awaiting_confirmation':
                  badgeColor = Colors.orange;
                  statusText = 'รอยืนยัน';
                  break;
                case 'canceled':
                  badgeColor = Colors.grey;
                  statusText = 'ยกเลิก';
                  break;
                default:
                  badgeColor = Colors.red;
                  statusText = 'ยังไม่ได้จ่าย';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCurrentUser ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${total.toStringAsFixed(0)} บาท',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isCurrentUser ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showBillSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BillSheet(
          workspaces: [workspace],
          selectedWorkspace: workspace,
          amountController: TextEditingController(),
          isEvenSplit: true,
          onSplitToggle: (value) {},
          onWorkspaceSelected: (workspace) {},
        ),
      ),
    );
  }

  Widget _buildSummaryCard(AsyncValue<List<Bill>> bills) {
    return bills.when(
      data: (bills) {
        bills.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final int paidCount = bills.where((b) => b.status == 'paid').length;
        final int canceledCount =
            bills.where((b) => b.status == 'canceled').length;
        final int awaitingCount = bills
            .where((b) =>
                b.status == 'pending' &&
                b.items.any((item) => item.sharedWith
                    .any((sw) => sw.status == 'awaiting_confirmation')))
            .length;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'สรุปบิล',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF638889),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF638889).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ทั้งหมด ${bills.length} บิล',
                      style: const TextStyle(
                        color: Color(0xFF638889),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem('สำเร็จ', '$paidCount', Icons.check_circle),
                  _buildSummaryItem(
                      'รอยืนยัน', '$awaitingCount', Icons.hourglass_empty),
                  _buildSummaryItem('ยกเลิก', '$canceledCount', Icons.cancel),
                ],
              ),
            ],
          ),
        );
      },
      error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF638889).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF638889), size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF638889),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF638889),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สมาชิก',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...workspace.members.map((member) {
          final String initial = member.user.name.isNotEmpty
              ? member.user.name[0].toUpperCase()
              : '#';
          return ListTile(
            leading: CircleAvatar(
              child: Text(initial),
            ),
            title: Text(member.user.name.isNotEmpty ? member.user.name : 'N/A'),
            subtitle:
                Text(member.user.email.isNotEmpty ? member.user.email : 'N/A'),
            trailing: Text(
              'เข้าร่วมเมื่อ ${_formatDate(member.joinAt)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
