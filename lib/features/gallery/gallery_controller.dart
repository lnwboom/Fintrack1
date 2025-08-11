import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/data/models/photo_model.dart';
import 'package:fintrack/data/repositories/photo_repository.dart';

// สร้าง Provider สำหรับ PhotoRepository
final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl();
});

// สร้าง State สำหรับ Gallery
class GalleryState {
  final List<PhotoModel> photos;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;

  GalleryState({
    required this.photos,
    required this.currentPage,
    required this.hasMore,
    this.isLoading = false,
  });

  // สร้าง State เริ่มต้น
  factory GalleryState.initial() {
    return GalleryState(
      photos: [],
      currentPage: 0,
      hasMore: true,
    );
  }

  // สร้าง State ใหม่โดยคัดลอกค่าจาก State เดิม
  GalleryState copyWith({
    List<PhotoModel>? photos,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
  }) {
    return GalleryState(
      photos: photos ?? this.photos,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// สร้าง StateNotifier สำหรับ Gallery
class GalleryController extends StateNotifier<AsyncValue<GalleryState>> {
  final PhotoRepository _photoRepository;
  static const int _pageSize = 20;

  GalleryController(this._photoRepository) : super(const AsyncValue.loading()) {
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    state = const AsyncValue.loading();

    try {
      final photos =
          await _photoRepository.getPhotos(page: 0, pageSize: _pageSize);
      state = AsyncValue.data(GalleryState(
        photos: photos,
        currentPage: 0,
        hasMore: photos.length == _pageSize,
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMorePhotos() async {
    final currentState = state;

    if (currentState is AsyncData<GalleryState>) {
      final galleryState = currentState.value;

      if (!galleryState.hasMore) return;

      try {
        final nextPage = galleryState.currentPage + 1;
        final newPhotos = await _photoRepository.getPhotos(
          page: nextPage,
          pageSize: _pageSize,
        );

        if (newPhotos.isEmpty) {
          state = AsyncValue.data(galleryState.copyWith(hasMore: false));
          return;
        }

        state = AsyncValue.data(galleryState.copyWith(
          photos: [...galleryState.photos, ...newPhotos],
          currentPage: nextPage,
          hasMore: newPhotos.length == _pageSize,
        ));
      } catch (e, stackTrace) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<void> pickImageFromGallery() async {
    final currentState = state;

    if (currentState is AsyncData<GalleryState>) {
      final galleryState = currentState.value;

      // อัปเดต state เพื่อแสดงว่ากำลังโหลด
      state = AsyncValue.data(galleryState.copyWith(isLoading: true));

      try {
        final photo = await _photoRepository.pickImageFromGallery();

        if (photo != null) {
          state = AsyncValue.data(galleryState.copyWith(
            photos: [photo, ...galleryState.photos],
            isLoading: false,
          ));
        } else {
          state = AsyncValue.data(galleryState.copyWith(isLoading: false));
        }
      } catch (e, stackTrace) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<void> takePhoto() async {
    final currentState = state;

    if (currentState is AsyncData<GalleryState>) {
      final galleryState = currentState.value;

      // อัปเดต state เพื่อแสดงว่ากำลังโหลด
      state = AsyncValue.data(galleryState.copyWith(isLoading: true));

      try {
        final photo = await _photoRepository.takePhoto();

        if (photo != null) {
          state = AsyncValue.data(galleryState.copyWith(
            photos: [photo, ...galleryState.photos],
            isLoading: false,
          ));
        } else {
          state = AsyncValue.data(galleryState.copyWith(isLoading: false));
        }
      } catch (e, stackTrace) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }
}

// สร้าง Provider สำหรับ GalleryController
final galleryControllerProvider =
    StateNotifierProvider<GalleryController, AsyncValue<GalleryState>>((ref) {
  final photoRepository = ref.watch(photoRepositoryProvider);
  return GalleryController(photoRepository);
});
