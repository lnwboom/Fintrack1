// request_bill_screen.dart
import 'package:flutter/material.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/data/models/bills_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bill_controller.dart';
import '../../../features/auth/auth_controller.dart';
import 'summary_bill_screen.dart';
import 'dart:async';

class BillDetailRoundScreen extends ConsumerStatefulWidget {
  final WorkspaceModel workspace;
  const BillDetailRoundScreen({Key? key, required this.workspace})
      : super(key: key);

  @override
  ConsumerState<BillDetailRoundScreen> createState() =>
      _BillDetailRoundScreenState();
}

class _BillDetailRoundScreenState extends ConsumerState<BillDetailRoundScreen> {
  bool isTotalMode = true;
  DateTime? startDate;

  // controllers
  final totalController = TextEditingController();
  final perPersonController = TextEditingController();
  final noteController = TextEditingController();
  final repeatCountController =
      TextEditingController(text: '1'); // กำหนด default = 1

  // เก็บสมาชิกที่ถูกเลือก + controller ของแต่ละคน
  List<String> selectedMembers = [];
  final Map<String, TextEditingController> memberControllers = {};

  // เพิ่ม debounce timer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // เตรียม controller แต่ละคน
    for (var m in widget.workspace.members) {
      memberControllers[m.user.name] = TextEditingController();
    }
    // เริ่มต้นเลือกสมาชิกทั้งหมด
    selectedMembers = widget.workspace.members.map((m) => m.user.name).toList();
    // คำนวณยอดหารเท่าเริ่มต้น
    _recalcTotalSplit();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    totalController.dispose();
    perPersonController.dispose();
    noteController.dispose();
    repeatCountController.dispose();
    for (var c in memberControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ฟังก์ชันคำนวณหารเท่า
  void _recalcTotalSplit() {
    if (!mounted) return;
    final total = double.tryParse(totalController.text) ?? 0.0;
    final cnt = selectedMembers.length;
    if (cnt == 0) return;
    setState(() {
      final share = total / cnt;
      for (var n in selectedMembers) {
        if (memberControllers[n] != null) {
          memberControllers[n]!.text = share.toStringAsFixed(0);
        }
      }
    });
  }

  // เมื่อแก้ไขยอดของสมาชิกรายในโหมดยอดรวม
  void _onTotalMemberChanged(String name, String val) {
    final total = double.tryParse(totalController.text) ?? 0.0;
    final changed = double.tryParse(val) ?? 0.0;
    final others = selectedMembers.where((n) => n != name).toList();
    if (others.isEmpty) return;
    setState(() {
      final rem = total - changed;
      final share = rem / others.length;
      for (var n in others) {
        memberControllers[n]!.text = share.toStringAsFixed(0);
      }
    });
  }

  // ผลรวมยอดสมาชิกโหมดรายคน
  double get _sumOfPersons {
    return selectedMembers.fold<double>(0.0, (sum, n) {
      return sum + (double.tryParse(memberControllers[n]!.text) ?? 0.0);
    });
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => startDate = d);
  }

  Future<Bill?> _fetchBill(WidgetRef ref) async {
    try {
      final billsState = ref.read(billListProvider(widget.workspace.id));
      return billsState.when(
        data: (bills) {
          try {
            return bills.firstWhere(
              (bill) => bill.paymentType == 'round',
              orElse: () => throw Exception('ไม่พบบิลแบบหารเท่า'),
            );
          } catch (e) {
            debugPrint('ไม่พบบิลแบบหารเท่า: $e');
            return null;
          }
        },
        loading: () {
          debugPrint('กำลังโหลดข้อมูลบิล...');
          return null;
        },
        error: (error, stack) {
          debugPrint('เกิดข้อผิดพลาดในการดึงข้อมูลบิล: $error');
          debugPrint('Stack trace: $stack');
          return null;
        },
      );
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดใน _fetchBill: $e');
      return null;
    }
  }

