import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/data/models/workspace_model.dart';
import 'package:fintrack/features/workspace/service/workspace_service.dart';
import 'package:fintrack/features/auth/auth_controller.dart';
import 'package:flutter/foundation.dart';

/// Exposes the list of all workspaces and CRUD operations on them.
final workspaceListProvider = StateNotifierProvider<WorkspaceListController,
    AsyncValue<List<WorkspaceModel>>>(
  (ref) => WorkspaceListController(ref),
);

class WorkspaceListController
    extends StateNotifier<AsyncValue<List<WorkspaceModel>>> {
  final _service = WorkspaceService();
  final Ref _ref;

  WorkspaceListController(this._ref) : super(const AsyncValue.loading()) {
    _loadWorkspaces();
  }

  Future<void> _loadWorkspaces() async {
    state = const AsyncValue.loading();
    try {
      final authStateValue = _ref.read(authControllerProvider).value;
      if (authStateValue == null) {
        state = const AsyncValue.data([]);
        debugPrint('User not authenticated, clearing workspaces.');
        return;
      }

      debugPrint(
          'Phase 1: Loading all workspaces from /api/workspaces for user: ${authStateValue.id}');
      final initialWorkspaces = await _service
          .getAll(); // These might have incomplete member.user data

      final List<WorkspaceModel> enrichedWorkspaces = [];
      debugPrint(
          'Phase 2: Enriching workspaces. Found ${initialWorkspaces.length} initial workspaces.');

      for (int i = 0; i < initialWorkspaces.length; i++) {
        var ws = initialWorkspaces[i];
        // Check if any member in this workspace has incomplete user data (e.g., name is empty)
        bool needsEnrichment =
            ws.members.any((m) => m.user.name.isEmpty && m.user.id.isNotEmpty);

        if (needsEnrichment) {
          debugPrint(
              'Workspace ${ws.id} (name: ${ws.name}) needs enrichment. Fetching full details.');
          try {
            // Fetch the full workspace details which should include full user objects for members
            final fullWorkspaceData = await _service.getById(ws.id);
            enrichedWorkspaces.add(fullWorkspaceData);
            debugPrint(
                'Successfully enriched workspace ${ws.id}. Members: ${fullWorkspaceData.members.map((m) => m.user.name)}');
          } catch (e, s) {
            debugPrint(
                'Failed to enrich workspace ${ws.id} by calling getById: $e, Stacktrace: $s');
            // If enrichment fails, add the original workspace (with potentially incomplete members) to avoid losing it
            enrichedWorkspaces.add(ws);
          }
        } else {
          // Workspace members are already complete (e.g. API /workspaces already sent full user data for this one)
          debugPrint(
              'Workspace ${ws.id} (name: ${ws.name}) does not need enrichment.');
          enrichedWorkspaces.add(ws);
        }
      }
      state = AsyncValue.data(enrichedWorkspaces);
      debugPrint(
          'Finished loading and enriching all workspaces. Final count: ${enrichedWorkspaces.length}');
    } catch (e, st) {
      debugPrint(
          'Error in _loadWorkspaces outer try-catch: $e, Stacktrace: $st');
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a new workspace, appending it to the state list.
  Future<void> add(WorkspaceModel ws) async {
    try {
      // Create endpoint should ideally return the full workspace object with populated members
      final newWs = await _service.create(ws);
      final currentState = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentState, newWs]);
      // No explicit refresh needed here if create returns the full object as expected by UI
      // If create returns incomplete data, a refresh might be considered:
      // await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update an existing workspace in-place.
  Future<void> updateWorkspace(WorkspaceModel ws) async {
    try {
      // Update endpoint should return the full workspace object
      final updatedWs = await _service.update(ws);
      final currentState = state.valueOrNull ?? [];
      final index = currentState.indexWhere((w) => w.id == ws.id);
      if (index != -1) {
        final newList = List<WorkspaceModel>.from(currentState);
        newList[index] = updatedWs;
        state = AsyncValue.data(newList);
      } else {
        // Workspace not found in current list, might be an error or list was cleared.
        // Refreshing might be a good fallback.
        debugPrint(
            'Workspace ${ws.id} not found in state during update. Refreshing list.');
        await refresh();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a workspace by ID and remove it from state.
  Future<void> remove(String id) async {
    try {
      await _service.delete(id);
      final currentState = state.valueOrNull ?? [];
      state = AsyncValue.data(currentState.where((w) => w.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadWorkspaces();
  }

  Future<void> addFromMap(Map<String, dynamic> data) async {
    try {
      final newWs = await _service.createFromMap(data);
      final currentState = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentState, newWs]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a member to a workspace by email address.
  Future<void> addMemberToWorkspace(String workspaceId, String email) async {
    try {
      final updatedWs = await _service.addMember(workspaceId, email);
      final currentState = state.valueOrNull ?? [];
      final index = currentState.indexWhere((w) => w.id == workspaceId);
      if (index != -1) {
        final newList = List<WorkspaceModel>.from(currentState);
        newList[index] = updatedWs;
        state = AsyncValue.data(newList);
      } else {
        // Workspace not found in current list, refreshing to be safe
        debugPrint(
            'Workspace $workspaceId not found in state during addMember. Refreshing list.');
        await refresh();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove a member from a workspace by user ID.
  Future<void> removeMemberFromWorkspace(String workspaceId, String userId) async {
    try {
      final updatedWs = await _service.removeMember(workspaceId, userId);
      final currentState = state.valueOrNull ?? [];
      final index = currentState.indexWhere((w) => w.id == workspaceId);
      if (index != -1) {
        final newList = List<WorkspaceModel>.from(currentState);
        newList[index] = updatedWs;
        state = AsyncValue.data(newList);
      } else {
        // Workspace not found in current list, refreshing to be safe
        debugPrint(
            'Workspace $workspaceId not found in state during removeMember. Refreshing list.');
        await refresh();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}