import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_application_1/services/background_audio_handler.dart';

class AudioPlayerState {
  final TrackItem? currentTrack;
  final bool isPlaying;
  final List<TrackItem>? queue;
  final int currentIndex;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;

  AudioPlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.queue,
    this.currentIndex = 0,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration,
  });

  AudioPlayerState copyWith({
    Object? currentTrack = const Object(),
    bool? isPlaying,
    Object? queue = const Object(),
    int? currentIndex,
    Duration? position,
    Duration? bufferedPosition,
    Object? duration = const Object(),
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
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  BackgroundAudioHandler? _audioHandler;
  List<TrackItem> _originalQueue = [];

  AudioPlayerNotifier() : super(AudioPlayerState()) {
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => BackgroundAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId:
            'com.example.flutter_application_1.channel.audio',
        androidNotificationChannelName: 'Music Player',
        androidNotificationChannelDescription: 'Music playback controls',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
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
        position: playbackState.updatePosition,
        bufferedPosition: playbackState.bufferedPosition,
      );
    });

    _audioHandler?.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        final currentTrack = TrackItem(
          id: mediaItem.extras?['trackId'] ?? 0,
          title: mediaItem.title,
          artist: mediaItem.artist ?? '',
          cover: mediaItem.artUri?.toString() ?? '',
          fileuri: mediaItem.id,
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
              id: mediaItem.extras?['trackId'] ?? 0,
              title: mediaItem.title,
              artist: mediaItem.artist ?? '',
              cover: mediaItem.artUri?.toString() ?? '',
              fileuri: mediaItem.id,
            ),
          )
          .toList();

      state = state.copyWith(
        queue: trackQueue,
        currentIndex: _audioHandler?.currentIndex ?? 0,
      );
    });
  }

  Future<void> createQueue(List<TrackItem> tracks) async {
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
    if (_audioHandler == null) return;

    // If it's a new track, play it with the current queue
    if (state.currentTrack?.fileuri != track.fileuri) {
      final currentQueue = state.queue ?? [track];
      await _audioHandler!.playTrack(track, currentQueue);
    } else {
      // Just resume playback
      await _audioHandler!.play();
    }
  }

  Future<void> next() async {
    if (_audioHandler != null) {
      await _audioHandler!.skipToNext();
    }
  }

  Future<void> previous() async {
    if (_audioHandler != null) {
      await _audioHandler!.skipToPrevious();
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
    if (tracks.isNotEmpty && _audioHandler != null) {
      await createQueue(tracks);
      await _audioHandler!.shuffleQueue();
      await _audioHandler!.play();
    }
  }

  /// Get the audio handler for direct access
  BackgroundAudioHandler? get audioHandler => _audioHandler;

  /// Set repeat mode
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (_audioHandler != null) {
      await _audioHandler!.setRepeatMode(repeatMode);
    }
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
    if (_audioHandler != null) {
      await _audioHandler!.customAction('shuffle');
    }
  }
}
