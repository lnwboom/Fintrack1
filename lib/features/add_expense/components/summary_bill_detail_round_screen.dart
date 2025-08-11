// summary_request_bill_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryBillRoundScreen extends StatelessWidget {
  final String workspaceName;
  final bool isTotalMode;
  final double totalAmount;
  final DateTime? dueDate;
  final int repeatCount;
  final String note;
  final Map<String, double> memberAmounts;

  const SummaryBillRoundScreen({
    Key? key,
    required this.workspaceName,
    required this.isTotalMode,
    required this.totalAmount,
    this.dueDate,
    required this.repeatCount,
    required this.note,
    required this.memberAmounts,
  }) : super(key: key);

  void _editPromptPay(BuildContext context, String payeeName,
      String payeePromptPay, void Function(String, String) onSave) async {
    final nameCtrl = TextEditingController(text: payeeName);
    final numCtrl = TextEditingController(text: payeePromptPay);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('แก้ไขบัญชีรับเงิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อบัญชี')),
            TextField(
                controller: numCtrl,
                decoration: const InputDecoration(labelText: 'เบอร์พร้อมเพย์'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              onSave(nameCtrl.text, numCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String payeeName = '';
    String payeePromptPay = '';

    void onSavePrompt(String name, String num) {
      payeeName = name;
      payeePromptPay = num;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('สรุปการเรียกเก็บเงิน',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row('กลุ่ม', workspaceName),
              const Divider(),
              _row('โหมด', isTotalMode ? 'ยอดรวม' : 'รายคน'),
              const Divider(),
              _row('จำนวนเงินทั้งหมด', '${totalAmount.toStringAsFixed(2)} บาท'),
              const Divider(),
              _row(
                  'ครบกำหนด',
                  dueDate != null
                      ? DateFormat('dd/MM/yyyy').format(dueDate!)
                      : 'ไม่กำหนด'),
              const Divider(),
              _row('จำนวนรอบ', repeatCount.toString()),
              const Divider(),
              _row('หมายเหตุ', note.isNotEmpty ? note : '-'),
            ]),
          ),

          const SizedBox(height: 24),

          // Breakdown per member
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ยอดที่สมาชิกต้องจ่าย',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...memberAmounts.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(color: Colors.grey)),
                        Text('${e.value.toStringAsFixed(0)} บาท',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                );
              }).toList(),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('รวมทั้งหมด', style: TextStyle(color: Colors.grey)),
                Text('${totalAmount.toStringAsFixed(0)} บาท',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),

          const SizedBox(height: 24),

          // PromptPay
          const Text('บัญชีรับเงิน', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _editPromptPay(
                context, payeeName, payeePromptPay, onSavePrompt),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    payeeName.isNotEmpty
                        ? '$payeeName\nพร้อมเพย์  $payeePromptPay'
                        : 'เพิ่มบัญชีรับเงิน',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54),
                  ),
                ),
                const Icon(Icons.edit, color: Colors.blue),
              ]),
            ),
          ),

          const Spacer(),

          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child:
                    const Text('แก้ไข', style: TextStyle(color: Colors.black))),
            ElevatedButton.icon(
                onPressed: () {
                  // Save logic…
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('บันทึกเรียบร้อย!')));
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('บันทึก'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A6D8C))),
          ]),
        ]),
      ),
    );
  }

  Widget _row(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Flexible(
            child: Text(val,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
