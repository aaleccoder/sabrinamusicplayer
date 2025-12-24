import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/screens/lyrics_editor_screen.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/services/audio_service.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/services/lyrics_service.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/utils/lrc_parser.dart';
import 'package:drift/drift.dart' hide Column;

Future<List<Color>> _extractColorsFromImage(String? imagePath) async {
  if (imagePath == null || imagePath.isEmpty) {
    debugPrint("Got here nothing working");
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
          size: const Size(16, 16),
        );

        final dominantColor = palette.dominantColor?.color ?? AppTheme.primary;
        final vibrantColor = palette.vibrantColor?.color ?? AppTheme.secondary;

        return [dominantColor, vibrantColor, AppTheme.background];
      }
    }
  } catch (e) {
    // Fallback to default colors
  }

  return [AppTheme.primary, AppTheme.background];
}

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
  List<Color>? _previousColors;
  final Map<int, List<Color>> _colorCache = {};
  bool _showLyrics = false;
  final ScrollController _lyricsScrollController = ScrollController();
  final Map<int, GlobalKey> _lyricKeys = {};

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

    final currentTrack = ref.read(audioPlayerNotifierProvider).currentTrack;
    if (currentTrack != null) {
      _updateColors(currentTrack);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  void _updateColors(TrackItem track, {bool prefetchNext = true}) async {
    print(
      '[_updateColors] called for track: ${track.title}, fullCover: ${track.fullCover}, mounted: $mounted',
    );
    // Store current colors as previous
    _previousColors = _dominantColors;

    if (_colorCache.containsKey(track.id)) {
      if (mounted) {
        setState(() {
          _dominantColors = _colorCache[track.id]!;
        });
      } else {
        print(
          '[_updateColors] Widget not mounted, skipping setState for cached colors.',
        );
      }
      if (prefetchNext) {
        _prefetchNextTrackColors();
      }
      return;
    }

    // Fetch the small cover art
    // Only read ref if mounted
    if (!mounted) {
      print('[_updateColors] Widget not mounted, skipping ref.read for db.');
      return;
    }
    final newColors = await _extractColorsFromImage(track.cover);

    if (mounted) {
      setState(() {
        _dominantColors = newColors;
        _colorCache[track.id] = newColors;
      });
    } else {
      print(
        '[_updateColors] Widget not mounted, skipping setState for new colors.',
      );
    }

    if (prefetchNext) {
      _prefetchNextTrackColors();
    }
  }

  void _prefetchNextTrackColors() async {
    print('[_prefetchNextTrackColors] called, mounted: $mounted');
    // Only read ref if mounted
    if (!mounted) {
      print(
        '[_prefetchNextTrackColors] Widget not mounted, skipping ref.read for audioState.',
      );
      return;
    }
    final audioState = ref.read(audioPlayerNotifierProvider);
    final queue = audioState.queue;
    if (queue == null || queue.isEmpty) return;

    final nextIndex = audioState.currentIndex + 1;
    if (nextIndex < queue.length) {
      final nextTrack = queue[nextIndex];
      if (!_colorCache.containsKey(nextTrack.id)) {
        // Only read ref if mounted
        if (!mounted) {
          print(
            '[_prefetchNextTrackColors] Widget not mounted, skipping ref.read for db (next track).',
          );
          return;
        }
        final colors = await _extractColorsFromImage(nextTrack.cover);
        if (mounted) {
          _colorCache[nextTrack.id] = colors;
        } else {
          print(
            '[_prefetchNextTrackColors] Widget not mounted, skipping color cache update.',
          );
        }
      }
    }
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
          _updateColors(next);
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
                  end: Alignment.center,
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
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: AppTheme.animationSlow,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                          child: _showLyrics
                              ? _buildLyricsView(currentTrack, audioState)
                              : _buildPlayerView(
                                  currentTrack,
                                  audioService,
                                  audioState,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                _showLyrics
                                    ? CupertinoIcons.music_note_2
                                    : CupertinoIcons.text_alignleft,
                                color: AppTheme.onSurface.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showLyrics = !_showLyrics;
                                });
                              },
                              tooltip: _showLyrics
                                  ? 'Show Player'
                                  : 'Show Lyrics',
                            ),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.pencil_ellipsis_rectangle,
                                color: AppTheme.onSurface.withOpacity(0.7),
                              ),
                              onPressed: () {
                                if (currentTrack != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LyricsEditorScreen(
                                        track: currentTrack,
                                      ),
                                    ),
                                  );
                                }
                              },
                              tooltip: 'Edit Lyrics',
                            ),
                          ],
                        ),
                      ),
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
                decoration: BoxDecoration(borderRadius: AppTheme.radiusXxl),
                child: ClipRRect(
                  borderRadius: AppTheme.radiusXxl,
                  child: Builder(
                    builder: (context) {
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

                      String? artUri = currentTrack.fullCover;

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
                        print(
                          '[_buildAlbumArtSection] Error loading image: $e',
                        );
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
              activeTrackColor: _dominantColors[0],
              inactiveTrackColor: AppTheme.onSurface.withOpacity(0.2),
              thumbColor: _dominantColors[1],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _buildControlButton(
              icon: Icons.shuffle_rounded,
              onPressed: audioService.toggleShuffle,
              size: 44,
              isPrimary: false,
              color: audioState.isShuffleActive ? AppTheme.primary : null,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _buildControlButton(
              icon: CupertinoIcons.backward_fill,
              onPressed: audioService.previous,
              size: 52,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: AnimatedSwitcher(
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
                size: 68,
                isPrimary: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: _buildControlButton(
              icon: CupertinoIcons.forward_fill,
              onPressed: audioService.next,
              size: 52,
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _buildControlButton(
              icon: repeatIcon,
              onPressed: audioService.cycleRepeatMode,
              size: 44,
              isPrimary: false,
              color: audioState.repeatMode != RepeatMode.none
                  ? AppTheme.primary
                  : null,
            ),
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
                colors: [_dominantColors[0], _dominantColors[1]],
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

  Widget _buildPlayerView(
    TrackItem? currentTrack,
    AudioPlayerNotifier audioService,
    AudioPlayerState audioState,
  ) {
    return Column(
      key: const ValueKey('player_view'),
      children: [
        const Spacer(),
        _buildAlbumArtSection(currentTrack),
        const SizedBox(height: 24),
        _buildTrackInfoSection(currentTrack),
        const Spacer(),
        _buildSeekerSection(audioService, audioState),
        _buildControlsSection(audioService, audioState),
      ],
    );
  }

  Widget _buildLyricsView(
    TrackItem? currentTrack,
    AudioPlayerState audioState,
  ) {
    final lyrics = currentTrack?.lyrics;

    return Column(
      key: const ValueKey('lyrics_view'),
      children: [
        const Spacer(),
        Expanded(
          flex: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: AppTheme.radiusMd,
            ),
            child: lyrics != null && lyrics.isNotEmpty
                ? _buildSyncedLyrics(lyrics, audioState.position)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No lyrics available for this song.',
                          style: TextStyle(color: AppTheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (currentTrack != null) {
                              debugPrint(
                                '[PlayerScreen] Starting lyrics fetch for: ${currentTrack.title}',
                              );
                              try {
                                final lyrics = await LyricsService()
                                    .fetchLyrics(
                                      currentTrack.title,
                                      currentTrack.artist,
                                      album: currentTrack.album,
                                      durationSeconds:
                                          audioState.duration?.inSeconds,
                                    );
                                debugPrint(
                                  '[PlayerScreen] Lyrics fetch completed, mounted: $mounted',
                                );
                                if (lyrics != null && mounted) {
                                  final db = ref.read(appDatabaseProvider);
                                  db.update(db.tracks)
                                    ..where((t) => t.id.equals(currentTrack.id))
                                    ..write(
                                      TracksCompanion(lyrics: Value(lyrics)),
                                    );

                                  // Update the current track with the new lyrics
                                  currentTrack.lyrics = lyrics;

                                  // Update the audio player state with the updated track
                                  final audioNotifier = ref.read(
                                    audioPlayerNotifierProvider.notifier,
                                  );
                                  final currentState = ref.read(
                                    audioPlayerNotifierProvider,
                                  );
                                  audioNotifier.state = currentState.copyWith(
                                    currentTrack: currentTrack,
                                  );

                                  // Also refresh tracks provider for consistency
                                  ref.invalidate(tracksProvider);

                                  // Force UI rebuild to show the new lyrics
                                  setState(() {});

                                  debugPrint(
                                    '[PlayerScreen] Lyrics updated in database, audio player state, and UI refreshed',
                                  );
                                } else if (!mounted) {
                                  debugPrint(
                                    '[PlayerScreen] Widget not mounted, skipping lyrics update - POTENTIAL ERROR SOURCE',
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  '[PlayerScreen] Error fetching lyrics: $e',
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Fetch Lyrics'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildSyncedLyrics(String lyrics, Duration currentPosition) {
    final lrcLines = LrcParser.parse(lyrics);

    if (lrcLines.isEmpty) {
      // Fallback to plain text display if not in LRC format
      return SingleChildScrollView(
        padding: AppTheme.paddingLg,
        child: Text(
          lyrics,
          textAlign: TextAlign.center,
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurface,
            height: 1.8,
            fontSize: 18,
          ),
        ),
      );
    }

    final currentLineIndex = LrcParser.getCurrentLineIndex(
      lrcLines,
      currentPosition,
    );

    // Auto-scroll to center the current line
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentLineIndex >= 0) {
        final key = _lyricKeys[currentLineIndex];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: AppTheme.animationFast,
            curve: Curves.easeOut,
            alignment: 0.5, // Centers the item in the viewport
          );
        }
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.builder(
          controller: _lyricsScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          itemCount: lrcLines.length,
          itemBuilder: (context, index) {
            final line = lrcLines[index];
            final isActive = index == currentLineIndex;
            final isPast = index < currentLineIndex;

            // Ensure we have a GlobalKey for this index
            _lyricKeys[index] ??= GlobalKey();

            return Padding(
              key: _lyricKeys[index],
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: AnimatedDefaultTextStyle(
                duration: AppTheme.animationFast,
                style: AppTheme.textTheme.bodyLarge!.copyWith(
                  color: isActive
                      ? _dominantColors[0]
                      : isPast
                      ? AppTheme.onSurface.withOpacity(0.4)
                      : AppTheme.onSurface.withOpacity(0.6),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  fontSize: isActive ? 32 : 24,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                child: Text(line.text.isEmpty ? '♪' : line.text),
              ),
            );
          },
        );
      },
    );
  }
}
