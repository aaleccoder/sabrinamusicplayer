class LibraryScanningState {
  final bool isScanning;
  final int totalFiles;
  final int processedFiles;
  final String? currentFile;
  final String? errorMessage;

  const LibraryScanningState({
    this.isScanning = false,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.currentFile,
    this.errorMessage,
  });

  LibraryScanningState copyWith({
    bool? isScanning,
    int? totalFiles,
    int? processedFiles,
    String? currentFile,
    String? errorMessage,
  }) {
    return LibraryScanningState(
      isScanning: isScanning ?? this.isScanning,
      totalFiles: totalFiles ?? this.totalFiles,
      processedFiles: processedFiles ?? this.processedFiles,
      currentFile: currentFile ?? this.currentFile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get progress {
    if (totalFiles == 0) return 0.0;
    return processedFiles / totalFiles;
  }

  String get progressText {
    return '$processedFiles / $totalFiles songs processed';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LibraryScanningState &&
        other.isScanning == isScanning &&
        other.totalFiles == totalFiles &&
        other.processedFiles == processedFiles &&
        other.currentFile == currentFile &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return isScanning.hashCode ^
        totalFiles.hashCode ^
        processedFiles.hashCode ^
        currentFile.hashCode ^
        errorMessage.hashCode;
  }
}
