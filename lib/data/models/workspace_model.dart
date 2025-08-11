// lib/data/models/workspace_model.dart

import 'user_model.dart';
import 'package:flutter/foundation.dart';

/// A single member of a workspace, with their user info and join date.
class WorkspaceMemberModel {
  final UserModel user;
  final DateTime joinAt;

  WorkspaceMemberModel({
    required this.user,
    required this.joinAt,
  });

  factory WorkspaceMemberModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceMemberModel(
      user: json['user'] is String
          ? UserModel(
              id: json['user'] as String,
              username: '',
              name: '',
              email: '',
              numberAccount: '') // Create UserModel with ID only
          : UserModel.fromJson(json['user'] as Map<String, dynamic>),
      joinAt: DateTime.parse(json['join_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'join_at': joinAt.toIso8601String(),
      };
}

/// The top-level workspace object.
class WorkspaceModel {
  final String id;
  final String name;
  final String owner; // user ID of the workspace owner
  final String type; // "expense" or "project"
  final double? budget;
  final List<WorkspaceMemberModel> members;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkspaceModel({
    required this.id,
    required this.name,
    required this.owner,
    required this.type,
    this.budget,
    required this.members,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    // Helper to pull either "_id" or "id"
    String parseId(Map<String, dynamic> m) =>
        m['_id']?.toString() ?? m['id']?.toString() ?? '';

    List<WorkspaceMemberModel> parsedMembers = [];
    if (json['members'] is List) {
      for (final item in (json['members'] as List<dynamic>)) {
        if (item is Map<String, dynamic>) {
          try {
            parsedMembers.add(WorkspaceMemberModel.fromJson(item));
          } catch (e, s) {
            debugPrint(
                'Error parsing member item: $item, Error: $e, Stacktrace: $s');
            // Optionally, rethrow or handle more gracefully
          }
        } else {
          debugPrint('Skipping non-map item in members list: $item');
        }
      }
    }

    return WorkspaceModel(
      id: parseId(json),
      name: json['name'] as String? ?? '',
      owner: json['owner']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      budget: (json['budget'] as num?)?.toDouble(),
      members: parsedMembers, // Use the safely parsed members
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'owner': owner,
        'type': type,
        if (budget != null) 'budget': budget,
        'members': members.map((m) => m.toJson()).toList(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
