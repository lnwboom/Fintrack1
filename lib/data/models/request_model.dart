// lib/data/models/request_model.dart

import 'workspace_model.dart';
import 'user_model.dart';

/// Model class for budget request items
class RequestItemModel {
  final String? description;
  final double price;
  final int quantity;

  RequestItemModel({
    this.description,
    required this.price,
    required this.quantity,
  });

  factory RequestItemModel.fromJson(Map<String, dynamic> json) {
    return RequestItemModel(
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (description != null) 'description': description,
        'price': price,
        'quantity': quantity,
      };

  // Calculate the total price of the item
  double get total => price * quantity;
}

/// Status history entry for a request
class StatusHistoryEntry {
  final String status;
  final DateTime updatedAt;
  final String updatedBy;
  final String? reason;

  StatusHistoryEntry({
    required this.status,
    required this.updatedAt,
    required this.updatedBy,
    this.reason,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: json['status'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
        if (reason != null) 'reason': reason,
      };
}

/// Model for file proofs (requester proof or owner proof)
class ProofFileModel {
  final String url;
  final String? path;

  ProofFileModel({
    required this.url,
    this.path,
  });

  factory ProofFileModel.fromJson(dynamic json) {
    if (json is String) {
      return ProofFileModel(url: json);
    }
    if (json is Map<String, dynamic>) {
      return ProofFileModel(
        url: json['url'] as String,
        path: json['path'] as String?,
      );
    }
    throw Exception('Invalid proof file data format');
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        if (path != null) 'path': path,
      };
}

/// The main Request model
class RequestModel {
  final String id;
  final String workspaceId;
  final String requesterId;
  final double amount;
  final List<RequestItemModel> items;
  final ProofFileModel? requesterProof;
  final ProofFileModel? ownerProof;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;
  final List<StatusHistoryEntry>? statusHistory;

  // Optional populated objects from backend
  final WorkspaceModel? workspace;
  final UserModel? requester;

  RequestModel({
    required this.id,
    required this.workspaceId,
    required this.requesterId,
    required this.amount,
    required this.items,
    this.requesterProof,
    this.ownerProof,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
    this.statusHistory,
    this.workspace,
    this.requester,
  });

  // Compute the total from all items
  double get totalItemsAmount => items.fold(0, (sum, item) => sum + item.total);

  // Check if the request is pending
  bool get isPending => status == 'pending';

  // Check if the request is completed
  bool get isCompleted => status == 'completed';

  // Check if the request is rejected
  bool get isRejected => status == 'rejected';

  // Helper to get the formatted date
  String get formattedDate =>
      '${createdAt.day}/${createdAt.month}/${createdAt.year}';

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    // Extract ID safely from either _id or id field
    String parseId(Map<String, dynamic> m) =>
        m['_id']?.toString() ?? m['id']?.toString() ?? '';

    // Parse the workspace info
    WorkspaceModel? parseWorkspace(dynamic workspaceData) {
      if (workspaceData == null) return null;
      if (workspaceData is String) return null; // Just ID, no full object
      if (workspaceData is Map<String, dynamic>) {
        return WorkspaceModel.fromJson(workspaceData);
      }
      return null;
    }

    // Parse the requester info
    UserModel? parseRequester(dynamic requesterData) {
      if (requesterData == null) return null;
      if (requesterData is String) return null; // Just ID, no full object
      if (requesterData is Map<String, dynamic>) {
        return UserModel.fromJson(requesterData);
      }
      return null;
    }

    // Parse the items list
    List<RequestItemModel> parseItems(dynamic itemsData) {
      if (itemsData == null || !(itemsData is List)) return [];

      return (itemsData as List).map((item) {
        if (item is Map<String, dynamic>) {
          return RequestItemModel.fromJson(item);
        }
        return RequestItemModel(price: 0, quantity: 0); // Fallback
      }).toList();
    }

    // Parse the status history
    List<StatusHistoryEntry>? parseStatusHistory(dynamic historyData) {
      if (historyData == null || !(historyData is List)) return null;

      return (historyData as List).map((entry) {
        if (entry is Map<String, dynamic>) {
          return StatusHistoryEntry.fromJson(entry);
        }
        return StatusHistoryEntry(
          status: '',
          updatedAt: DateTime.now(),
          updatedBy: '',
        ); // Fallback
      }).toList();
    }

    // Parse proof files
    ProofFileModel? parseProofFile(dynamic proofData) {
      if (proofData == null) return null;
      try {
        return ProofFileModel.fromJson(proofData);
      } catch (e) {
        return null;
      }
    }

    return RequestModel(
      id: parseId(json),
      workspaceId: json['workspace'] is String
          ? json['workspace'] as String
          : json['workspace'] != null &&
                  json['workspace'] is Map<String, dynamic>
              ? parseId(json['workspace'] as Map<String, dynamic>)
              : '',
      requesterId: json['requester'] is String
          ? json['requester'] as String
          : json['requester'] != null &&
                  json['requester'] is Map<String, dynamic>
              ? parseId(json['requester'] as Map<String, dynamic>)
              : '',
      amount: (json['amount'] as num).toDouble(),
      items: parseItems(json['items']),
      requesterProof: parseProofFile(json['requesterProof']),
      ownerProof: parseProofFile(json['ownerProof']),
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      updatedBy: json['updatedBy'] as String?,
      statusHistory: parseStatusHistory(json['statusHistory']),
      workspace: parseWorkspace(json['workspace']),
      requester: parseRequester(json['requester']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workspace': workspaceId,
        'requester': requesterId,
        'amount': amount,
        'items': items.map((item) => item.toJson()).toList(),
        if (requesterProof != null) 'requesterProof': requesterProof!.toJson(),
        if (ownerProof != null) 'ownerProof': ownerProof!.toJson(),
        'status': status,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (updatedBy != null) 'updatedBy': updatedBy,
        if (statusHistory != null)
          'statusHistory':
              statusHistory!.map((entry) => entry.toJson()).toList(),
      };
}
