import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/data/models/request_model.dart';
import 'package:fintrack/features/workspace/request_controller.dart';
import 'package:fintrack/features/workspace/components/all_bills_screen.dart';
import 'package:fintrack/features/workspace/components/request_form_screen.dart';
import 'package:fintrack/features/workspace/components/request_detail_dialog.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/workspace/workspace_controller.dart';

class ProjectWorkspaceScreen extends ConsumerStatefulWidget {
  final WorkspaceModel workspace;

  const ProjectWorkspaceScreen({
    Key? key,
    required this.workspace,
  }) : super(key: key);

  @override
  ConsumerState<ProjectWorkspaceScreen> createState() =>
      _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState
    extends ConsumerState<ProjectWorkspaceScreen> {
  final RequestController _requestController = Get.put(RequestController());
  final SecureStorage _storage = SecureStorage();
  String _selectedTab = 'requests'; // 'requests', 'my-requests', 'members'
  bool _isOwner = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadRequests();
  }

  Future<void> _checkUserRole() async {
    try {
      final token = await _storage.read('jwt');
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(
              base64Url.decode(
                base64Url.normalize(parts[1]),
              ),
            ),
          );
          final userId = payload['id'] as String;
          _isOwner = userId == widget.workspace.owner;
        }
      }
    } catch (e) {
      debugPrint('Error checking user role: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRequests() async {
    if (_selectedTab == 'requests') {
      await _requestController.fetchWorkspaceRequests(widget.workspace.id);
    } else if (_selectedTab == 'my-requests') {
      await _requestController.fetchMyRequests(widget.workspace.id);
    }
  }

  Future<void> _showApproveDialog(RequestModel request) async {
    await _requestController.selectOwnerProofFile();
    if (_requestController.selectedOwnerProofFile.value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาแนบหลักฐานการอนุมัติ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('อนุมัติคำขอ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('คุณต้องการอนุมัติคำขอนี้ใช่หรือไม่?'),
            const SizedBox(height: 16),
            if (_requestController.selectedOwnerProofFile.value != null) ...[
              const Text(
                'ไฟล์หลักฐานที่แนบ:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _requestController.selectedOwnerProofFile.value!.path
                    .split('/')
                    .last,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _requestController.selectedOwnerProofFile.value = null;
              Navigator.pop(context, false);
            },
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('อนุมัติ'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await _requestController.approveRequest(
          widget.workspace.id, request.id);
      if (success) {
        await _loadRequests();
      }
    }
  }

  Future<void> _showRejectDialog(RequestModel request) async {
    final TextEditingController reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธคำขอ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณาระบุเหตุผลในการปฏิเสธ:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'เหตุผลในการปฏิเสธ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาระบุเหตุผลในการปฏิเสธ'),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ปฏิเสธ'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await _requestController.rejectRequest(
        widget.workspace.id,
        request.id,
        reasonController.text,
      );
      if (success) {
        await _loadRequests();
      }
    }
  }

  Future<void> _showDeleteDialog(RequestModel request) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบคำขอ'),
        content: const Text(
            'คุณต้องการลบคำขอนี้ใช่หรือไม่?\nการกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await _requestController.deleteRequest(
          widget.workspace.id, request.id);
      if (success) {
        await _loadRequests();
        if (!mounted) return;
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showRequestDetail(RequestModel request) async {
    await _requestController.fetchRequestDetail(
        widget.workspace.id, request.id);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => RequestDetailDialog(
        request: request,
        isOwner: _isOwner,
        onApprove: (request) => _showApproveDialog(request),
        onReject: (request) => _showRejectDialog(request),
        onDelete: (request) => _showDeleteDialog(request),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.white, size: 48),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabButton('requests', 'คำขอทั้งหมด'),
          const SizedBox(width: 16),
          _buildTabButton('my-requests', 'คำขอของฉัน'),
          const SizedBox(width: 16),
          _buildTabButton('members', 'สมาชิก'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedTab = tab);
          _loadRequests();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3A6D8C) : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    return Obx(() {
      if (_requestController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final requests = _selectedTab == 'my-requests'
          ? _requestController.myRequests
          : _requestController.requests;

      if (requests.isEmpty) {
        return Center(
          child: Text(
            _selectedTab == 'my-requests'
                ? 'คุณยังไม่มีคำขอเบิกจ่าย'
                : 'ยังไม่มีคำขอเบิกจ่าย',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                '${request.amount.toStringAsFixed(2)} บาท',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('โดย ${request.requester?.name ?? 'ไม่ระบุ'}'),
                  Text('วันที่ ${request.formattedDate}'),
                  if (request.rejectionReason != null)
                    Text(
                      'เหตุผลที่ปฏิเสธ: ${request.rejectionReason}',
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(request.status),
                      style: TextStyle(
                        color: _getStatusColor(request.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isOwner && request.status == 'pending')
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'approve') {
                          await _showApproveDialog(request);
                        } else if (value == 'reject') {
                          await _showRejectDialog(request);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'approve',
                          child: Row(
                            children: [
                              Icon(Icons.check, color: Colors.green),
                              SizedBox(width: 8),
                              Text('อนุมัติ'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              Icon(Icons.close, color: Colors.red),
                              SizedBox(width: 8),
                              Text('ปฏิเสธ'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              onTap: () => _showRequestDetail(request),
            ),
          );
        },
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รออนุมัติ';
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ไม่อนุมัติ';
      case 'completed':
        return 'เสร็จสิ้น';
      default:
        return status;
    }
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
        ...widget.workspace.members.map((member) => ListTile(
              leading: CircleAvatar(
                child: Text(member.user.name[0].toUpperCase()),
              ),
              title: Text(member.user.name),
              subtitle: Text(member.user.email),
              trailing: Text(
                'เข้าร่วมเมื่อ ${_formatDate(member.joinAt)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Obx(() {
      final requests = _requestController.requests;
      final totalBudget = widget.workspace.budget ?? 0;
      final usedBudget = requests
          .where((req) => req.status == 'completed')
          .fold(0.0, (sum, req) => sum + req.amount);
      final remainingBudget = totalBudget - usedBudget;

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
                  'สรุปงบประมาณ',
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
                    'ทั้งหมด ${requests.length} คำขอ',
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
                _buildSummaryItem(
                  'งบประมาณ',
                  '${totalBudget.toStringAsFixed(0)} บาท',
                  Icons.account_balance_wallet,
                ),
                _buildSummaryItem(
                  'ใช้แล้ว',
                  '${usedBudget.toStringAsFixed(0)} บาท',
                  Icons.payments,
                ),
                _buildSummaryItem(
                  'คงเหลือ',
                  '${remainingBudget.toStringAsFixed(0)} บาท',
                  Icons.account_balance,
                ),
              ],
            ),
          ],
        ),
      );
    });
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
              fontSize: 16,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF638889),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(
              widget.workspace.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.workspace.members.length} สมาชิก',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showWorkspaceOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildTabBar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: _selectedTab == 'members'
                  ? _buildMemberList()
                  : _buildRequestList(),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedTab != 'members'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RequestFormScreen(workspace: widget.workspace),
                  ),
                ).then((_) => _loadRequests());
              },
              backgroundColor: const Color(0xFF3A6D8C),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showWorkspaceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('เพิ่มสมาชิก'),
              onTap: () {
                Navigator.pop(context);
                _showAddMemberDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('แก้ไขงบประมาณ'),
              onTap: () {
                Navigator.pop(context);
                _showEditBudgetDialog(context);
              },
            ),
            if (_isOwner)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('ลบ Workspace',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteWorkspaceDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditBudgetDialog(BuildContext context) async {
    final TextEditingController budgetController = TextEditingController(
      text: widget.workspace.budget?.toString() ?? '0',
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขงบประมาณ'),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'งบประมาณ',
            prefixText: '฿ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBudget = double.tryParse(budgetController.text) ?? 0;
              try {
                final updatedWorkspace = WorkspaceModel(
                  id: widget.workspace.id,
                  name: widget.workspace.name,
                  owner: widget.workspace.owner,
                  type: widget.workspace.type,
                  budget: newBudget,
                  members: widget.workspace.members,
                  createdAt: widget.workspace.createdAt,
                  updatedAt: widget.workspace.updatedAt,
                );
                await ref
                    .read(workspaceListProvider.notifier)
                    .updateWorkspace(updatedWorkspace);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('อัพเดทงบประมาณสำเร็จ'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A6D8C),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMemberDialog(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มสมาชิก'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรุณากรอกอีเมลของสมาชิกที่ต้องการเพิ่ม'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'อีเมล',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกอีเมล'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await ref
                    .read(workspaceListProvider.notifier)
                    .addMemberToWorkspace(
                      widget.workspace.id,
                      email,
                    );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('เพิ่มสมาชิกสำเร็จ'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A6D8C),
            ),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteWorkspaceDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบ Workspace'),
        content: const Text(
            'คุณต้องการลบ workspace นี้ใช่หรือไม่?\nการกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: ลบ workspace ผ่าน controller
              Navigator.pop(context);
              Navigator.pop(context); // กลับไปหน้าหลัก
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}
