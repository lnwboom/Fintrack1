import 'package:fintrack/data/models/workspace_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/auth/auth_controller.dart';
import 'workspace_controller.dart';
import 'expense_workspace_screen.dart';
import 'project_workspace_screen.dart';
import 'package:fintrack/features/workspace/components/create_workspace_dialog.dart';

class WorkspaceListScreen extends ConsumerWidget {
  const WorkspaceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final workspaces = ref.watch(workspaceListProvider);

    Widget _buildHeader() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('พื้นที่ทำงาน',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                Text('กลุ่มของฉัน',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.groups, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF638889),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    workspaces.when(
                      data: (list) {
                        final userWorkspaces = list
                            .where((w) =>
                                w.members.any((m) => m.user.id == user?.id))
                            .toList();
                        return Column(
                          children: [
                            if (userWorkspaces.isEmpty)
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'ยังไม่มีพื้นที่ทำงาน\nกด + เพื่อสร้างใหม่',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: userWorkspaces.length,
                                  itemBuilder: (context, index) {
                                    final ws = userWorkspaces[index];
                                    return _WorkspaceCard(
                                      workspace: ws,
                                      onMemberAdded: (success, message) {
                                        if (!success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    message.contains(
                                                            'สมาชิกอยู่แล้ว')
                                                        ? Icons
                                                            .warning_amber_rounded
                                                        : Icons.error_outline,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(message),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: message.contains(
                                                      'สมาชิกอยู่แล้ว')
                                                  ? Colors.orange
                                                  : Colors.red,
                                              duration:
                                                  const Duration(seconds: 3),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              margin: const EdgeInsets.all(8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              action: SnackBarAction(
                                                label: 'ตกลง',
                                                textColor: Colors.white,
                                                onPressed: () {
                                                  ScaffoldMessenger.of(context)
                                                      .hideCurrentSnackBar();
                                                },
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF638889),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'เกิดข้อผิดพลาด: ${error.toString()}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.refresh(workspaceListProvider);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF638889),
                              ),
                              child: const Text('ลองใหม่'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFF638889),
                        child: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _showCreateDialog(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authControllerProvider);
    final user = authState.value;
    showDialog(
      context: context,
      builder: (context) => CreateWorkspaceDialog(
        onCreate: (name, type, memberEmails) async {
          final data = {
            'name': name,
            'type': type,
            'members': memberEmails, // ส่งตรงไป API
          };
          await ref.read(workspaceListProvider.notifier).addFromMap(data);
        },
        currentUserEmail: user?.email ?? '',
      ),
    );
  }
}

class _WorkspaceCard extends ConsumerWidget {
  final WorkspaceModel workspace;
  final Function(bool success, String message)? onMemberAdded;

  const _WorkspaceCard({
    required this.workspace,
    this.onMemberAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (workspace.type == 'expense') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseWorkspaceScreen(workspace: workspace),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectWorkspaceScreen(workspace: workspace),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    workspace.type == 'expense'
                        ? Icons.account_balance_wallet
                        : Icons.assignment,
                    color: const Color(0xFF3A6D8C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workspace.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: workspace.type == 'expense'
                          ? const Color(0xFF638889).withOpacity(0.1)
                          : const Color(0xFF3A6D8C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      workspace.type == 'expense' ? 'บิล' : 'โปรเจค',
                      style: TextStyle(
                        color: workspace.type == 'expense'
                            ? const Color(0xFF638889)
                            : const Color(0xFF3A6D8C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'add_member',
                        child: Row(
                          children: [
                            Icon(Icons.person_add, size: 20),
                            SizedBox(width: 8),
                            Text('เพิ่มสมาชิก'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('แก้ไข'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('ลบ', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'add_member') {
                        _showAddMemberDialog(context, ref);
                      } else if (value == 'edit') {
                        _showEditDialog(context, ref);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, ref);
                      }
                    },
                  ),
                ],
              ),
              if (workspace.budget != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'งบประมาณ: ${workspace.budget!.toStringAsFixed(2)} บาท',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'สมาชิก: ${workspace.members.length} คน',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: workspace.name);
    final budgetController = TextEditingController(
      text: workspace.budget?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขพื้นที่ทำงาน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อพื้นที่ทำงาน',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetController,
              decoration: const InputDecoration(
                labelText: 'งบประมาณ (บาท)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType: TextInputType.number,
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
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกชื่อพื้นที่ทำงาน'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final updated = WorkspaceModel(
                  id: workspace.id,
                  name: nameController.text,
                  owner: workspace.owner,
                  type: workspace.type,
                  budget: double.tryParse(budgetController.text),
                  members: workspace.members,
                  createdAt: workspace.createdAt,
                  updatedAt: workspace.updatedAt,
                );

                await ref
                    .read(workspaceListProvider.notifier)
                    .updateWorkspace(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('อัพเดทข้อมูลสำเร็จ'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณต้องการลบ "${workspace.name}" ใช่หรือไม่?'),
            const SizedBox(height: 8),
            const Text(
              'การกระทำนี้ไม่สามารถย้อนกลับได้',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
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
              try {
                await ref
                    .read(workspaceListProvider.notifier)
                    .remove(workspace.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ลบพื้นที่ทำงานสำเร็จ'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
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
              backgroundColor: Colors.red,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('เพิ่มสมาชิก'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('กรุณากรอกอีเมลของสมาชิกที่ต้องการเพิ่ม'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'อีเมล',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
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

                      setState(() => isLoading = true);

                      try {
                        await ref
                            .read(workspaceListProvider.notifier)
                            .addMemberToWorkspace(
                              workspace.id,
                              email,
                            );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        onMemberAdded?.call(true, 'เพิ่มสมาชิกสำเร็จ');
                      } catch (e) {
                        if (!context.mounted) return;
                        String errorMessage = 'เกิดข้อผิดพลาดในการเพิ่มสมาชิก';
                        if (e.toString().contains('User is already a member')) {
                          errorMessage = 'อีเมลนี้เป็นสมาชิกอยู่แล้ว';
                        } else if (e.toString().contains('User not found')) {
                          errorMessage = 'ไม่พบผู้ใช้อีเมลนี้ในระบบ';
                        }
                        onMemberAdded?.call(false, errorMessage);
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A6D8C),
                disabledBackgroundColor:
                    const Color(0xFF3A6D8C).withOpacity(0.5),
              ),
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }
}
