import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:fintrack/features/home/service/transaction_service.dart';

final transactionListProvider = StateNotifierProvider<TransactionListController,
    AsyncValue<List<TransactionModel>>>(
  (ref) => TransactionListController(ref),
);

class TransactionListController
    extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final Ref _ref;
  final TransactionService _service;

  TransactionListController(this._ref)
      : _service = TransactionService(),
        super(const AsyncValue.loading()) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _service.fetchTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => _loadTransactions();

  Future<void> remove(String id) async {
    try {
      await _service.deleteTransaction(id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((t) => t.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TransactionModel> create({
    required String type,
    required double amount,
    required String category,
    String? description,
    String? workspaceId,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    return _service.createTransaction(
      type: type,
      amount: amount,
      category: category,
      description: description,
      workspaceId: workspaceId,
      slipImageBytes: slipImageBytes,
      slipImageName: slipImageName,
    );
  }

  Future<TransactionModel> update({
    required String id,
    String? type,
    double? amount,
    String? category,
    String? description,
    String? workspaceId,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    return _service.updateTransaction(
      id: id,
      type: type,
      amount: amount,
      category: category,
      description: description,
      workspaceId: workspaceId,
      slipImageBytes: slipImageBytes,
      slipImageName: slipImageName,
    );
  }
}
