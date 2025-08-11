/*// bill_model.dart
import 'user_model.dart';

class BillItem {
  final String name;
  final double amount;
  final List<String> sharedBy;

  BillItem({
    required this.name,
    required this.amount,
    required this.sharedBy,
  });

  double get amountPerPerson => amount / sharedBy.length;
}

class BillModel {
  final String workspaceId;
  final String billName;
  final bool isEvenSplit;
  final double totalAmount;
  final String createdBy;
  final DateTime createdAt;
  final String note;
  final String payeeName;
  final String payeePromptPay;
  final List<String> allMembers;
  final List<BillItem> items;
  Map<String, bool> paymentStatus;

  BillModel({
    required this.workspaceId,
    required this.billName,
    required this.isEvenSplit,
    required this.totalAmount,
    required this.createdBy,
    required this.createdAt,
    required this.note,
    required this.payeeName,
    required this.payeePromptPay,
    required this.allMembers,
    required this.items,
    required this.paymentStatus,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>).map((item) {
      final sharedBy = (item['sharedWith'] as List<dynamic>).map((shared) {
        final userData = shared['user'] is Map
            ? shared['user'] as Map<String, dynamic>
            : {'_id': shared['user'], 'name': shared['name']};
        return userData['name'] as String;
      }).toList();

      return BillItem(
        name: item['description'] as String,
        amount: (item['amount'] as num).toDouble(),
        sharedBy: sharedBy,
      );
    }).toList();

    return BillModel(
      workspaceId: json['workspace']['_id'] as String,
      billName: json['billName'] as String? ?? '',
      isEvenSplit: json['paymentType'] == 'equal',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdBy: (json['creator'] as List<dynamic>).first['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String? ?? '',
      payeeName: (json['creator'] as List<dynamic>).first['name'] as String,
      payeePromptPay:
          (json['creator'] as List<dynamic>).first['numberAccount'] as String,
      allMembers: (json['members'] as List<dynamic>)
          .map((m) => m['name'] as String)
          .toList(),
      items: items,
      paymentStatus: Map<String, bool>.from(json['paymentStatus'] as Map),
    );
  }

  /// Return a breakdown of each member's total share
  Map<String, List<Map<String, dynamic>>> get itemsByMember {
    final Map<String, List<Map<String, dynamic>>> result = {};

    for (var item in items) {
      final share = item.amountPerPerson;
      for (var person in item.sharedBy) {
        result.putIfAbsent(person, () => []);
        result[person]!.add({
          'name': item.name,
          'amount': share,
        });
      }
    }

    return result;
  }

  /// Return total amount each member has to pay
  Map<String, double> get memberTotalAmounts {
    final Map<String, double> result = {};
    for (var item in items) {
      final share = item.amountPerPerson;
      for (var person in item.sharedBy) {
        result[person] = (result[person] ?? 0) + share;
      }
    }
    return result;
  }

  /// Return true if everyone has paid
  bool get isFullyPaid {
    return allMembers.every((m) => paymentStatus[m] == true);
  }

  /// Update payment status
  void markAsPaid(String memberName) {
    paymentStatus[memberName] = true;
  }

  void markAsUnpaid(String memberName) {
    paymentStatus[memberName] = false;
  }

  void updatePaymentStatus(Map<String, bool> newStatus) {
    paymentStatus = Map<String, bool>.from(newStatus);
  }

  void updateMemberPaymentStatus(String memberName, bool status) {
    paymentStatus[memberName] = status;
  }
}

// mock_bill_data

*/