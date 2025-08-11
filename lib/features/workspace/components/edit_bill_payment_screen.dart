import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fintrack/data/models/bills_model.dart';
import 'package:fintrack/features/auth/auth_controller.dart';
import 'package:fintrack/features/add_expense/bill_controller.dart';

class EditBillPaymentScreen extends ConsumerStatefulWidget {
  final Bill bill;

  const EditBillPaymentScreen({Key? key, required this.bill}) : super(key: key);

  @override
  ConsumerState<EditBillPaymentScreen> createState() =>
      _EditBillPaymentScreenState();
}

class _EditBillPaymentScreenState extends ConsumerState<EditBillPaymentScreen> {
  final Map<String, File?> _slipImages = {};
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  // รวมยอดแต่ละ userId
  Map<String, double> _calculateMemberAmounts() {
    final Map<String, double> amounts = {};
    for (var item in widget.bill.items) {
      for (var shared in item.sharedWith) {
        amounts[shared.user] = (amounts[shared.user] ?? 0) + shared.shareAmount;
      }
    }
    return amounts;
  }

  // ดึง userId ทั้งหมด
  List<String> _getAllUserIds() {
    final Set<String> members = {};
    for (var item in widget.bill.items) {
      for (var shared in item.sharedWith) {
        members.add(shared.user);
      }
    }
    return members.toList();
  }

  // ดึง sharedWith ของ userId
  List<Map<String, dynamic>> _getSharedsByUserId(String userId) {
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < widget.bill.items.length; i++) {
      final item = widget.bill.items[i];
      for (var shared in item.sharedWith) {
        if (shared.user == userId) {
          result.add({'shared': shared, 'itemIndex': i});
        }
      }
    }
    return result;
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'ยังไม่ได้จ่าย';
      case 'awaiting_confirmation':
        return 'รอยืนยัน';
      case 'paid':
        return 'จ่ายแล้ว';
      case 'canceled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.red;
      case 'awaiting_confirmation':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAmounts = _calculateMemberAmounts();
    final allUserIds = _getAllUserIds();
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.value;
    final isOwner = widget.bill.creator.isNotEmpty &&
        widget.bill.creator.first.userId == currentUser?.id;

