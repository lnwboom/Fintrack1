import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bill_controller.dart';

import '../../../data/models/bills_model.dart';

class SummaryBillScreen extends ConsumerStatefulWidget {
  final String tripName;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, List<Map<String, dynamic>>> itemsByMember;
  final double totalAmount;
  final String note;
  final String payeeName;
  final String payeePromptPay;
  final String workspaceId;
  final String billId;
  final RoundDetails? roundDetails;

  const SummaryBillScreen({
    super.key,
    required this.tripName,
    required this.createdBy,
    required this.createdAt,
    required this.itemsByMember,
    required this.totalAmount,
    required this.note,
    required this.payeeName,
    required this.payeePromptPay,
    required this.workspaceId,
    required this.billId,
    this.roundDetails,
  });

  @override
  ConsumerState<SummaryBillScreen> createState() => _SummaryBillScreenState();
}

class _SummaryBillScreenState extends ConsumerState<SummaryBillScreen> {
  late Future<Bill> _billFuture;

  @override
  void initState() {
    super.initState();
    _billFuture = _fetchBill();
  }

  Future<Bill> _fetchBill() async {
    try {
      debugPrint('เริ่มดึงข้อมูลบิล...');
      final billsState = ref.read(billListProvider(widget.workspaceId));
      return billsState.when(
        data: (bills) {
          try {
            final bill = bills.firstWhere(
              (b) => b.id == widget.billId,
              orElse: () => throw Exception('ไม่พบบิลที่ต้องการ'),
            );
            debugPrint('ได้รับข้อมูลบิล: ${bill.toJson()}');
            return bill;
          } catch (e) {
            debugPrint('ไม่พบบิลที่ต้องการ: $e');
            rethrow;
          }
        },
        loading: () => throw Exception('กำลังโหลดข้อมูล'),
        error: (error, stack) {
          debugPrint('เกิดข้อผิดพลาดในการดึงข้อมูลบิล: $error');
          debugPrint('Stack trace: $stack');
          throw Exception('เกิดข้อผิดพลาด: $error');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('เกิดข้อผิดพลาดใน _fetchBill: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
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
            const Text('รายละเอียดบิล', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: FutureBuilder<Bill>(
        future: _billFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('เกิดข้อผิดพลาดใน FutureBuilder: ${snapshot.error}');
            debugPrint('Stack trace: ${snapshot.stackTrace}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _billFuture = _fetchBill();
                      });
                    },
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          }

          final bill = snapshot.data!;
          final creator = bill.creator.first;

          // --- สร้าง itemsByMember ใหม่โดยใช้ userId เป็น key ---
          final Map<String, List<Map<String, dynamic>>> itemsByMember = {};
          final Map<String, String> userIdToName = {};
          final Map<String, String> userIdToStatus = {};
          final Map<String, double> userIdToTotal = {};

          for (var item in bill.items) {
            for (var shared in item.sharedWith) {
              final userId = shared.user;
              userIdToName[userId] = shared.name;
              userIdToStatus[userId] = shared.status;
              if (!itemsByMember.containsKey(userId)) {
                itemsByMember[userId] = [];
                userIdToTotal[userId] = 0.0;
              }
              final shareAmount = shared.shareAmount?.toDouble() ?? 0.0;
              itemsByMember[userId]!.add({
                'name': item.description,
                'amount': shareAmount,
              });
              userIdToTotal[userId] =
                  (userIdToTotal[userId] ?? 0.0) + shareAmount;
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.tripName,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Text('สร้างโดย ${creator.name}',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                  Text(
                                    '${widget.createdAt.day}/${widget.createdAt.month}, ${widget.createdAt.hour}:${widget.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              if (bill.roundDetails != null) ...[
                                const SizedBox(height: 12),
                                const Divider(),
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
                                      const Text(
                                        'รายละเอียดการจ่ายแบบรอบ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('จำนวนรอบทั้งหมด:'),
                                          Text(
                                            '${bill.roundDetails!.totalPeriod} รอบ',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('รอบปัจจุบัน:'),
                                          Text(
                                            'รอบที่ ${bill.roundDetails!.currentRound}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('วันที่ครบกำหนด:'),
                                          Text(
                                            '${bill.roundDetails!.dueDate.day}/${bill.roundDetails!.dueDate.month}/${bill.roundDetails!.dueDate.year}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('ยอดต่อรอบ:'),
                                          Text(
                                            '${(widget.totalAmount / bill.roundDetails!.totalPeriod).toStringAsFixed(0)} บาท',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(),
                              ...itemsByMember.entries.map((entry) {
                                final userId = entry.key;
                                final items = entry.value;
                                final name = userIdToName[userId] ?? userId;
                                final status =
                                    userIdToStatus[userId] ?? 'pending';
                                final total = userIdToTotal[userId] ?? 0.0;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ส่วนหัวแสดงชื่อและสถานะ
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: status == 'paid'
                                                    ? Colors.green[100]
                                                    : Colors.orange[100],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                status == 'paid'
                                                    ? 'จ่ายแล้ว'
                                                    : 'รอจ่าย',
                                                style: TextStyle(
                                                  color: status == 'paid'
                                                      ? Colors.green[800]
                                                      : Colors.orange[800],
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              '${total.toStringAsFixed(0)} บาท',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // รายการสินค้า
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        top: 8,
                                        bottom: 8,
                                      ),
                                      child: Column(
                                        children: items
                                            .map((item) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 4),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                          item['name'] ?? '',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 1,
                                                        child: Text(
                                                          '${(item['amount'] as double).toStringAsFixed(0)} บาท',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 14,
                                                          ),
                                                          textAlign:
                                                              TextAlign.right,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                    // รวมยอด
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'รวม',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${total.toStringAsFixed(0)} บาท',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(),
                                  ],
                                );
                              }),
                              // แสดงสถานะการจ่ายของแต่ละรอบ
                              if (bill.roundDetails != null) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'สถานะการจ่ายแต่ละรอบ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...bill.items.first.sharedWith.first
                                        .roundPayments
                                        ?.map((payment) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: payment.status == 'paid'
                                              ? Colors.green[50]
                                              : Colors.orange[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: payment.status == 'paid'
                                                ? Colors.green[200]!
                                                : Colors.orange[200]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'รอบที่ ${payment.round}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                if (payment.paidDate != null)
                                                  Text(
                                                    'จ่ายเมื่อ: ${payment.paidDate!.day}/${payment.paidDate!.month}/${payment.paidDate!.year}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${payment.amount.toStringAsFixed(0)} บาท',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: payment.status ==
                                                            'paid'
                                                        ? Colors.green[100]
                                                        : Colors.orange[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    payment.status == 'paid'
                                                        ? 'จ่ายแล้ว'
                                                        : 'รอจ่าย',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: payment.status ==
                                                              'paid'
                                                          ? Colors.green[800]
                                                          : Colors.orange[800],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList() ??
                                    [],
                              ],
                              // ยอดรวมทั้งบิล
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ยอดรวมทั้งบิล',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${widget.totalAmount.toStringAsFixed(0)} บาท',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('หมายเหตุ',
                                  style: TextStyle(color: Colors.grey)),
                              Text(widget.note,
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('บัญชีรับเงิน',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Image.asset('assets/promptpay.png', width: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${creator.name}\nพร้อมเพย์  ${creator.numberAccount}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54),
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.copy, color: Colors.blue),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: creator.numberAccount,
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('คัดลอกเลขพร้อมเพย์แล้ว'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("เสร็จสิ้น"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A6D8C)),
                    )
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
