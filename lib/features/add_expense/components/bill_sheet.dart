import 'package:flutter/material.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/features/workspace/components/workspace_list_item.dart';
import 'bill_detail_equal.dart';
import 'bill_detail_unequal.dart';

class BillSheet extends StatefulWidget {
  final List<WorkspaceModel> workspaces;
  final WorkspaceModel? selectedWorkspace;
  final TextEditingController amountController;
  final bool isEvenSplit;
  final Function(bool) onSplitToggle;
  final Function(WorkspaceModel) onWorkspaceSelected;

  const BillSheet({
    Key? key,
    required this.workspaces,
    required this.selectedWorkspace,
    required this.amountController,
    required this.isEvenSplit,
    required this.onSplitToggle,
    required this.onWorkspaceSelected,
  }) : super(key: key);

  @override
  _BillSheetState createState() => _BillSheetState();
}

class _BillSheetState extends State<BillSheet> {
  final TextEditingController _billNameController = TextEditingController();
  bool _isEvenSplit = true;
  WorkspaceModel? _selectedWorkspace;

  @override
  void initState() {
    super.initState();
    _isEvenSplit = widget.isEvenSplit;
    _selectedWorkspace = widget.selectedWorkspace;
  }

  @override
  void dispose() {
    _billNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseWorkspaces =
        widget.workspaces.where((w) => w.type == 'expense').toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: TextField(
                controller: _billNameController,
                decoration: const InputDecoration(
                  labelText: 'ตั้งชื่อบิล',
                  hintText: 'เช่น ค่าอาหารกลางวัน',
                ),
              ),
            ),
            SwitchListTile(
              title: Text(_isEvenSplit ? 'หารเท่า' : 'หารไม่เท่า'),
              subtitle: Text(
                _isEvenSplit ? 'หารเฉลี่ยทุกคน' : 'กำหนดเงินแต่ละคนเอง',
              ),
              value: _isEvenSplit,
              onChanged: (val) {
                setState(() => _isEvenSplit = val);
              },
              activeColor: Colors.green,
            ),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'จำนวนเงิน',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: widget.amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'เช่น 450.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF090F47),
              ),
            ),

            const Divider(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'เลือกกลุ่ม',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            // Workspace List
            if (expenseWorkspaces.isEmpty)
              const Text('ไม่พบกลุ่มสำหรับรายจ่าย')
            else
              ListView.builder(
                itemCount: expenseWorkspaces.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final workspace = expenseWorkspaces[index];
                  final isSelected = workspace.id == _selectedWorkspace?.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedWorkspace = workspace;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.transparent,
                        border: isSelected
                            ? Border.all(color: Colors.blueAccent, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: WorkspaceListItem(workspace: workspace),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () {
                if (_selectedWorkspace == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาเลือกกลุ่มก่อน')),
                  );
                  return;
                }
                final total =
                    double.tryParse(widget.amountController.text) ?? 0.0;
                if (total <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('จำนวนเงินไม่ถูกต้อง')),
                  );
                  return;
                }
                final List<MemberShare> shares =
                    _selectedWorkspace!.members.map((m) {
                  return MemberShare(
                    memberId: m.user.id,
                    memberName: m.user.name,
                    amount: _isEvenSplit
                        ? total / _selectedWorkspace!.members.length
                        : 0,
                  );
                }).toList();
                if (_isEvenSplit) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BillDetailScreen(
                        isEvenSplit: true,
                        totalAmount: total,
                        memberShares: shares,
                        billName: _billNameController.text,
                        allMembers: shares.map((e) => e.memberName).toList(),
                        workspaceId: _selectedWorkspace!.id,
                        selectedWorkspace: _selectedWorkspace!,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BillDetailUnequalScreen(
                        allMembers: _selectedWorkspace!.members,
                        tripName: _billNameController.text,
                        createdBy: '',
                        totalAmount: total,
                        note: '',
                        payeeName: '',
                        payeePromptPay: '',
                        workspaceId: _selectedWorkspace!.id,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('เสร็จสิ้น'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A6D8C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
