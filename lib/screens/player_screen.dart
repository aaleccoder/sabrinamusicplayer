import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/metadata_service.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/services/audio_service.dart';
import 'package:palette_generator/palette_generator.dart';
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
          final imageProvider = FileImage(file);
          final palette = await PaletteGenerator.fromImageProvider(
            imageProvider,
            size: const Size(100, 100), // Smaller size for faster processing
          );

          final dominantColor =
              palette.dominantColor?.color ?? AppTheme.primary;
          final vibrantColor =
              palette.vibrantColor?.color ?? AppTheme.secondary;

          return [dominantColor, vibrantColor, AppTheme.background];
        }
      }
    } catch (e) {
      // Fallback to default colors
    }

    return [AppTheme.primary, AppTheme.background];
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioPlayerNotifierProvider.notifier);
    final audioState = ref.watch(audioPlayerNotifierProvider);
    final currentTrack = audioState.currentTrack;

    ref.listen(
      audioPlayerNotifierProvider.select((value) => value.currentTrack),
      (previous, next) {
        if (previous != next && next != null) {
          _extractColorsFromImage(next.cover).then((colors) {
            if (mounted) {
              setState(() {
                _dominantColors = colors;
              });
            }
          });
        }
      },
    );

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
            child: AnimatedContainer(
              duration: AppTheme.animationSlow,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _dominantColors[0].withOpacity(0.8),
                    _dominantColors.length > 1
                        ? _dominantColors[1].withOpacity(0.6)
                        : _dominantColors[0].withOpacity(0.5),
                    AppTheme.background,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Column(
                    children: [
                      const Spacer(),
                      _buildAlbumArtSection(currentTrack),
                      const SizedBox(height: 40),
                      _buildTrackInfoSection(currentTrack),
                      const Spacer(),
                      _buildSeekerSection(audioService, audioState),
                      _buildControlsSection(audioService, audioState),
                      const SizedBox(height: 80),
                      // _buildAudioInfoSection(currentTrack),
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

  Widget _buildAlbumArtSection(currentTrack) {
    return AnimatedSwitcher(
      duration: AppTheme.animationSlow,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(0.5, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(scale: animation, child: child),
          ),
        );
      },
      child: currentTrack != null
          ? Hero(
              tag: 'player-artwork',
              child: Container(
                key: ValueKey(currentTrack.id),
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radiusXxl,
                  // Removed boxShadow and blur, keep only gradient
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
                  // Favorite icon
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          // Toggle liked status
                          currentTrack.liked = !currentTrack.liked;
                          // If liked, it cannot be unliked
                          if (currentTrack.liked) {
                            currentTrack.unliked = false;
                          }

                          // Update UI immediately
                          setState(() {});

                          // Persist change and refresh data providers
                          await ref.read(
                            updateTrackProvider(currentTrack).future,
                          );
                          ref.invalidate(tracksProvider);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentTrack.liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: currentTrack.liked
                                ? AppTheme.error
                                : AppTheme.onSurface.withOpacity(0.7),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unliked icon
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          // Toggle unliked status
                          currentTrack.unliked = !currentTrack.unliked;
                          // If unliked, it cannot be liked
                          if (currentTrack.unliked) {
                            currentTrack.liked = false;
                          }

                          // Update UI immediately
                          setState(() {});

                          // Persist change and refresh data providers
                          await ref.read(
                            updateTrackProvider(currentTrack).future,
                          );
                          ref.invalidate(tracksProvider);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentTrack.unliked != true
                                ? Icons.thumb_down_alt_outlined
                                : Icons.thumb_down_alt_rounded,
                            color: currentTrack.unliked == true
                                ? AppTheme.error
                                : AppTheme.onSurface.withOpacity(0.7),
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

  Widget _buildSeekerSection(
    AudioPlayerNotifier audioService,
    AudioPlayerState audioState,
  ) {
    final duration = audioState.duration ?? Duration.zero;
    final position = audioState.position;

    final double sliderMax = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final double sliderValue = position.inMilliseconds.toDouble().clamp(
      0.0,
      sliderMax,
    );

    return Container(
      padding: AppTheme.paddingLg,
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.onSurface.withOpacity(0.2),
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: sliderValue,
              max: sliderMax,
              onChanged: (value) {
                audioService.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: AppTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: AppTheme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildControlsSection(
    AudioPlayerNotifier audioService,
    AudioPlayerState audioState,
  ) {
    IconData repeatIcon;
    switch (audioState.repeatMode) {
      case RepeatMode.none:
        repeatIcon = Icons.repeat_rounded;
        break;
      case RepeatMode.one:
        repeatIcon = Icons.repeat_one_on_rounded;
        break;
      case RepeatMode.all:
        repeatIcon = Icons.repeat_on_rounded;
        break;
    }

    return Container(
      padding: AppTheme.paddingLg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildControlButton(
            icon: Icons.shuffle_rounded,
            onPressed: audioService.toggleShuffle,
            size: 50,
            isPrimary: false,
            color: audioState.isShuffleActive ? AppTheme.primary : null,
          ),
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
          _buildControlButton(
            icon: repeatIcon,
            onPressed: audioService.cycleRepeatMode,
            size: 50,
            isPrimary: false,
            color: audioState.repeatMode != RepeatMode.none
                ? AppTheme.primary
                : null,
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
    Color? color,
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
        // Removed boxShadow and blur for flat look
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
              color:
                  color ??
                  (isPrimary ? AppTheme.onPrimary : AppTheme.onSurface),
              size: isPrimary ? size * 0.4 : size * 0.35,
            ),
          ),
        ),
      ),
    );
  }
}
