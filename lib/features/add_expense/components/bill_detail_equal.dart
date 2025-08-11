import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bill_detail_unequal.dart';
import 'summary_bill_screen.dart';
import '../bill_controller.dart';
import '../../../data/models/bills_model.dart';
import '../../../features/auth/auth_controller.dart';
import '../../../data/models/workspace_model.dart';

class MemberShare {
  final String memberId;
  final String memberName;
  final double amount;

  MemberShare(
      {required this.memberId, required this.memberName, required this.amount});
}

class BillDetailScreen extends ConsumerStatefulWidget {
  final bool isEvenSplit;
  final double totalAmount;
  final List<MemberShare> memberShares;
  final String billName;
  final List<String> allMembers;
  final String workspaceId;
  final WorkspaceModel selectedWorkspace;

  BillDetailScreen({
    Key? key,
    required this.isEvenSplit,
    required this.totalAmount,
    required this.memberShares,
    required this.billName,
    required this.allMembers,
    required this.workspaceId,
    required this.selectedWorkspace,
  }) : super(key: key);

  @override
  ConsumerState<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  late List<TextEditingController> _controllers;
  late List<MemberShare> _shares;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    _shares = widget.memberShares
        .map((m) => MemberShare(
            memberId: m.memberId, memberName: m.memberName, amount: m.amount))
        .toList();
    _controllers = _shares
        .map((m) => TextEditingController(text: m.amount.toStringAsFixed(0)))
        .toList();
    noteController = TextEditingController(text: widget.billName);
  }

  void _onAmountChanged(int index, String value) {
    double newValue = double.tryParse(value) ?? 0.0;
    // จำกัดไม่ให้ติดลบ
    if (newValue < 0) newValue = 0;
    _shares[index] = MemberShare(
      memberId: _shares[index].memberId,
      memberName: _shares[index].memberName,
      amount: newValue,
    );
    // คำนวณผลรวมของสมาชิกอื่น
    double sumOthers = 0;
    for (int i = 0; i < _shares.length - 1; i++) {
      if (i != index) sumOthers += _shares[i].amount;
    }
    if (index != _shares.length - 1) {
      // ปรับยอดของสมาชิกคนสุดท้าย
      double lastAmount = widget.totalAmount -
          sumOthers -
          (index == _shares.length - 1 ? 0 : newValue);
      if (lastAmount < 0) lastAmount = 0;
      _shares[_shares.length - 1] = MemberShare(
        memberId: _shares.last.memberId,
        memberName: _shares.last.memberName,
        amount: lastAmount,
      );
      _controllers[_shares.length - 1].text = lastAmount.toStringAsFixed(0);
    }
    setState(() {});
  }

  double get _sumAmount => _shares.fold(0.0, (sum, m) => sum + m.amount);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.value;

    if (!widget.isEvenSplit) {
      return BillDetailUnequalScreen(
        allMembers: widget.selectedWorkspace.members,
        tripName: widget.billName,
        createdBy: 'คุณ',
        totalAmount: widget.totalAmount,
        note: 'ค่าอาหารเมื่อวาน',
        payeeName: 'นายXXX',
        payeePromptPay: 'XXX XXX XXXX',
        workspaceId: widget.workspaceId,
      );
    }

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
                    const Text('บิล',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(
                            child: Text('รายชื่อ',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        Text('จำนวนเงิน',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _shares.length,
                        itemBuilder: (context, index) {
                          final member = _shares[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.green[300],
                                  child: Text(
                                      member.memberName[0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(member.memberName)),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        hintText: 'จำนวน'),
                                    controller: _controllers[index],
                                    onChanged: (value) =>
                                        _onAmountChanged(index, value),
                                    enabled: index !=
                                        _shares.length -
                                            1, // แก้ไขได้ทุกคนยกเว้นคนสุดท้าย
                                  ),
                                ),
                                if (index != _shares.length - 1)
                                  const SizedBox(width: 8),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                        'รวม: ${_sumAmount.toStringAsFixed(0)} / ${widget.totalAmount.toStringAsFixed(0)} บาท',
                        style: TextStyle(
                          color: _sumAmount == widget.totalAmount
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        )),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'หมายเหตุ',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _button(context, 'ยกเลิก', () => Navigator.pop(context),
                            filled: false),
                        _button(context, 'สรุปบิล', () async {
                          final authState = ref.read(authControllerProvider);
                          final currentUser = authState.value;
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('กรุณาเข้าสู่ระบบก่อน')),
                            );
                            return;
                          }
                          final items = [
                            Item(
                              description: 'หารทั้งหมด',
                              amount: widget.totalAmount,
                              sharedWith: _shares
                                  .map((member) => SharedWith(
                                        user: member.memberId,
                                        name: member.memberName,
                                        status: 'pending',
                                        shareAmount: member.amount,
                                        roundPayments: [],
                                      ))
                                  .toList(),
                            )
                          ];
                          try {
                            debugPrint('Starting bill creation...');
                            final bill = await ref
                                .read(billListProvider(widget.workspaceId)
                                    .notifier)
                                .create(
                                  paymentType: 'normal',
                                  items: items,
                                  note: noteController.text.isEmpty
                                      ? widget.billName
                                      : noteController.text,
                                  roundDetails: RoundDetails(
                                    dueDate: DateTime.now()
                                        .add(const Duration(days: 7)),
                                    totalPeriod: 1,
                                    currentRound: 1,
                                  ),
                                );
                            debugPrint('Bill created: \\${bill?.toJson()}');
                            if (context.mounted && bill != null) {
                              debugPrint(
                                  'Bill is not null, processing data...');
                              final creator = bill.creator.first;
                              debugPrint('Creator data: \\${creator.toJson()}');
                              final Map<String, List<Map<String, dynamic>>>
                                  itemsByMember = {};
                              debugPrint('Processing items...');
                              for (var item in bill.items) {
                                debugPrint('Item: \\${item.toJson()}');
                                for (var shared in item.sharedWith) {
                                  debugPrint(
                                      'SharedWith: \\${shared.toJson()}');
                                  if (!itemsByMember.containsKey(shared.name)) {
                                    itemsByMember[shared.name] = [];
                                  }
                                  itemsByMember[shared.name]!.add({
                                    'name': item.description,
                                    'amount': shared.shareAmount,
                                  });
                                }
                              }
                              debugPrint('Final itemsByMember: $itemsByMember');
                              debugPrint(
                                  'Navigating to SummaryBillScreen with data:');
                              debugPrint('- tripName: ${widget.billName}');
                              debugPrint('- createdBy: ${creator.name}');
                              debugPrint('- createdAt: ${bill.createdAt}');
                              debugPrint(
                                  '- totalAmount: ${widget.totalAmount}');
                              debugPrint('- note: ${bill.note}');
                              debugPrint('- payeeName: ${creator.name}');
                              debugPrint(
                                  '- payeePromptPay: ${creator.numberAccount}');
                              debugPrint(
                                  '- workspaceId: ${widget.workspaceId}');
                              debugPrint(creator.toJson().toString());
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SummaryBillScreen(
                                    tripName: widget.billName,
                                    createdBy: creator.name,
                                    createdAt: bill.createdAt,
                                    itemsByMember: itemsByMember,
                                    totalAmount: widget.totalAmount,
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
                              debugPrint('Bill is null or context not mounted');
                              debugPrint('Bill: $bill');
                              debugPrint('Context mounted: ${context.mounted}');
                            }
                          } catch (e, stackTrace) {
                            debugPrint('Error occurred: $e');
                            debugPrint('Stack trace: $stackTrace');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                            }
                          }
                        }, icon: Icons.arrow_forward),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
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
          Text(widget.selectedWorkspace.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.billName,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 4),
          Text('฿${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.savings,
                size: 72, color: Colors.white.withOpacity(0.5)),
          )
        ],
      ),
    );
  }

  Widget _button(BuildContext context, String label, VoidCallback onTap,
      {bool filled = true, IconData? icon}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon ?? Icons.cancel,
          color: filled ? Colors.white : Colors.black),
      label: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? const Color(0xFF3A6D8C) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: filled
              ? BorderSide.none
              : const BorderSide(color: Colors.black12),
        ),
      ),
    );
  }
}
