import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fintrack/presentation/components/bottom_navbar.dart';
import 'package:fintrack/features/home/home_screen.dart';
import 'package:fintrack/features/expense_report/expense_report_screen.dart';
import 'package:fintrack/features/add_expense/add_expense_screen.dart';
import 'package:fintrack/features/workspace/workspace_list_screen.dart';
//import 'package:fintrack/features/notification/notification_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    ExpenseReportScreen(),
    const AddExpenseScreen(), // Your existing HomeScreen

    const WorkspaceListScreen(),
    //NotificationScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedIndex == 2 ? const Color(0xFF638889) : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
