import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens/player_screen.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController,
            curve: AppTheme.curveDefault,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: AppTheme.curveDefault),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerNotifierProvider.notifier);
    final audioState = ref.watch(audioPlayerNotifierProvider);
    final currentTrack = audioState.currentTrack;

    if (currentTrack == null) {
      return const SizedBox.shrink();
    }

    // Start slide animation when track is available
    if (!_slideController.isAnimating && _slideController.value == 0) {
      _slideController.forward();
    }

    final colorScheme = Theme.of(context).colorScheme;

    void onPressed() {
      if (audioState.isPlaying) {
        audioService.pause();
      } else {
        audioService.unpause();
      }
    }

    void onTapDown(TapDownDetails details) {
      _scaleController.forward();
    }

    void onTapUp(TapUpDetails details) {
      _scaleController.reverse();
    }

    void onTapCancel() {
      _scaleController.reverse();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTapDown: onTapDown,
          onTapUp: onTapUp,
          onTapCancel: onTapCancel,
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: AppTheme.animationSlowest,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PlayerScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      final curvedAnimation = CurvedAnimation(
                        parent: animation,
                        curve: AppTheme.curveEmphasized,
                      );
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: SizeTransition(
                          sizeFactor: curvedAnimation,
                          axisAlignment: -1.0,
                          child: child,
                        ),
                      );
                    },
              ),
            );
          },
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppTheme.radiusXl,
                boxShadow: AppTheme.shadowLg,
              ),
              child: ClipRRect(
                borderRadius: AppTheme.radiusXl,
                child: Container(
                  // Removed BackdropFilter and blur
                  padding: AppTheme.paddingMd,
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.radiusXl,
                    color: Colors.black.withOpacity(0.90),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.13),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildAlbumArt(currentTrack, colorScheme),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTrackInfo(currentTrack, context)),
                      const SizedBox(width: 12),
                      _buildPlayButton(onPressed, audioState, colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(currentTrack, ColorScheme colorScheme) {
    return Hero(
      tag: 'player-artwork',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusMd,
          boxShadow: AppTheme.shadowMd,
        ),
        child: ClipRRect(
          borderRadius: AppTheme.radiusMd,
          child: () {
            try {
              if (currentTrack.cover.isNotEmpty) {
                final coverUri = Uri.parse(currentTrack.cover);
                if (coverUri.isScheme('file')) {
                  final file = File.fromUri(coverUri);
                  if (file.existsSync()) {
                    return Image.file(
                      file,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    );
                  }
                }
              }
            } catch (e) {
              // Fall back to placeholder
            }
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
            );
          }(),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(currentTrack, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currentTrack.title,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          currentTrack.artist,
          style: AppTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.onSurface.withOpacity(0.7),
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildPlayButton(
    VoidCallback onPressed,
    audioState,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              audioState.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: AppTheme.onPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
