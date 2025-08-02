import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/metadata_service.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  List<Color> _dominantColors = [AppTheme.primary, AppTheme.background];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: AppTheme.animationSlow,
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppTheme.animationNormal,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideController,
            curve: AppTheme.curveEmphasized,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: AppTheme.curveDefault),
    );

    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<List<Color>> _extractColorsFromImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return [AppTheme.primary, AppTheme.background];
    }

    try {
      final uri = Uri.parse(imagePath);
      if (uri.isScheme('file')) {
        final file = File.fromUri(uri);
        if (file.existsSync()) {
          // This is a simplified color extraction - in a real app you'd use a package like palette_generator
          return [
            AppTheme.primary.withOpacity(0.8),
            AppTheme.secondary.withOpacity(0.6),
            AppTheme.background,
          ];
        }
      }
    } catch (e) {
      // Fallback
    }

    return [AppTheme.primary, AppTheme.background];
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerNotifierProvider.notifier);
    final audioState = ref.watch(audioPlayerNotifierProvider);
    final currentTrack = audioState.currentTrack;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          _slideController.reverse().then((_) {
            Navigator.pop(context);
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _slideController.reverse().then((_) {
                    Navigator.pop(context);
                  });
                },
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.onSurface,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        body: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FutureBuilder<List<Color>>(
              future: _extractColorsFromImage(currentTrack?.cover),
              builder: (context, colorSnapshot) {
                final colors = colorSnapshot.data ?? _dominantColors;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        colors[0].withOpacity(0.6),
                        colors.length > 1
                            ? colors[1].withOpacity(0.4)
                            : colors[0].withOpacity(0.3),
                        AppTheme.background.withOpacity(0.9),
                        AppTheme.background,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          const Spacer(),
                          _buildAlbumArtSection(currentTrack),
                          const SizedBox(height: 40),
                          _buildTrackInfoSection(currentTrack),
                          const Spacer(),
                          _buildControlsSection(audioService, audioState),
                          const SizedBox(height: 20),
                          _buildAudioInfoSection(currentTrack),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArtSection(currentTrack) {
    return AnimatedSwitcher(
      duration: AppTheme.animationSlow,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: currentTrack != null
          ? Hero(
              tag: 'player-artwork',
              child: Container(
                key: ValueKey(currentTrack.id),
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radiusXxl,
                  boxShadow: AppTheme.shadowXl,
                ),
                child: ClipRRect(
                  borderRadius: AppTheme.radiusXxl,
                  child: FutureBuilder<String?>(
                    future: MetadataService().getFullSizeAlbumArt(
                      currentTrack.id.toString(),
                    ),
                    builder: (context, snapshot) {
                      Widget coverArt = Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withOpacity(0.3),
                              AppTheme.secondary.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 80,
                          color: AppTheme.primary,
                        ),
                      );

                      String? artUri = snapshot.data;
                      if (artUri == null || artUri.isEmpty) {
                        artUri = currentTrack.cover;
                      }

                      try {
                        if (artUri != null && artUri.isNotEmpty) {
                          final uri = Uri.parse(artUri);
                          if (uri.isScheme('file')) {
                            final file = File.fromUri(uri);
                            if (file.existsSync()) {
                              coverArt = Image.file(
                                file,
                                width: 320,
                                height: 320,
                                fit: BoxFit.cover,
                              );
                            }
                          }
                        }
                      } catch (e) {
                        // Fallback to placeholder
                      }

                      return AnimatedSwitcher(
                        duration: AppTheme.animationNormal,
                        child: Container(
                          key: Key(artUri ?? 'placeholder'),
                          child: coverArt,
                        ),
                      );
                    },
                  ),
                ),
              ),
            )
          : Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                borderRadius: AppTheme.radiusXxl,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.surface, AppTheme.surfaceVariant],
                ),
                boxShadow: AppTheme.shadowLg,
              ),
              child: Icon(
                Icons.music_off_rounded,
                size: 80,
                color: AppTheme.onSurface.withOpacity(0.5),
              ),
            ),
    );
  }

  Widget _buildTrackInfoSection(currentTrack) {
    return AnimatedSwitcher(
      duration: AppTheme.animationNormal,
      child: currentTrack != null
          ? Container(
              key: ValueKey(currentTrack.id),
              padding: AppTheme.paddingLg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTrack.title,
                          style: AppTheme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentTrack.artist,
                          style: AppTheme.textTheme.bodyLarge?.copyWith(
                            color: AppTheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // TODO: Implement like functionality
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            color: AppTheme.onSurface.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // TODO: Implement menu functionality
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: AppTheme.onSurface.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Text(
              'No track is currently playing',
              style: AppTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurface.withOpacity(0.7),
              ),
            ),
    );
  }

  Widget _buildControlsSection(audioService, audioState) {
    return Container(
      padding: AppTheme.paddingLg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: CupertinoIcons.backward_fill,
            onPressed: audioService.previous,
            size: 60,
            isPrimary: false,
          ),
          AnimatedSwitcher(
            duration: AppTheme.animationNormal,
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _buildControlButton(
              key: ValueKey(audioState.isPlaying),
              icon: audioState.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              onPressed: audioState.isPlaying
                  ? audioService.pause
                  : audioService.unpause,
              size: 80,
              isPrimary: true,
            ),
          ),
          _buildControlButton(
            icon: CupertinoIcons.forward_fill,
            onPressed: audioService.next,
            size: 60,
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAudioInfoSection(currentTrack) {
    return AnimatedSwitcher(
      duration: AppTheme.animationNormal,
      child: currentTrack != null
          ? Container(
              key: ValueKey(currentTrack.id),
              padding: AppTheme.paddingMd,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAudioInfoItem('Bitrate', '320 kbps'),
                  Container(
                    width: 1,
                    height: 16,
                    color: AppTheme.onSurface.withOpacity(0.2),
                  ),
                  _buildAudioInfoItem('Sample Rate', '44.1 kHz'),
                  Container(
                    width: 1,
                    height: 16,
                    color: AppTheme.onSurface.withOpacity(0.2),
                  ),
                  _buildAudioInfoItem('Format', 'FLAC'),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAudioInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.textTheme.labelMedium?.copyWith(
            color: AppTheme.onSurface.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required bool isPrimary,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryDark],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.surfaceVariant, AppTheme.surface],
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : AppTheme.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              icon,
              color: isPrimary ? AppTheme.onPrimary : AppTheme.onSurface,
              size: isPrimary ? size * 0.4 : size * 0.35,
            ),
          ),
        ),
      ),
    );
  }
}
