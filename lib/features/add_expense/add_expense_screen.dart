import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/features/add_expense/components/expense_form.dart';
import 'package:fintrack/features/add_expense/components/bill_sheet.dart';
import 'package:fintrack/features/add_expense/components/bill_detail_equal.dart';
import 'package:fintrack/features/add_expense/components/bill_detail_round_screen.dart';
import 'package:fintrack/features/workspace/workspace_controller.dart';
import 'package:fintrack/features/auth/auth_controller.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '0');
  final TextEditingController _noteController = TextEditingController();

  String selectedType = 'รายรับ';
  final List<Map<String, String>> _categories = [
    {'value': 'food', 'label': 'อาหาร'},
    {'value': 'housing', 'label': 'ที่อยู่อาศัย'},
    {'value': 'utilities', 'label': 'ค่าสาธารณูปโภค'},
    {'value': 'transportation', 'label': 'การเดินทาง'},
    {'value': 'healthcare', 'label': 'สุขภาพ'},
    {'value': 'education', 'label': 'การศึกษา'},
    {'value': 'shopping', 'label': 'ช้อปปิ้ง'},
    {'value': 'entertainment', 'label': 'บันเทิง'},
    {'value': 'telecommunications', 'label': 'โทรคมนาคม'},
    {'value': 'insurance', 'label': 'ประกันภัย'},
    {'value': 'electronics', 'label': 'อิเล็กทรอนิกส์'},
    {'value': 'other', 'label': 'อื่นๆ'},
  ];
  String? _selectedCategory = 'food';
  WorkspaceModel? _selectedWorkspace;
  bool _isEvenSplit = true;

  void _submitExpense() {
    if (_amountController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }
    print('Type: $selectedType');
    print('Amount: ${_amountController.text}');
    print('Category: $_selectedCategory');
    print('Note: ${_noteController.text}');
    print('Workspace: ${_selectedWorkspace?.name}');
  }

  void _showBillBottomSheet() async {
    final workspaces = ref.watch(workspaceListProvider);

    if (workspaces.value?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No real workspaces yet! Please create one.')),
      );
      return;
    }

    await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => BillSheet(
        workspaces: workspaces.value ?? [],
        selectedWorkspace: _selectedWorkspace,
        amountController: _amountController,
        isEvenSplit: _isEvenSplit,
        onSplitToggle: (val) {},
        onWorkspaceSelected: (_) {},
      ),
    );
  }

  void _onRequestBill() async {
    ref.watch(authControllerProvider);
    final workspaces = ref.watch(workspaceListProvider);

    final selectedWorkspace = await showModalBottomSheet<WorkspaceModel>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => RequestWorkspaceBottomSheet(
        workspaces: workspaces.value ?? [],
      ),
    );

    if (selectedWorkspace != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillDetailRoundScreen(workspace: selectedWorkspace),
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('เพิ่มรายการ',
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              Text('บันทึกรายจ่าย',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.wallet, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: XpenseForm(
                amountController: _amountController,
                noteController: _noteController,
                selectedType: selectedType,
                onTypeSelected: (type) {
                  setState(() => selectedType = type);
                },
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategoryChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                onBillTap: _showBillBottomSheet,
                onRequestBillTap: _onRequestBill,
                onSubmit: _submitExpense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

class RequestWorkspaceBottomSheet extends StatelessWidget {
  final List<WorkspaceModel> workspaces;

  const RequestWorkspaceBottomSheet({Key? key, required this.workspaces})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseWorkspaces =
        workspaces.where((w) => w.type == 'expense').toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เลือกกลุ่มสำหรับเรียกเก็บเงิน',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (expenseWorkspaces.isEmpty)
            const Center(child: Text('ไม่พบกลุ่มสำหรับรายจ่าย'))
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: expenseWorkspaces.length,
              itemBuilder: (context, index) {
                final workspace = expenseWorkspaces[index];
                return ListTile(
                  title: Text(workspace.name),
                  subtitle: Text('สมาชิก ${workspace.members.length} คน'),
                  leading: CircleAvatar(child: Text(workspace.name[0])),
                  onTap: () => Navigator.of(context).pop(workspace),
                );
              },
            ),
        ],
      ),
    );
  }
}
