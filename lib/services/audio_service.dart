import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_application_1/services/background_audio_handler.dart';

enum RepeatMode { none, one, all }

class AudioPlayerState {
  final TrackItem? currentTrack;
  final bool isPlaying;
  final List<TrackItem>? queue;
  final int currentIndex;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;
  final bool isShuffleActive;
  final RepeatMode repeatMode;

  AudioPlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.queue,
    this.currentIndex = 0,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration,
    this.isShuffleActive = false,
    this.repeatMode = RepeatMode.none,
  });

  AudioPlayerState copyWith({
    Object? currentTrack = const Object(),
    bool? isPlaying,
    Object? queue = const Object(),
    int? currentIndex,
    Duration? position,
    Duration? bufferedPosition,
    Object? duration = const Object(),
    bool? isShuffleActive,
    RepeatMode? repeatMode,
  }) {
    return AudioPlayerState(
      currentTrack: identical(currentTrack, const Object())
          ? this.currentTrack
          : currentTrack as TrackItem?,
      isPlaying: isPlaying ?? this.isPlaying,
      queue: identical(queue, const Object())
          ? this.queue
          : queue as List<TrackItem>?,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: identical(duration, const Object())
          ? this.duration
          : duration as Duration?,
      isShuffleActive: isShuffleActive ?? this.isShuffleActive,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  BackgroundAudioHandler? _audioHandler;
  List<TrackItem> _originalQueue = [];
  final Completer<void> _initializationCompleter = Completer<void>();
  int _skipRequests = 0;
  bool _isProcessingSkips = false;

  final Ref _ref;

  AudioPlayerNotifier(this._ref) : super(AudioPlayerState()) {
    _initializeAudioService();

    // Listen to track updates and refresh the current track if it's playing
    _ref.listen(tracksProvider(SortOption.alphabeticalAZ), (previous, next) {
      final tracks = next.asData?.value;
      if (tracks != null && state.currentTrack != null) {
        try {
          final updatedTrack = tracks.firstWhere(
            (t) => t.id == state.currentTrack!.id,
          );
          if (state.currentTrack!.liked != updatedTrack.liked ||
              state.currentTrack!.unliked != updatedTrack.unliked) {
            state = state.copyWith(currentTrack: updatedTrack);
          }
        } catch (e) {
          // Track not found, do nothing
        }
      }
    });
  }

  StreamSubscription<Duration>? _positionSubscription;

  Future<void> _initializeAudioService() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => BackgroundAudioHandler(),
        config: AudioServiceConfig(
          androidNotificationChannelId:
              'com.example.flutter_application_1.channel.audio',
          androidNotificationChannelName: 'Music Player',
          androidNotificationChannelDescription: 'Music playback controls',
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidShowNotificationBadge: true,
          androidStopForegroundOnPause: true,
          fastForwardInterval: const Duration(seconds: 10),
          rewindInterval: const Duration(seconds: 10),
          preloadArtwork: true,
          artDownscaleWidth: 200,
          artDownscaleHeight: 200,
        ),
      );

      // Listen to audio handler events and update state
      _audioHandler?.playbackState.listen((playbackState) {
        state = state.copyWith(
          isPlaying: playbackState.playing,
          bufferedPosition: playbackState.bufferedPosition,
        );
      });

      // Listen to positionStream for frequent position updates
      if (_audioHandler != null && _audioHandler is BackgroundAudioHandler) {
        final handler = _audioHandler as BackgroundAudioHandler;
        _positionSubscription = handler.positionStream.listen((pos) {
          state = state.copyWith(position: pos);
        });
      }

      _audioHandler?.mediaItem.listen((mediaItem) {
        if (mediaItem != null) {
          final currentTrack = TrackItem(
            liked: mediaItem.extras?['liked'] ?? false,
            unliked: mediaItem.extras?['unliked'] ?? false,
            id: mediaItem.extras?['trackId'] ?? 0,
            title: mediaItem.title,
            artist: mediaItem.artist ?? '',
            cover: mediaItem.artUri?.toString() ?? '',
            fileuri: mediaItem.id,
            album: mediaItem.album,
            year: mediaItem.extras?['year'],
            createdAt: DateTime.parse(mediaItem.extras!['createdAt'] as String),
          );

          state = state.copyWith(
            currentTrack: currentTrack,
            duration: mediaItem.duration,
          );
        }
      });

      _audioHandler?.queue.listen((queue) {
        final trackQueue = queue
            .map(
              (mediaItem) => TrackItem(
                liked: mediaItem.extras?['liked'] ?? false,
                unliked: mediaItem.extras?['unliked'] ?? false,
                id: mediaItem.extras?['trackId'] ?? 0,
                title: mediaItem.title,
                artist: mediaItem.artist ?? '',
                cover: mediaItem.artUri?.toString() ?? '',
                fileuri: mediaItem.id,
                album: mediaItem.album,
                year: mediaItem.extras?['year'],
                createdAt: DateTime.parse(
                  mediaItem.extras!['createdAt'] as String,
                ),
              ),
            )
            .toList();

        state = state.copyWith(
          queue: trackQueue,
          currentIndex: _audioHandler?.currentIndex ?? 0,
        );
      });
      // ... existing listeners setup ...

      _initializationCompleter.complete();
    } catch (e) {
      _initializationCompleter.completeError(e);
    }
  }

  Future<void> createQueue(List<TrackItem> tracks) async {
    try {
      await _initializationCompleter.future;
    } catch (e) {
      debugPrint('AudioService initialization failed, not initialized: $e');
      return;
    }

    if (tracks.isNotEmpty && _audioHandler != null) {
      _originalQueue = List.from(tracks);
      final mediaItems = tracks
          .map(BackgroundAudioHandler.trackToMediaItem)
          .toList();
      await _audioHandler!.addQueueItems(mediaItems);

      state = state.copyWith(
        queue: tracks,
        currentTrack: tracks[0],
        currentIndex: 0,
        position: Duration.zero,
        bufferedPosition: Duration.zero,
      );
    }
  }

  Future<void> play(TrackItem track) async {
    try {
      await _initializationCompleter.future;
    } catch (e) {
      debugPrint('AudioService initialization failed: $e');
      return;
    }

    if (_audioHandler == null) return;

    // Always call playTrack to ensure the audio source is set for the selected track
    final currentQueue = state.queue ?? [track];
    await _audioHandler!.playTrack(track, currentQueue);
  }

  void next() {
    _skipRequests++;
    _processSkipRequests();
  }

  void previous() {
    _skipRequests--;
    _processSkipRequests();
  }

  Future<void> _processSkipRequests() async {
    if (_isProcessingSkips || _audioHandler == null) return;

    _isProcessingSkips = true;

    try {
      while (_skipRequests != 0) {
        if (_skipRequests > 0) {
          await _audioHandler!.skipToNext();
          _skipRequests--;
        } else {
          await _audioHandler!.skipToPrevious();
          _skipRequests++;
        }
        // Add a small delay to allow the UI to update and prevent blocking
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      _isProcessingSkips = false;
    }
  }

  Future<void> unpause() async {
    if (_audioHandler != null) {
      await _audioHandler!.play();
    }
  }

  Future<void> pause() async {
    if (_audioHandler != null) {
      await _audioHandler!.pause();
    }
  }

  Future<void> stop() async {
    if (_audioHandler != null) {
      await _audioHandler!.stop();
    }
    state = state.copyWith(
      position: Duration.zero,
      bufferedPosition: Duration.zero,
    );
  }

  Future<void> clearQueue() async {
    await stop();
    state = state.copyWith(
      queue: [],
      currentTrack: null,
      currentIndex: 0,
      duration: null,
    );
  }

  Future<void> seek(Duration position) async {
    if (_audioHandler != null) {
      await _audioHandler!.seek(position);
    }
  }

  Future<void> playAllShuffled(List<TrackItem> tracks) async {
    try {
      await _initializationCompleter.future;
    } catch (e) {
      debugPrint('AudioService initialization failed: $e');
      return;
    }

    if (tracks.isNotEmpty && _audioHandler != null) {
      await createQueue(tracks);
      await _audioHandler!.shuffleQueue();
      final shuffledQueue = state.queue ?? [];
      if (shuffledQueue.isNotEmpty) {
        await play(shuffledQueue[0]);
      } else {
        await _audioHandler!.play();
      }
    }
  }

  /// Get the audio handler for direct access
  BackgroundAudioHandler? get audioHandler => _audioHandler;

  /// Set repeat mode
  Future<void> setRepeatMode(RepeatMode repeatMode) async {
    state = state.copyWith(repeatMode: repeatMode);
    final audioServiceRepeatMode =
        AudioServiceRepeatMode.values[repeatMode.index];
    await _audioHandler?.setRepeatMode(audioServiceRepeatMode);
  }

  /// Set shuffle mode
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (_audioHandler != null) {
      await _audioHandler!.setShuffleMode(shuffleMode);
    }
  }

  /// Get current repeat mode
  AudioServiceRepeatMode get repeatMode =>
      _audioHandler?.repeatMode ?? AudioServiceRepeatMode.none;

  /// Get current shuffle mode
  AudioServiceShuffleMode get shuffleMode =>
      _audioHandler?.shuffleMode ?? AudioServiceShuffleMode.none;

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    final isShuffleActive = !state.isShuffleActive;
    state = state.copyWith(isShuffleActive: isShuffleActive);

    if (isShuffleActive) {
      final currentQueue = state.queue;
      if (currentQueue != null && currentQueue.isNotEmpty) {
        _originalQueue = List.from(currentQueue);
        final shuffledQueue = List<TrackItem>.from(currentQueue)..shuffle();
        final List<MediaItem> mediaItems = shuffledQueue
            .map(BackgroundAudioHandler.trackToMediaItem)
            .toList();
        await _audioHandler?.updateQueue(mediaItems);
        state = state.copyWith(queue: shuffledQueue);
      }
    } else {
      final List<MediaItem> mediaItems = _originalQueue
          .map(BackgroundAudioHandler.trackToMediaItem)
          .toList();
      await _audioHandler?.updateQueue(mediaItems);
      state = state.copyWith(queue: _originalQueue);
    }
  }

  void cycleRepeatMode() {
    final currentMode = state.repeatMode;
    final nextMode =
        RepeatMode.values[(currentMode.index + 1) % RepeatMode.values.length];
    setRepeatMode(nextMode);
  }
}
