import 'package:flutter/material.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/data/models/user_model.dart';

class WorkspaceListItem extends StatelessWidget {
  final WorkspaceModel workspace;

  const WorkspaceListItem({Key? key, required this.workspace})
      : super(key: key);

  Color _generateColorFromName(String name) {
    int hash = name.hashCode;
    return Color.fromRGBO(
      (hash & 0xFF0000) >> 16,
      (hash & 0x00FF00) >> 8,
      hash & 0x0000FF,
      0.7,
    );
  }

  Widget _buildMemberAvatar(UserModel member) {
    return Container(
      width: 35,
      height: 35,
      decoration: ShapeDecoration(
        color: _generateColorFromName(member.name),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.77),
        ),
        shadows: const [
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
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMembersAvatar(int count) {
    return Container(
      width: 35,
      height: 35,
      decoration: ShapeDecoration(
        color: const Color(0xFF6CA2E4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.77),
        ),
        shadows: const [
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
          '+$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 218,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 4,
            offset: Offset(0, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                workspace.type == 'expense' ? 'Expense' : 'Project',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 35,
            child: Stack(
              children: [
                for (int i = workspace.members.length - 1; i >= 0; i--)
                  if (i < 3)
                    Positioned(
                      left: i * 25.0,
                      child: _buildMemberAvatar(workspace.members[i].user),
                    ),
                if (workspace.members.length > 3)
                  Positioned(
                    left: 3 * 25.0,
                    child:
                        _buildMoreMembersAvatar(workspace.members.length - 3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            workspace.name,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 12,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'สร้างโดย ${workspace.members.isNotEmpty ? workspace.members.first.user.name : 'Unknown'}',
            style: const TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 10,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatDate(DateTime.now()),
              style: const TextStyle(
                color: Color(0xFFBDBDBD),
                fontSize: 8,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month;
    final monthName = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][month - 1];
    final day = date.day;
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'pm' : 'am';
    final hour12 = hour > 12 ? hour - 12 : hour;
    return '$monthName $day, $hour12:${minute.toString().padLeft(2, '0')}$period';
  }
}
