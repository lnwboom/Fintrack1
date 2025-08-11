/// A model class representing a financial transaction.
class TransactionModel {
  final String id;
  final String userId;
  final String? workspaceId;
  final String type;
  final double amount;
  final String category;
  final String? description;
  final String? slipImage;
  final DateTime? transactionDate;
  final String? transactionTime;
  final String? transactionId;
  final SenderInfo? senderInfo;
  final ReceiverInfo? receiverInfo;
  final Reference? reference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  TransactionModel({
    required this.id,
    required this.userId,
    this.workspaceId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    this.slipImage,
    this.transactionDate,
    this.transactionTime,
    this.transactionId,
    this.senderInfo,
    this.receiverInfo,
    this.reference,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      workspaceId: json['workspace']?.toString(),
      type: json['type']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString(),
      slipImage: json['slip_image']?.toString() ??
          (json['image'] is Map ? json['image']['url']?.toString() : null),
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'].toString())
          : null,
      transactionTime: json['transaction_time']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      senderInfo: json['sender_info'] != null
          ? SenderInfo.fromJson(json['sender_info'] as Map<String, dynamic>)
          : null,
      receiverInfo: json['receiver_info'] != null
          ? ReceiverInfo.fromJson(json['receiver_info'] as Map<String, dynamic>)
          : null,
      reference: json['reference'] != null
          ? Reference.fromJson(json['reference'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      v: json['__v'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      '_id': id,
      'user': userId,
      'workspace': workspaceId,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'slip_image': slipImage,
      'transaction_date': transactionDate?.toIso8601String(),
      'transaction_time': transactionTime,
      'transaction_id': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
    };

    if (senderInfo != null) {
      data['sender_info'] = senderInfo!.toJson();
    }
    if (receiverInfo != null) {
      data['receiver_info'] = receiverInfo!.toJson();
    }
    if (reference != null) {
      data['reference'] = reference!.toJson();
    }

    return data;
  }
}

/// Nested model for sender information.
class SenderInfo {
  final String? name;
  final String? bank;

  SenderInfo({this.name, this.bank});

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      name: json['name'] as String?,
      bank: json['bank'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bank': bank,
    };
  }
}

/// Nested model for receiver information.
class ReceiverInfo {
  final String? name;
  final String? bank;

  ReceiverInfo({this.name, this.bank});

  factory ReceiverInfo.fromJson(Map<String, dynamic> json) {
    return ReceiverInfo(
      name: json['name'] as String?,
      bank: json['bank'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'bank': bank,
    };
  }
}

/// Nested model for reference information.
class Reference {
  final String? type;
  final String? id;

  Reference({this.type, this.id});

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      type: json['type'] as String?,
      id: json['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
    };
  }
}
