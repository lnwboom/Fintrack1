import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/data/models/bills_model.dart';
import 'package:fintrack/features/add_expense/service/bill_service.dart';

final billListProvider = StateNotifierProvider.family<BillListController,
    AsyncValue<List<Bill>>, String>(
  (ref, workspaceId) => BillListController(ref, workspaceId),
);

class BillListController extends StateNotifier<AsyncValue<List<Bill>>> {
  final Ref _ref;
  final String workspaceId;
  final BillService _service;

  BillListController(this._ref, this.workspaceId)
      : _service = BillService(),
        super(const AsyncValue.loading()) {
    _loadBills();
  }

  Future<void> _loadBills() async {
    try {
      final bills = await _service.fetchBills(workspaceId: workspaceId);
      state = AsyncValue.data(bills);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => _loadBills();

  Future<void> remove(String id) async {
    try {
      await _service.deleteBill(workspaceId: workspaceId, id: id);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((b) => b.id != id).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Bill> create({
    String? paymentType,
    RoundDetails? roundDetails,
    required List<Item> items,
    String? note,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    final processedItems = items.map((item) {
      final processedSharedWith = item.sharedWith.map((shared) {
        final userData = shared.user is Map
            ? shared.user as Map<String, dynamic>
            : {'_id': shared.user, 'name': shared.name};
        return SharedWith(
          user: userData['_id'] as String,
          name: userData['name'] as String,
          status: shared.status,
          shareAmount: shared.shareAmount,
          roundPayments: shared.roundPayments,
          eSlip: shared.eSlip,
        );
      }).toList();

      return Item(
        description: item.description,
        amount: item.amount,
        sharedWith: processedSharedWith,
      );
    }).toList();

    final bill = await _service.createBill(
      workspaceId: workspaceId,
      paymentType: paymentType ?? 'normal',
      roundDetails: roundDetails,
      items: processedItems,
      note: note,
      slipImageBytes: slipImageBytes,
      slipImageName: slipImageName,
    );
    await _loadBills();
    return bill;
  }

  Future<Bill> update({
    required String id,
    String? paymentType,
    RoundDetails? roundDetails,
    List<Item>? items,
    String? note,
    List<int>? slipImageBytes,
    String? slipImageName,
  }) async {
    final bill = await _service.updateBill(
      workspaceId: workspaceId,
      id: id,
      paymentType: paymentType,
      roundDetails: roundDetails,
      items: items,
      note: note,
      slipImageBytes: slipImageBytes,
      slipImageName: slipImageName,
    );
    await _loadBills();
    return bill;
  }

  /// Submit payment for bill items
  ///
  /// This method allows a user to submit payment for one or more items in a bill
  /// by uploading a payment slip.
  Future<Map<String, dynamic>> submitPayment({
    required String billId,
    required List<String> itemIds,
    required List<int> slipImageBytes,
    required String slipImageName,
  }) async {
    final result = await _service.submitPayment(
      workspaceId: workspaceId,
      billId: billId,
      itemIds: itemIds,
      slipImageBytes: slipImageBytes,
      slipImageName: slipImageName,
    );

    await _loadBills(); // Refresh bills after submission
    return result;
  }

  /// Confirm payment for bill items
  ///
  /// This method allows the bill creator to confirm payment for one or more items
  /// in a bill, changing the status from 'awaiting_confirmation' to 'paid'.
  ///
  /// Each item in the itemsToConfirm list should contain:
  /// - 'itemId': The ID of the bill item
  /// - 'userIdToConfirm': The ID of the user whose payment is being confirmed
  Future<Map<String, dynamic>> confirmPayment({
    required String billId,
    required List<Map<String, String>> itemsToConfirm,
  }) async {
    // ตรวจสอบและแปลง userIdToConfirm ให้เป็น String id เสมอ
    final processedItems = itemsToConfirm.map((item) {
      final userId = item['userIdToConfirm'];
      return {
        'itemId': item['itemId'] ?? '',
        'userIdToConfirm': userId ?? '',
      };
    }).toList();
    final result = await _service.confirmPayment(
      workspaceId: workspaceId,
      billId: billId,
      itemsToConfirm: processedItems,
    );
    await _loadBills(); // Refresh bills after confirmation
    return result;
  }
}
