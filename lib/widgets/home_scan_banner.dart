import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_scanning_provider.dart';
import '../theme.dart';

class HomeScanBanner extends ConsumerWidget {
  const HomeScanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(libraryScanningProvider);

    if (!scanState.isScanning) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scanning music library...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (scanState.totalFiles > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    scanState.progressText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (scanState.totalFiles > 0)
            Text(
              '${(scanState.progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
