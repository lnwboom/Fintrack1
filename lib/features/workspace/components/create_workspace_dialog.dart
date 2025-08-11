import 'package:flutter/material.dart';
import 'package:fintrack/data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/auth/auth_controller.dart';

class CreateWorkspaceDialog extends ConsumerStatefulWidget {
  final Function(String, String, List<Map<String, String>>) onCreate;
  final String currentUserEmail;

  const CreateWorkspaceDialog({
    Key? key,
    required this.onCreate,
    required this.currentUserEmail,
  }) : super(key: key);

  @override
  ConsumerState<CreateWorkspaceDialog> createState() =>
      _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends ConsumerState<CreateWorkspaceDialog> {
  List<UserModel> allUsers = [];
  List<String> selectedMembers = [];
  bool isLoading = true;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String selectedType = 'expense';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users =
          await ref.read(authControllerProvider.notifier).getSimplifiedUsers();
      setState(() {
        allUsers = users
            .map((u) => UserModel(
                  id: u['id'],
                  username: u['username'] ?? '',
                  name: u['name'] ?? '',
                  email: u['email'] ?? '',
                  numberAccount: '',
                ))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Failed to fetch users: $e');
    }
  }

  void _addMemberByEmail(String email) {
    if (email.isEmpty) return;
    final normalized = email.trim().toLowerCase();
    if (normalized == widget.currentUserEmail.toLowerCase()) return;
    if (!selectedMembers.contains(normalized)) {
      setState(() {
        selectedMembers.add(normalized);
        emailController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 375,
        height: 736,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เลือกประเภท Workspace',
                style: TextStyle(
                  color: Color(0xFF080422),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _typeBox(
                    context,
                    title: 'Expenses',
                    subtitle: 'หารค่าใช้จ่าย',
                    selected: selectedType == 'expense',
                    onTap: () => setState(() => selectedType = 'expense'),
                  ),
                  _typeBox(
                    context,
                    title: 'Project',
                    subtitle: 'จัดการงบประมาณ',
                    selected: selectedType == 'project',
                    onTap: () => setState(() => selectedType = 'project'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อ Workspace',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'สมาชิกที่เลือก',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (selectedMembers.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedMembers.map((email) {
                    return Chip(
                      label: Text(email),
                      onDeleted: () {
                        setState(() {
                          selectedMembers.remove(email);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'เพิ่มสมาชิกด้วยอีเมล',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              _addMemberByEmail(emailController.text),
                        ),
                      ),
                      onSubmitted: _addMemberByEmail,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'สมาชิกที่มีในระบบ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Expanded(
                      child: ListView.builder(
                        itemCount: allUsers.length,
                        itemBuilder: (context, index) {
                          final user = allUsers[index];
                          final isSelected = selectedMembers
                              .contains(user.email.toLowerCase());
                          final isCurrentUser = user.email.toLowerCase() ==
                              widget.currentUserEmail.toLowerCase();
                          return ListTile(
                            leading: _buildMemberAvatar(user),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: isCurrentUser
                                ? null
                                : IconButton(
                                    icon: Icon(
                                      isSelected
                                          ? Icons.remove_circle
                                          : Icons.add_circle,
                                      color: isSelected
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (isSelected) {
                                          selectedMembers
                                              .remove(user.email.toLowerCase());
                                        } else {
                                          selectedMembers
                                              .add(user.email.toLowerCase());
                                        }
                                      });
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ยกเลิก'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('กรุณาระบุชื่อ Workspace')),
                        );
                        return;
                      }
                      if (selectedMembers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('กรุณาเลือกสมาชิกอย่างน้อย 1 คน')),
                        );
                        return;
                      }
                      final emailText =
                          emailController.text.trim().toLowerCase();
                      if (emailText.isNotEmpty &&
                          !selectedMembers.contains(emailText)) {
                        selectedMembers.add(emailText);
                      }
                      final memberList =
                          selectedMembers.map((e) => {'email': e}).toList();
                      try {
                        final result = await widget.onCreate(
                          nameController.text,
                          selectedType,
                          memberList,
                        );
                        if (result is Map && result['success'] == false) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(result['message'] ??
                                    'เกิดข้อผิดพลาดในการสร้าง Workspace')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
                        );
                      }
                    },
                    child: const Text('สร้าง'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBox(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 114,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color:
                selected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF080422),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: 0.5,
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF080422),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(UserModel member) {
    final int hash = member.name.hashCode;
    final color = Color.fromRGBO(
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
      0.7,
    );

    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.77),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: Center(
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }
}
