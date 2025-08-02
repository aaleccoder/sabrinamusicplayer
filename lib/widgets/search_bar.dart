import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/global_search.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXl,
        boxShadow: AppTheme.shadowLg,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.radiusXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppTheme.radiusXl,
              color: AppTheme.surface,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppTheme.radiusXl,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.02),
                    Colors.white.withOpacity(0.01),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: AppTheme.radiusXl,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GlobalSearchPage(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: AppTheme.paddingMd,
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppTheme.onSurface.withOpacity(0.6),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search songs, albums, artists...',
                            style:
                                AppTheme.textTheme.labelMedium?.copyWith(
                                  color: AppTheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ) ??
                                const TextStyle(),
                          ),
                        ),
                        Icon(
                          Icons.mic,
                          color: AppTheme.primary.withOpacity(0.7),
                          size: 22,
                        ),
                      ],
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
