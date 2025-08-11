import 'package:flutter/material.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/data/models/bills_model.dart';
import '../../add_expense/components/summary_bill_screen.dart';
import 'package:fintrack/features/add_expense/service/bill_service.dart';

class AllBillsScreen extends StatefulWidget {
  final WorkspaceModel workspace;

  const AllBillsScreen({super.key, required this.workspace});

  @override
  State<AllBillsScreen> createState() => _AllBillsScreenState();
}

class _AllBillsScreenState extends State<AllBillsScreen> {
  String filter = 'all';
  late Future<List<Bill>> _billsFuture;

  @override
  void initState() {
    super.initState();
    _billsFuture = BillService().fetchBills(workspaceId: widget.workspace.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title:
            const Text('ดูบิลทั้งหมด', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Bill>>(
        future: _billsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: \\${snapshot.error}'));
          }
          List<Bill> bills = snapshot.data ?? [];
          if (filter == 'paid') {
            bills = bills.where((b) => b.status == 'paid').toList();
          } else if (filter == 'unpaid') {
            bills = bills.where((b) => b.status != 'paid').toList();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterTab('all', 'ทั้งหมด'),
                    _buildFilterTab('paid', 'บิลที่สำเร็จแล้ว'),
                    _buildFilterTab('unpaid', 'บิลที่ยังคงค้าง'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: bills.isEmpty
                    ? const Center(child: Text('ไม่พบบิลในกลุ่มนี้'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: bills.length,
                        itemBuilder: (context, index) {
                          final bill = bills[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(bill.note,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        '${bill.items.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(0)} บาท',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    'สร้างโดย ${bill.creator.isNotEmpty ? bill.creator.first.name : '-'}',
                                    style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 12),
                                ...bill.items
                                    .expand((item) => item.sharedWith)
                                    .map((shared) {
                                  final isPaid = shared.status == 'paid';
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(shared.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isPaid
                                                    ? Colors.black54
                                                    : Colors.black)),
                                        Row(
                                          children: [
                                            Text(
                                                '${shared.shareAmount.toStringAsFixed(0)} บาท'),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isPaid
                                                    ? Colors.blue.shade100
                                                    : Colors.red.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isPaid
                                                    ? 'จ่ายแล้ว'
                                                    : 'ยังไม่ได้จ่าย',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isPaid
                                                      ? Colors.blue.shade900
                                                      : Colors.red.shade900,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                // แสดงรายละเอียดการจ่ายแบบรอบ (ถ้ามี)
                                if (bill.roundDetails != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'การจ่ายแบบรอบ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            Text(
                                              'รอบที่ ${bill.roundDetails!.currentRound}/${bill.roundDetails!.totalPeriod}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ครบกำหนด: ${bill.roundDetails!.dueDate.day}/${bill.roundDetails!.dueDate.month}/${bill.roundDetails!.dueDate.year}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text('Note: ${bill.note}',
                                    style:
                                        const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      // สร้าง itemsByMember map
                                      final Map<String,
                                              List<Map<String, dynamic>>>
                                          itemsByMember = {};
                                      for (var item in bill.items) {
                                        for (var shared in item.sharedWith) {
                                          if (!itemsByMember
                                              .containsKey(shared.name)) {
                                            itemsByMember[shared.name] = [];
                                          }
                                          itemsByMember[shared.name]!.add({
                                            'name': item.description,
                                            'amount': shared.shareAmount,
                                          });
                                        }
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SummaryBillScreen(
                                            tripName: widget.workspace.name,
                                            createdBy: bill.creator.isNotEmpty
                                                ? bill.creator.first.name
                                                : '-',
                                            createdAt: bill.createdAt,
                                            itemsByMember: itemsByMember,
                                            totalAmount: bill.items.fold(
                                                0.0,
                                                (sum, item) =>
                                                    sum + item.amount),
                                            note: bill.note,
                                            payeeName: bill.creator.isNotEmpty
                                                ? bill.creator.first.name
                                                : '-',
                                            payeePromptPay:
                                                bill.creator.isNotEmpty
                                                    ? bill.creator.first
                                                        .numberAccount
                                                    : '',
                                            workspaceId: bill.workspace,
                                            billId: bill.id,
                                            roundDetails: bill.roundDetails,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('รายละเอียดบิล'),
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
