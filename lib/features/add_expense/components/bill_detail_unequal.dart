import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'summary_bill_screen.dart';
import '../bill_controller.dart';
import '../../../data/models/bills_model.dart';
import '../../../features/auth/auth_controller.dart';
import 'bill_detail_equal.dart';
import '../../../data/models/workspace_model.dart';
import 'dart:convert';

class BillItem {
  String name;
  double amount;
  List<MemberShare> selectedMembers;

  BillItem({
    required this.name,
    required this.amount,
    required this.selectedMembers,
  });
}

class BillDetailUnequalScreen extends ConsumerStatefulWidget {
  final List<WorkspaceMemberModel> allMembers;
  final String tripName;
  final String createdBy;
  final double totalAmount;
  final String note;
  final String payeeName;
  final String payeePromptPay;
  final String workspaceId;

  const BillDetailUnequalScreen({
    super.key,
    required this.allMembers,
    required this.tripName,
    required this.createdBy,
    required this.totalAmount,
    required this.note,
    required this.payeeName,
    required this.payeePromptPay,
    required this.workspaceId,
  });

  @override
  ConsumerState<BillDetailUnequalScreen> createState() =>
      _BillDetailUnequalScreenState();
}

class _BillDetailUnequalScreenState
    extends ConsumerState<BillDetailUnequalScreen> {
  List<BillItem> billItems = [];
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(text: widget.tripName);
  }

  void addBillItem() {
    setState(() {
      billItems.add(BillItem(name: "", amount: 0.0, selectedMembers: []));
    });
  }

  void removeBillItem(int index) {
    setState(() {
      billItems.removeAt(index);
    });
  }

  void toggleMember(int billIndex, MemberShare member) {
    debugPrint('=== DEBUG MEMBER SELECTION ===');
    debugPrint('Selected members:');
    for (var m in billItems[billIndex].selectedMembers) {
      debugPrint('- ${m.memberName} (${m.memberId})');
    }
    debugPrint('Workspace members:');
    for (var m in widget.allMembers) {
      debugPrint('- ${m.user.name} (${m.user.id})');
    }
    debugPrint('===========================');

    setState(() {
      final selected = billItems[billIndex].selectedMembers;
      if (selected.any((m) => m.memberId == member.memberId)) {
        selected.removeWhere((m) => m.memberId == member.memberId);
      } else {
        selected.add(member);
      }
    });
  }

  double get totalAmount =>
      billItems.fold(0.0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6D8E8C),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("บิล", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: billItems.length,
                        itemBuilder: (context, index) {
                          final item = billItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          decoration: InputDecoration(
                                            hintText: 'ชื่อรายการ',
                                            hintStyle: TextStyle(
                                                color: Colors.grey.shade400),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF638889),
                                                  width: 2),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14),
                                          ),
                                          onChanged: (value) =>
                                              item.name = value,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: 'จำนวนเงิน',
                                            hintStyle: TextStyle(
                                                color: Colors.grey.shade400),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: Colors.grey.shade300),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF638889),
                                                  width: 2),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14),
                                            prefixText: '฿ ',
                                          ),
                                          onChanged: (value) => item.amount =
                                              double.tryParse(value) ?? 0.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => removeBillItem(index),
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.red.withOpacity(0.1),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (item.selectedMembers.isNotEmpty) ...[
                                    const Text(
                                      'สมาชิกที่เลือก',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ...item.selectedMembers.map((m) => Chip(
                                            label: Text(
                                              m.memberName,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                            backgroundColor:
                                                const Color(0xFF638889),
                                            deleteIcon: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            onDeleted: () =>
                                                toggleMember(index, m),
                                          )),
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: PopupMenuButton<MemberShare>(
                                          icon: const Icon(
                                            Icons.add,
                                            size: 20,
                                            color: Colors.orange,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          itemBuilder: (context) {
                                            return widget.allMembers
                                                .where((m) => !item
                                                    .selectedMembers
                                                    .any((mm) =>
                                                        mm.memberId ==
                                                        m.user.id))
                                                .map((m) => PopupMenuItem(
                                                    value: MemberShare(
                                                        memberId: m.user.id,
                                                        memberName: m.user.name,
                                                        amount: 0),
                                                    child: Text(m.user.name)))
                                                .toList();
                                          },
                                          onSelected: (m) =>
                                              toggleMember(index, m),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total",
                            style: TextStyle(color: Colors.grey)),
                        Text("${totalAmount.toStringAsFixed(0)} บาท",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text("Note", style: TextStyle(color: Colors.grey)),
                    TextField(controller: noteController),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white),
                          child: const Text("ยกเลิก",
                              style: TextStyle(color: Colors.black)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final authState = ref.read(authControllerProvider);
                            final currentUser = authState.value;

                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('กรุณาเข้าสู่ระบบก่อน')),
                              );
                              return;
                            }

                            debugPrint(
                                'DEBUG: billItems count = \\${billItems.length}');
                            for (var i = 0; i < billItems.length; i++) {
                              debugPrint(
                                  'DEBUG: billItem[[33m$i[0m] name = \\${billItems[i].name}, amount = \\${billItems[i].amount}, selectedMembers = \\${billItems[i].selectedMembers.map((m) => m.memberId).join(", ")}');
                            }

                            final items = billItems
                                .where((item) =>
                                    item.name.isNotEmpty &&
                                    item.amount > 0 &&
                                    item.selectedMembers.isNotEmpty)
                                .map((item) {
                              final perUser =
                                  item.amount / item.selectedMembers.length;
                              return Item(
                                description: item.name,
                                amount: item.amount,
                                sharedWith: item.selectedMembers.map((member) {
                                  final workspaceMember =
                                      widget.allMembers.firstWhere(
                                    (m) => m.user.id == member.memberId,
                                    orElse: () => throw Exception(
                                        'Member ${member.memberName} is not in workspace'),
                                  );
                                  return SharedWith(
                                    user: workspaceMember.user.id,
                                    name: workspaceMember.user.name,
                                    status: 'pending',
                                    shareAmount: perUser,
                                    roundPayments: [],
                                  );
                                }).toList(),
                              );
                            }).toList();

                            debugPrint('DEBUG: JSON to send: ' +
                                jsonEncode({
                                  "items":
                                      items.map((e) => e.toJson()).toList(),
                                  // เพิ่ม field อื่นๆ ที่จะส่ง
                                }));

                            try {
                              final logger = Logger();
                              logger.d('Starting bill creation...');
                              final bill = await ref
                                  .read(billListProvider(widget.workspaceId)
                                      .notifier)
                                  .create(
                                    paymentType: 'normal',
                                    items: items,
                                    note: noteController.text.isEmpty
                                        ? widget.tripName
                                        : noteController.text,
                                    roundDetails: RoundDetails(
                                      dueDate: DateTime.now()
                                          .add(const Duration(days: 7)),
                                      totalPeriod: 1,
                                      currentRound: 1,
                                    ),
                                  );

                              logger.d('Bill created: ${bill?.toJson()}');

                              if (context.mounted && bill != null) {
                                logger
                                    .d('Bill is not null, processing data...');
                                final creator = bill.creator.first;
                                logger.d('Creator data: ${creator.toJson()}');

                                final Map<String, List<Map<String, dynamic>>>
                                    itemsByMember = {};

                                logger.d('Processing items...');
                                for (var item in bill.items) {
                                  logger.d('Item: ${item.toJson()}');
                                  for (var shared in item.sharedWith) {
                                    logger.d('SharedWith: ${shared.toJson()}');
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
                                logger.d('Final itemsByMember: $itemsByMember');

                                logger.d(
                                    'Navigating to SummaryBillScreen with data:');
                                logger.d('- tripName: ${widget.tripName}');
                                logger.d('- createdBy: ${creator.name}');
                                logger.d('- createdAt: ${bill.createdAt}');
                                logger.d('- totalAmount: $totalAmount');
                                logger.d('- note: ${bill.note}');
                                logger.d('- payeeName: ${creator.name}');
                                logger.d(
                                    '- payeePromptPay: ${creator.numberAccount}');
                                logger
                                    .d('- workspaceId: ${widget.workspaceId}');

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SummaryBillScreen(
                                      tripName: widget.tripName,
                                      createdBy: creator.name,
                                      createdAt: bill.createdAt,
                                      itemsByMember: itemsByMember,
                                      totalAmount: totalAmount,
                                      note: bill.note,
                                      payeeName: creator.name,
                                      payeePromptPay: creator.numberAccount,
                                      workspaceId: widget.workspaceId,
                                      billId: bill.id,
                                    ),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('บันทึกบิลสำเร็จ')),
                                );
                              } else {
                                logger.e('Bill is null or context not mounted');
                                logger.e('Bill: $bill');
                                logger.e('Context mounted: ${context.mounted}');
                              }
                            } catch (e, stackTrace) {
                              final logger = Logger();
                              logger.e('Error occurred: $e');
                              logger.e('Stack trace: $stackTrace');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text("สรุปบิล"),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A6D8C)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addBillItem,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('กลุ่ม', style: TextStyle(color: Colors.white70)),
          Text(widget.tripName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('สร้างโดย ${widget.createdBy}',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }
}