  // ส่งข้อมูลสู่หน้าสรุป
  void _goToSummary(WidgetRef ref) async {
    final authState = ref.read(authControllerProvider);
    final currentUser = authState.value;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    final total = isTotalMode
        ? double.tryParse(totalController.text) ?? 0.0
        : _sumOfPersons;

    // สร้าง map ของยอดสมาชิก
    final memberAmounts = {
      for (var name in selectedMembers)
        name: double.tryParse(memberControllers[name]!.text) ?? 0.0
    };

    // สร้าง round details
    final roundDetails = RoundDetails(
      dueDate: startDate ?? DateTime.now().add(const Duration(days: 7)),
      totalPeriod: int.tryParse(repeatCountController.text) ?? 1,
      currentRound: 1,
    );

    // สร้าง items สำหรับบิล
    final items = [
      Item(
        description: 'หารทั้งหมด',
        amount: total,
        sharedWith: selectedMembers
            .map((name) => SharedWith(
                  user: widget.workspace.members
                      .firstWhere((m) => m.user.name == name)
                      .user
                      .id,
                  name: name,
                  status: 'pending',
                  shareAmount: memberAmounts[name] ?? 0.0,
                  roundPayments: [],
                ))
            .toList(),
      )
    ];

    try {
      debugPrint('Starting bill creation...');
      final bill =
          await ref.read(billListProvider(widget.workspace.id).notifier).create(
                paymentType: 'round',
                items: items,
                note: noteController.text.isEmpty
                    ? 'บิลหารเท่า'
                    : noteController.text,
                roundDetails: roundDetails,
              );

      if (context.mounted && bill != null) {
        final creator = bill.creator.first;
        final Map<String, List<Map<String, dynamic>>> itemsByMember = {};

        for (var item in bill.items) {
          for (var shared in item.sharedWith) {
            if (!itemsByMember.containsKey(shared.name)) {
              itemsByMember[shared.name] = [];
            }
            itemsByMember[shared.name]!.add({
              'name': item.description,
              'amount': shared.shareAmount,
            });
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SummaryBillScreen(
              tripName: widget.workspace.name,
              createdBy: creator.name,
              createdAt: bill.createdAt,
              itemsByMember: itemsByMember,
              totalAmount: total,
              note: bill.note,
              payeeName: creator.name,
              payeePromptPay: creator.numberAccount,
              workspaceId: widget.workspace.id,
              billId: bill.id,
              roundDetails: roundDetails,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกบิลสำเร็จ')),
        );
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
  }

  // Modal เลือกสมาชิก
  void _showMemberPicker() {
    final temp = List<String>.from(selectedMembers);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setM) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widget.workspace.members.map((m) {
                  final sel = temp.contains(m.user.name);
                  return CheckboxListTile(
                    title: Text(m.user.name),
                    value: sel,
                    onChanged: (v) {
                      setM(() {
                        if (v == true)
                          temp.add(m.user.name);
                        else
                          temp.remove(m.user.name);
                      });
                    },
                  );
                }),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('ยกเลิก')),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedMembers = temp;
                            // sync controller สมาชิกใหม่
                            for (var m in widget.workspace.members) {
                              if (!memberControllers.containsKey(m.user.name)) {
                                memberControllers[m.user.name] =
                                    TextEditingController();
                              }
                            }
                            // ลบ controller ที่ไม่ใช้งาน
                            memberControllers.removeWhere(
                                (k, v) => !selectedMembers.contains(k));
                            // เคลียร์ controller สมาชิกที่ถูกถอด
                            for (var k in memberControllers.keys) {
                              if (!selectedMembers.contains(k)) {
                                memberControllers[k]!.clear();
                              }
                            }
                            if (isTotalMode)
                              _recalcTotalSplit();
                            else {
                              final v = perPersonController.text;
                              for (var n in selectedMembers) {
                                memberControllers[n]!.text = v;
                              }
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text('ตกลง'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Tab เปลี่ยนโหมด
  Widget _buildTabs() {
    return TabBar(
      indicatorColor: Colors.indigo,
      labelColor: Colors.black,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'ยอดรวม'),
        Tab(text: 'รายคน'),
      ],
      onTap: (i) {
        setState(() {
          isTotalMode = (i == 0);
          if (isTotalMode) {
            _recalcTotalSplit();
          } else {
            perPersonController.clear();
            for (var n in selectedMembers) {
              memberControllers[n]!.clear();
            }
          }
        });
      },
    );
  }

  Widget _amountSection() {
    if (isTotalMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ยอดรวม',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: totalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, color: Colors.black),
            decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey)),
            onChanged: (value) {
              // ใช้ debounce เพื่อลดการคำนวณบ่อยเกินไป
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _recalcTotalSplit();
                }
              });
            },
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('จำนวนเงินต่อคน',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: perPersonController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, color: Colors.black),
            decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.grey)),
            onChanged: (v) {
              setState(() {
                for (var n in selectedMembers) {
                  memberControllers[n]!.text = v;
                }
              });
            },
          ),
        ],
      );
    }
  }

  Widget _memberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _showMemberPicker,
          icon: const Icon(Icons.group_add),
          label: Text(
              'สมาชิก (${selectedMembers.length}/${widget.workspace.members.length})'),
          style: ElevatedButton.styleFrom(
              //primary: Colors.white, onPrimary: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300)),
        ),
        const SizedBox(height: 12),
        ...selectedMembers.map((name) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green[300],
                    child: Text(name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 12),
                Expanded(child: Text(name)),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: memberControllers[name],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '0'),
                    onChanged: isTotalMode
                        ? (value) {
                            // ใช้ debounce สำหรับการคำนวณยอดสมาชิก
                            _debounceTimer?.cancel();
                            _debounceTimer =
                                Timer(const Duration(milliseconds: 300), () {
                              if (mounted) {
                                _onTotalMemberChanged(name, value);
                              }
                            });
                          }
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedMembers.remove(name);
                      memberControllers[name]!.clear();
                      if (isTotalMode) _recalcTotalSplit();
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _startDatePicker() {
    return ListTile(
      title: Text(
        startDate != null
            ? DateFormat('dd/MM/yyyy').format(startDate!)
            : 'เลือกวันที่',
        style: const TextStyle(color: Colors.black),
      ),
      trailing: const Icon(Icons.calendar_today, color: Colors.black),
      onTap: _pickStartDate,
    );
  }

  Widget _repeatCountField() {
    return TextField(
      controller: repeatCountController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: const InputDecoration(border: InputBorder.none),
      onChanged: (v) => setState(() {}),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: noteController,
      maxLines: 2,
      decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'เพิ่มหมายเหตุ (ถ้ามี)',
          hintStyle: TextStyle(color: Colors.grey)),
      style: const TextStyle(color: Colors.black),
    );
  }

  Widget _submitButtons(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.black))),
        ElevatedButton.icon(
          onPressed: () => _goToSummary(ref),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('สรุปการเรียกเก็บเงิน'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A6D8C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('กลุ่ม', style: TextStyle(color: Colors.white70)),
      Text(widget.workspace.name,
          style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('สมาชิก ${widget.workspace.members.length} คน',
          style: const TextStyle(color: Colors.white70, fontSize: 16)),
      const SizedBox(height: 16),
      Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.request_page,
              size: 72, color: Colors.white.withOpacity(0.5))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return DefaultTabController(
          length: 2,
          initialIndex: isTotalMode ? 0 : 1,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      color: const Color(0xFF3A6D8C),
                      padding: const EdgeInsets.all(24),
                      child: _buildHeader(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('รูปแบบการเก็บเงิน',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                          _buildTabs(),
                          const Divider(height: 32),
                          _amountSection(),
                          const Divider(height: 32),
                          const Text('สมาชิก',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          _memberSection(),
                          const Divider(height: 32),
                          const Text('วันที่เริ่มเก็บ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          _startDatePicker(),
                          const Divider(height: 32),
                          const Text('จำนวนรอบ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          _repeatCountField(),
                          const Divider(height: 32),
                          const Text('หมายเหตุ',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          _noteField(),
                          const SizedBox(height: 32),
                          _submitButtons(ref),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
