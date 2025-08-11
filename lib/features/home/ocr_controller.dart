import 'dart:io';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:fintrack/features/home/service/ocr_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Controller for OCR-related operations.
/// Manages image selection, OCR processing, and state management.
class OcrController extends ChangeNotifier {
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _selectedImages = [];
  List<TransactionModel> _processedTransactions = [];
  TransactionModel? _previewTransaction;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get selectedImages => _selectedImages;
  List<TransactionModel> get processedTransactions => _processedTransactions;
  TransactionModel? get previewTransaction => _previewTransaction;
  bool get hasSelectedImages => _selectedImages.isNotEmpty;

  /// Select image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        await _addImage(pickedFile);
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Capture image from camera
  Future<void> captureImageFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        await _addImage(pickedFile);
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Add image to selected images
  Future<void> _addImage(XFile pickedFile) async {
    final bytes = await pickedFile.readAsBytes();
    final fileName = pickedFile.name;
    
    _selectedImages.add({
      'file': pickedFile,
      'bytes': bytes,
      'fileName': fileName,
      'path': pickedFile.path,
    });
    
    notifyListeners();
  }

  /// Remove image at index
  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all selected images
  void clearImages() {
    _selectedImages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Process single image for OCR preview
  Future<void> processImagePreview(int index) async {
    if (index < 0 || index >= _selectedImages.length) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final image = _selectedImages[index];
      final imageBytes = image['bytes'] as List<int>;
      final fileName = image['fileName'] as String;
      
      // Check for duplicates
      final isDuplicate = await _ocrService.checkDuplicateImage(
        imageBytes: imageBytes,
      );
      
      if (isDuplicate) {
        _errorMessage = 'This receipt has already been processed.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Get OCR preview
      final previewData = await _ocrService.getOcrProcessingPreview(
        imageBytes: imageBytes,
        fileName: fileName,
      );
      
      if (previewData != null) {
        _previewTransaction = TransactionModel.fromJson(previewData);
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'Failed to process receipt. Please try again.';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error processing image: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Process all selected images for OCR
  Future<List<TransactionModel>> processAllImages() async {
    if (_selectedImages.isEmpty) {
      _errorMessage = 'Please select at least one image.';
      notifyListeners();
      return [];
    }
    
    _isLoading = true;
    _errorMessage = null;
    _processedTransactions = [];
    notifyListeners();
    
    try {
      final images = _selectedImages.map((img) => {
        'bytes': img['bytes'] as List<int>,
        'fileName': img['fileName'] as String,
      }).toList();
      
      _processedTransactions = await _ocrService.uploadImagesForOcr(images: images);
      _isLoading = false;
      
      if (_processedTransactions.isEmpty) {
        _errorMessage = 'No transactions were created. Please try again.';
      } else {
        // Clear selected images after successful processing
        _selectedImages = [];
      }
      
      notifyListeners();
      return _processedTransactions;
    } catch (e) {
      _errorMessage = 'Error processing images: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  /// Process a single image for OCR
  Future<TransactionModel?> processSingleImage(int index) async {
    if (index < 0 || index >= _selectedImages.length) return null;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final image = _selectedImages[index];
      final imageBytes = image['bytes'] as List<int>;
      final fileName = image['fileName'] as String;
      
      final transaction = await _ocrService.uploadImageForOcr(
        imageBytes: imageBytes,
        fileName: fileName,
      );
      
      _isLoading = false;
      
      if (transaction != null) {
        _processedTransactions.add(transaction);
        _selectedImages.removeAt(index);
      } else {
        _errorMessage = 'Failed to process receipt.';
      }
      
      notifyListeners();
      return transaction;
    } catch (e) {
      _errorMessage = 'Error processing image: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Save edited preview transaction
  Future<TransactionModel?> saveEditedTransaction(TransactionModel editedTransaction) async {
    if (_previewTransaction == null) return null;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // This is a simplified implementation - in a real app, you'd call an API
      // to update the transaction with the edited values
      _processedTransactions.add(editedTransaction);
      _previewTransaction = null;
      _isLoading = false;
      notifyListeners();
      return editedTransaction;
    } catch (e) {
      _errorMessage = 'Error saving transaction: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Reset error state
  void resetError() {
    _errorMessage = null;
    notifyListeners();
  }
}