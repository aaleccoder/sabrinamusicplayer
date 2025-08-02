import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_scanning_provider.dart';
import '../theme.dart';

class LibraryScanningOverlay extends ConsumerStatefulWidget {
  const LibraryScanningOverlay({super.key});

  @override
  ConsumerState<LibraryScanningOverlay> createState() =>
      _LibraryScanningOverlayState();
}

class _LibraryScanningOverlayState extends ConsumerState<LibraryScanningOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: AppTheme.curveDefault),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanningState = ref.watch(libraryScanningProvider);

    if (!scanningState.isScanning) {
      if (_fadeController.value > 0) {
        _fadeController.reverse();
      }
      return const SizedBox.shrink();
    } else {
      if (_fadeController.value == 0) {
        _fadeController.forward();
      }
    }

    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.black.withOpacity(0.8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radiusXl,
                  boxShadow: AppTheme.shadowXl,
                ),
                child: ClipRRect(
                  borderRadius: AppTheme.radiusXl,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: AppTheme.paddingXl,
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.radiusXl,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primary.withOpacity(0.3),
                                    AppTheme.secondary.withOpacity(0.2),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.library_music_rounded,
                                size: 48,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Scanning Music Library',
                            style: AppTheme.textTheme.titleLarge?.copyWith(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Discovering your music collection...',
                            style: AppTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (scanningState.totalFiles > 0) ...[
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: AppTheme.radiusLg,
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: ClipRRect(
                                borderRadius: AppTheme.radiusLg,
                                child: LinearProgressIndicator(
                                  value: scanningState.progress,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.1,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primary,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              scanningState.progressText,
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (scanningState.currentFile != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: AppTheme.paddingSm,
                                decoration: BoxDecoration(
                                  borderRadius: AppTheme.radiusMd,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                child: Text(
                                  'Processing: ${scanningState.currentFile}',
                                  style: AppTheme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurface.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ] else ...[
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Initializing scan...',
                              style: AppTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                          if (scanningState.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: AppTheme.paddingMd,
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: AppTheme.radiusMd,
                                border: Border.all(
                                  color: AppTheme.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: AppTheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      scanningState.errorMessage!,
                                      style: AppTheme.textTheme.bodySmall
                                          ?.copyWith(color: AppTheme.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(libraryScanningProvider.notifier)
                                    .reset();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                              ),
                              child: const Text('Dismiss'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
