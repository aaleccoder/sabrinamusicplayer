import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_scanning_state.dart';

class LibraryScanningNotifier extends StateNotifier<LibraryScanningState> {
  LibraryScanningNotifier() : super(const LibraryScanningState());

  void startScanning({required int totalFiles}) {
    state = state.copyWith(
      isScanning: true,
      totalFiles: totalFiles,
      processedFiles: 0,
      currentFile: null,
      errorMessage: null,
    );
  }

  void updateProgress({required int processedFiles, String? currentFile}) {
    state = state.copyWith(
      processedFiles: processedFiles,
      currentFile: currentFile,
    );
  }

  void finishScanning() {
    state = state.copyWith(isScanning: false, currentFile: null);
  }

  void setError(String errorMessage) {
    state = state.copyWith(isScanning: false, errorMessage: errorMessage);
  }

  void reset() {
    state = const LibraryScanningState();
  }
}

final libraryScanningProvider =
    StateNotifierProvider<LibraryScanningNotifier, LibraryScanningState>((ref) {
      return LibraryScanningNotifier();
    });