    final workspaceId = widget.bill.workspace;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('แก้ไขสถานะการจ่าย',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.bill.note,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                            'Total: ${widget.bill.items.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(0)} บาท',
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                            'Created by: ${widget.bill.creator.isNotEmpty ? widget.bill.creator.first.name : '-'}',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: allUserIds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final userId = allUserIds[index];
                      final shareds = _getSharedsByUserId(userId);
                      final name = shareds.isNotEmpty
                          ? shareds.first['shared'].name
                          : userId;
                      final amount = memberAmounts[userId] ?? 0.0;
                      // สถานะหลัก: ถ้ามี awaiting_confirmation > paid > pending > canceled
                      String status = 'pending';
                      if (shareds.any((s) =>
                          s['shared'].status == 'awaiting_confirmation')) {
                        status = 'awaiting_confirmation';
                      } else if (shareds
                          .any((s) => s['shared'].status == 'paid')) {
                        status = 'paid';
                      } else if (shareds
                          .any((s) => s['shared'].status == 'canceled')) {
                        status = 'canceled';
                      }
                      final isCurrentUser =
                          currentUser != null && currentUser.id == userId;
                      final slip = _slipImages[userId] ??
                          (shareds.isNotEmpty
                              ? shareds.first['shared'].eSlip
                              : null);

                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        leading:
                            CircleAvatar(child: Text(name[0].toUpperCase())),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${amount.toStringAsFixed(0)} บาท'),
                            Text(_statusText(status),
                                style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold)),
                            if (slip != null &&
                                slip is String &&
                                slip.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Image.network(slip),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        slip,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (slip != null && slip is File)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Image.file(slip),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        slip,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.bill.paymentType == 'round' &&
                                shareds.isNotEmpty) ...[
                              for (var shared in shareds)
                                if (shared['shared'].roundPayments != null &&
                                    shared['shared'].roundPayments!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('รายละเอียดการจ่ายแต่ละรอบ:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        ...shared['shared']
                                            .roundPayments!
                                            .map<Widget>((rp) => Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 2),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: rp.status == 'paid'
                                                        ? Colors.green[50]
                                                        : Colors.orange[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: rp.status == 'paid'
                                                          ? Colors.green
                                                          : Colors.orange,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text('รอบที่ ${rp.round}',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                          '${rp.amount.toStringAsFixed(0)} บาท'),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                          rp.status == 'paid'
                                                              ? 'จ่ายแล้ว'
                                                              : 'รอยืนยัน',
                                                          style: TextStyle(
                                                              color: rp.status ==
                                                                      'paid'
                                                                  ? Colors.green
                                                                  : Colors
                                                                      .orange)),
                                                      if (rp.paidDate != null)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0),
                                                          child: Text(
                                                              '(${rp.paidDate!.day}/${rp.paidDate!.month}/${rp.paidDate!.year})',
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey)),
                                                        ),
                                                      if (rp.eSlip != null &&
                                                          rp.eSlip!.isNotEmpty)
                                                        IconButton(
                                                          icon: const Icon(
                                                              Icons
                                                                  .receipt_long,
                                                              color:
                                                                  Colors.blue),
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (_) =>
                                                                  Dialog(
                                                                child: Image
                                                                    .network(rp
                                                                        .eSlip!),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                                )),
                                      ],
                                    ),
                                  ),
                            ],
                          ],
                        ),
                        trailing: Wrap(
                          direction: Axis.vertical,
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (isCurrentUser &&
                                (status == 'pending' || status == 'canceled'))
                              ElevatedButton(
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        final picked = await _picker.pickImage(
                                            source: ImageSource.gallery);
                                        if (picked != null) {
                                          setState(() => _loading = true);
                                          final bytes = await File(picked.path)
                                              .readAsBytes();
                                          final itemIds = shareds
                                              .map((s) =>
                                                  widget.bill
                                                      .items[s['itemIndex']].id
                                                      ?.toString() ??
                                                  '')
                                              .toList();
                                          try {
                                            await ref
                                                .read(billListProvider(
                                                        workspaceId)
                                                    .notifier)
                                                .submitPayment(
                                                  billId: widget.bill.id,
                                                  itemIds: itemIds,
                                                  slipImageBytes: bytes,
                                                  slipImageName: picked.name,
                                                );
                                            ref.refresh(
                                                billListProvider(workspaceId));
                                            Navigator.pop(context);
                                            setState(() {
                                              _slipImages[userId] =
                                                  File(picked.path);
                                            });
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'เกิดข้อผิดพลาด: $e')));
                                          } finally {
                                            setState(() => _loading = false);
                                          }
                                        }
                                      },
                                child: const Text('แนบสลิป'),
                              ),
                            if (isOwner && status == 'awaiting_confirmation')
                              ElevatedButton(
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        setState(() => _loading = true);
                                        final itemsToConfirm = shareds
                                            .where((s) =>
                                                s['shared'].status ==
                                                'awaiting_confirmation')
                                            .map((s) => {
                                                  'itemId': widget
                                                          .bill
                                                          .items[s['itemIndex']]
                                                          .id
                                                          ?.toString() ??
                                                      '',
                                                  'userIdToConfirm': s['shared']
                                                          .user
                                                          ?.toString() ??
                                                      '',
                                                })
                                            .toList();
                                        try {
                                          await ref
                                              .read(
                                                  billListProvider(workspaceId)
                                                      .notifier)
                                              .confirmPayment(
                                                billId: widget.bill.id,
                                                itemsToConfirm: itemsToConfirm,
                                              );
                                          ref.refresh(
                                              billListProvider(workspaceId));
                                          Navigator.pop(context);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'เกิดข้อผิดพลาด: $e')));
                                        } finally {
                                          setState(() => _loading = false);
                                        }
                                      },
                                child: const Text('ยืนยัน'),
                              ),
                          ],
                        ),
                        onTap: status == 'paid' && slip != null
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      Dialog(child: Image.file(slip)),
                                );
                              }
                            : null,
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
