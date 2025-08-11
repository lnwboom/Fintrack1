// lib/features/auth/view/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/features/auth/auth_controller.dart';
import 'package:fintrack/features/main/main_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _error;
  bool _otpSent = false;

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() => _error = null);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendOtp(_emailCtrl.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    if (!_otpSent) {
      await _sendOtp();
      return;
    }
    try {
      final result = await ref.read(authControllerProvider.notifier).register(
            username: _userCtrl.text.trim(),
            password: _passCtrl.text,
            confirmPassword: _confirmPassCtrl.text,
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            otp: _otpCtrl.text.trim(),
          );

      if (result == true) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        setState(() {
          _error = 'ไม่สามารถลงทะเบียนได้ กรุณาตรวจสอบข้อมูลและลองใหม่อีกครั้ง';
        });
      }
    } catch (e) {
      String errorMessage = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';

      if (e.toString().contains('Duplicate value')) {
        if (e.toString().contains('numberAccount')) {
          errorMessage =
              'ชื่อผู้ใช้นี้มีผู้ใช้งานแล้ว กรุณาเลือกชื่อผู้ใช้อื่น';
          _userCtrl.clear();
        } else if (e.toString().contains('email')) {
          errorMessage = 'อีเมลนี้มีผู้ใช้งานแล้ว กรุณาใช้อีเมลอื่น';
          _emailCtrl.clear();
        }
      } else if (e.toString().contains('Invalid OTP')) {
        errorMessage = 'รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบและลองใหม่อีกครั้ง';
        _otpCtrl.clear();
      } else if (e.toString().contains('Weak password')) {
        errorMessage =
            'รหัสผ่านไม่ปลอดภัยพอ กรุณาใช้รหัสผ่านที่ซับซ้อนขึ้น (ต้องมีตัวอักษรและตัวเลขอย่างน้อย 8 ตัว)';
        _passCtrl.clear();
        _confirmPassCtrl.clear();
      }

      setState(() {
        _error = errorMessage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ตกลง',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        backgroundColor: const Color(0xFF638889),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_add,
                  size: 80,
                  color: Color(0xFF638889),
                ),
                const SizedBox(height: 16),
                const Text(
                  'สร้างบัญชีใหม่',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF638889),
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _userCtrl,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ใช้',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF638889)),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'กรุณากรอกชื่อผู้ใช้'
                      : v.length < 3
                          ? 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF638889)),
                    ),
                    helperText:
                        'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร และต้องมีตัวอักษรหรือตัวเลข',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    if (v.length < 8) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                    }
                    if (!RegExp(
                            r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$')
                        .hasMatch(v)) {
                      return 'รหัสผ่านต้องมีตัวอักษรและตัวเลข';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPassCtrl,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF638889)),
                    ),
                  ),
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty
                      ? 'กรุณายืนยันรหัสผ่าน'
                      : v != _passCtrl.text
                          ? 'รหัสผ่านไม่ตรงกัน'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ชื่อ-สกุล',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF638889)),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'กรุณากรอกชื่อ-สกุล'
                      : v.length < 2
                          ? 'ชื่อ-สกุลต้องมีอย่างน้อย 2 ตัวอักษร'
                          : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'อีเมล',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF638889)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty
                      ? 'กรุณากรอกอีเมล'
                      : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
                          ? 'กรุณากรอกอีเมลให้ถูกต้อง'
                          : null,
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otpCtrl,
                    decoration: InputDecoration(
                      labelText: 'รหัส OTP',
                      prefixIcon: const Icon(Icons.security),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF638889)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty
                        ? 'กรุณากรอก OTP'
                        : v.length != 6
                            ? 'รหัส OTP ต้องมี 6 หลัก'
                            : null,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                state.when(
                  data: (_) => SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF638889),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _otpSent ? 'ยืนยัน OTP และ ลงทะเบียน' : 'ส่งรหัส OTP',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF638889),
                      ),
                    ),
                  ),
                  error: (e, _) => Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.toString().contains('Duplicate value')
                                    ? 'ชื่อผู้ใช้หรืออีเมลนี้มีผู้ใช้งานแล้ว'
                                    : e.toString(),
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF638889),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _otpSent ? 'ลองอีกครั้ง' : 'ส่งรหัส OTP อีกครั้ง',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
