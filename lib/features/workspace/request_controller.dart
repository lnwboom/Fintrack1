import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fintrack/data/models/request_model.dart';
import 'package:fintrack/features/workspace/service/request_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class RequestController extends GetxController {
  final RequestService _requestService = RequestService();

  // Observable variables
  final RxList<RequestModel> requests = <RequestModel>[].obs;
  final RxList<RequestModel> myRequests = <RequestModel>[].obs;
  final Rx<RequestModel?> selectedRequest = Rx<RequestModel?>(null);

  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingDetail = false.obs;

  // Form-related variables
  final RxList<RequestItemModel> requestItems = <RequestItemModel>[].obs;
  final RxDouble totalAmount = 0.0.obs;
  final Rx<File?> selectedProofFile = Rx<File?>(null);
  final Rx<File?> selectedOwnerProofFile = Rx<File?>(null);
  final RxBool isEditing = false.obs;
  final TextEditingController rejectionReasonController =
      TextEditingController();

  void _showSnackbar(String title, String message,
      {bool isError = false, bool isWarning = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          isError ? Colors.red : (isWarning ? Colors.orange : Colors.green),
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
      icon: Icon(
        isError
            ? Icons.error
            : (isWarning ? Icons.warning : Icons.check_circle),
        color: Colors.white,
      ),
    );
  }

  @override
  void onClose() {
    rejectionReasonController.dispose();
    super.onClose();
  }

  // Calculate total amount from items
  void calculateTotalAmount() {
    totalAmount.value = requestItems.fold(
        0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Add a new item to the request
  void addItem(RequestItemModel item) {
    requestItems.add(item);
    calculateTotalAmount();
  }

  // Remove an item from the request
  void removeItem(int index) {
    if (index >= 0 && index < requestItems.length) {
      requestItems.removeAt(index);
      calculateTotalAmount();
    }
  }

  // Update an item in the request
  void updateItem(int index, RequestItemModel updatedItem) {
    if (index >= 0 && index < requestItems.length) {
      requestItems[index] = updatedItem;
      calculateTotalAmount();
    }
  }

  // Clear form data
  void clearForm() {
    requestItems.clear();
    totalAmount.value = 0.0;
    selectedProofFile.value = null;
    selectedOwnerProofFile.value = null;
    isEditing.value = false;
    rejectionReasonController.clear();
  }

  // Select proof file (using image_picker)
  Future<void> selectProofFile() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedProofFile.value = File(pickedFile.path);
      }
    } catch (e) {
      _showSnackbar('Error selecting file', e.toString(), isError: true);
    }
  }

  // Select owner proof file (for approval)
  Future<void> selectOwnerProofFile() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedOwnerProofFile.value = File(pickedFile.path);
      }
    } catch (e) {
      _showSnackbar('Error selecting file', e.toString(), isError: true);
    }
  }

  // Fetch all requests in a workspace
  Future<void> fetchWorkspaceRequests(String workspaceId) async {
    isLoading.value = true;
    try {
      final fetchedRequests =
          await _requestService.getAllByWorkspace(workspaceId);
      requests.assignAll(fetchedRequests);
    } catch (e) {
      _showSnackbar('Error loading requests', e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch current user's requests in a workspace
  Future<void> fetchMyRequests(String workspaceId) async {
    isLoading.value = true;
    try {
      final fetchedRequests =
          await _requestService.getMyRequestsByWorkspace(workspaceId);
      myRequests.assignAll(fetchedRequests);
    } catch (e) {
      _showSnackbar('Error loading your requests', e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // Get request details by ID
  Future<void> fetchRequestDetail(String workspaceId, String requestId) async {
    isLoadingDetail.value = true;
    try {
      final request = await _requestService.getById(workspaceId, requestId);
      selectedRequest.value = request;
    } catch (e) {
      _showSnackbar('Error loading request details', e.toString(),
          isError: true);
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // Create a new request
  Future<bool> createRequest(String workspaceId) async {
    if (requestItems.isEmpty) {
      _showSnackbar(
          'Cannot submit empty request', 'Please add at least one item',
          isWarning: true);
      return false;
    }

    isSubmitting.value = true;
    try {
      // Prepare request data
      final Map<String, dynamic> requestData = {
        'amount': totalAmount.value,
        'items': requestItems
            .map((item) => {
                  'description': item.description,
                  'price': item.price,
                  'quantity': item.quantity,
                })
            .toList(),
      };

      final newRequest = await _requestService.create(
          workspaceId, requestData, selectedProofFile.value);

      // Update local lists
      requests.add(newRequest);
      myRequests.add(newRequest);

      _showSnackbar(
          'Request created', 'Your budget request has been submitted');
      clearForm();
      return true;
    } catch (e) {
      _showSnackbar('Error creating request', e.toString(), isError: true);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Update an existing request
  Future<bool> updateRequest(String workspaceId, String requestId) async {
    if (requestItems.isEmpty) {
      _showSnackbar(
          'Cannot submit empty request', 'Please add at least one item',
          isWarning: true);
      return false;
    }

    isSubmitting.value = true;
    try {
      // Prepare request data
      final Map<String, dynamic> requestData = {
        'amount': totalAmount.value,
        'items': requestItems
            .map((item) => {
                  'description': item.description,
                  'price': item.price,
                  'quantity': item.quantity,
                })
            .toList(),
      };

      final updatedRequest = await _requestService.update(
          workspaceId, requestId, requestData, selectedProofFile.value);

      // Update local lists
      final reqIndex = requests.indexWhere((req) => req.id == requestId);
      if (reqIndex >= 0) {
        requests[reqIndex] = updatedRequest;
      }

      final myReqIndex = myRequests.indexWhere((req) => req.id == requestId);
      if (myReqIndex >= 0) {
        myRequests[myReqIndex] = updatedRequest;
      }

      selectedRequest.value = updatedRequest;

      _showSnackbar('Request updated', 'Your changes have been saved');
      return true;
    } catch (e) {
      _showSnackbar('Error updating request', e.toString(), isError: true);
      return false;
    } finally {
      isSubmitting.value = false;
      isEditing.value = false;
    }
  }

  // Approve a request
  Future<bool> approveRequest(String workspaceId, String requestId) async {
    if (selectedOwnerProofFile.value == null) {
      _showSnackbar('Payment proof required', 'Please attach payment proof',
          isWarning: true);
      return false;
    }

    isSubmitting.value = true;
    try {
      final result = await _requestService.updateStatus(
        workspaceId,
        requestId,
        'approved',
        ownerProofFile: selectedOwnerProofFile.value,
      );

      // Update local data
      if (result.containsKey('request')) {
        final updatedRequest = RequestModel.fromJson(result['request']);

        // Update in lists
        final reqIndex = requests.indexWhere((req) => req.id == requestId);
        if (reqIndex >= 0) {
          requests[reqIndex] = updatedRequest;
        }

        selectedRequest.value = updatedRequest;
      }

      _showSnackbar('Request approved', 'The budget request has been approved');
      return true;
    } catch (e) {
      _showSnackbar('Error approving request', e.toString(), isError: true);
      return false;
    } finally {
      isSubmitting.value = false;
      selectedOwnerProofFile.value = null;
    }
  }

  // Reject a request
  Future<bool> rejectRequest(
      String workspaceId, String requestId, String reason) async {
    if (reason.isEmpty) {
      _showSnackbar('Rejection reason required',
          'Please provide a reason for rejecting this request',
          isWarning: true);
      return false;
    }

    isSubmitting.value = true;
    try {
      final result = await _requestService.updateStatus(
        workspaceId,
        requestId,
        'rejected',
        rejectionReason: reason,
      );

      // Update local data
      if (result.containsKey('request')) {
        final updatedRequest = RequestModel.fromJson(result['request']);

        // Update in lists
        final reqIndex = requests.indexWhere((req) => req.id == requestId);
        if (reqIndex >= 0) {
          requests[reqIndex] = updatedRequest;
        }

        selectedRequest.value = updatedRequest;
      }

      _showSnackbar('Request rejected', 'The budget request has been rejected');
      rejectionReasonController.clear();
      return true;
    } catch (e) {
      _showSnackbar('Error rejecting request', e.toString(), isError: true);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Delete a request
  Future<bool> deleteRequest(String workspaceId, String requestId) async {
    isSubmitting.value = true;
    try {
      final success = await _requestService.delete(workspaceId, requestId);

      if (success) {
        // Remove from local lists
        requests.removeWhere((req) => req.id == requestId);
        myRequests.removeWhere((req) => req.id == requestId);

        _showSnackbar('Request deleted', 'The budget request has been deleted');
        return true;
      } else {
        throw Exception('Failed to delete request');
      }
    } catch (e) {
      _showSnackbar('Error deleting request', e.toString(), isError: true);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // Set up for editing
  void setupForEdit(RequestModel request) {
    requestItems.assignAll(request.items);
    totalAmount.value = request.amount;
    isEditing.value = true;
    // We don't set the selectedProofFile because we can't access the existing file
    // User will need to upload a new file if they want to change it
  }
}
