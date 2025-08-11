/// Model class for a Bill
class Bill {
  final String id;
  final dynamic workspace;
  final List<Creator> creator;
  final String paymentType;
  final RoundDetails? roundDetails;
  final List<Item> items;
  final String note;
  final String status;
  final String? eSlip;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Bill({
    required this.id,
    required this.workspace,
    required this.creator,
    required this.paymentType,
    this.roundDetails,
    required this.items,
    this.note = '',
    this.status = 'pending',
    this.eSlip,
    required this.createdAt,
    this.updatedAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['_id'] as String,
      workspace: (() {
        final ws = json['workspace'];
        if (ws is Map) {
          final id = ws['_id'];
          if (id is String) return id;
          if (id is Map && id['\$oid'] != null) return id['\$oid'] as String;
          return '';
        }
        return ws as String? ?? '';
      })(),
      creator: (json['creator'] as List<dynamic>)
          .map((e) => Creator.fromJson(e as Map<String, dynamic>))
          .toList(),
      paymentType: json['paymentType'] as String,
      roundDetails: json['roundDetails'] != null
          ? RoundDetails.fromJson(json['roundDetails'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String? ?? '',
      status: json['status'] as String,
      eSlip: json['eSlip'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'workspace': workspace is String
          ? workspace
          : (workspace is Map ? workspace['_id']?.toString() ?? '' : ''),
      'creator': creator.map((c) => c.toJson()).toList(),
      'paymentType': paymentType,
      if (roundDetails != null) 'roundDetails': roundDetails!.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'note': note,
      'status': status,
      if (eSlip != null) 'eSlip': eSlip,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

/// Model class for the creator info
class Creator {
  final String userId;
  final String name;
  final String numberAccount;

  Creator({
    required this.userId,
    required this.name,
    required this.numberAccount,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      userId: json['userId'] as String,
      name: json['name'] as String,
      numberAccount: json['numberAccount'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'numberAccount': numberAccount,
    };
  }
}

/// Model class for round payment details
class RoundDetails {
  final DateTime dueDate;
  final int totalPeriod;
  final int currentRound;

  RoundDetails({
    required this.dueDate,
    required this.totalPeriod,
    this.currentRound = 1,
  });

  factory RoundDetails.fromJson(Map<String, dynamic> json) {
    return RoundDetails(
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      totalPeriod: json['totalPeriod'] as int? ?? 1,
      currentRound: json['currentRound'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dueDate': dueDate.toIso8601String(),
      'totalPeriod': totalPeriod,
      'currentRound': currentRound,
    };
  }
}

/// Model class for an item in the bill
class Item {
  final String? id;
  final String description;
  final double amount;
  final List<SharedWith> sharedWith;

  Item({
    this.id,
    required this.description,
    required this.amount,
    required this.sharedWith,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['_id'] as String?,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      sharedWith: (json['sharedWith'] as List<dynamic>)
          .map((e) => SharedWith.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'description': description,
      'amount': amount,
      'sharedWith': sharedWith.map((s) => s.toJson()).toList(),
    };
  }
}

/// Model class for shared payment info
class SharedWith {
  final dynamic user;
  final String name;
  final String status;
  final double shareAmount;
  final List<RoundPayment>? roundPayments;
  final String? eSlip;

  SharedWith({
    required this.user,
    required this.name,
    required this.status,
    required this.shareAmount,
    this.roundPayments,
    this.eSlip,
  });

  factory SharedWith.fromJson(Map<String, dynamic> json) {
    // รองรับ user เป็น Map หรือ String
    String userId;
    if (json['user'] is Map) {
      userId = json['user']['\$oid'] ?? json['user']['_id'] ?? '';
    } else {
      userId = json['user']?.toString() ?? '';
    }
    String? eSlipUrl;
    if (json['eSlip'] is String) {
      eSlipUrl = json['eSlip'];
    } else if (json['eSlip'] is Map && json['eSlip']['url'] != null) {
      eSlipUrl = json['eSlip']['url'];
    }
    return SharedWith(
      user: userId,
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      shareAmount: (json['shareAmount'] ?? 0).toDouble(),
      roundPayments: (json['roundPayments'] as List<dynamic>? ?? [])
          .map((e) => RoundPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
      eSlip: eSlipUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user is String
          ? user
          : (user is Map ? user['_id']?.toString() ?? '' : ''),
      'name': name,
      'status': status,
      'shareAmount': shareAmount,
      if (roundPayments != null)
        'roundPayments': roundPayments!.map((r) => r.toJson()).toList(),
      if (eSlip != null) 'eSlip': eSlip,
    };
  }
}

/// Model class for each round payment
class RoundPayment {
  final int round;
  final double amount;
  final String status;
  final DateTime? paidDate;
  final String? eSlip;

  RoundPayment({
    required this.round,
    required this.amount,
    required this.status,
    this.paidDate,
    this.eSlip,
  });

  factory RoundPayment.fromJson(Map<String, dynamic> json) {
    String? eSlipUrl;
    if (json['eSlip'] is String) {
      eSlipUrl = json['eSlip'];
    } else if (json['eSlip'] is Map && json['eSlip']['url'] != null) {
      eSlipUrl = json['eSlip']['url'];
    }
    return RoundPayment(
      round: json['round'] != null ? (json['round'] as num).toInt() : 1,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      eSlip: eSlipUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'round': round,
      'amount': amount,
      'status': status,
      if (paidDate != null) 'paidDate': paidDate!.toIso8601String(),
      if (eSlip != null) 'eSlip': eSlip,
    };
  }
}
