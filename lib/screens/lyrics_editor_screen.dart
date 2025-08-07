import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_application_1/widgets/song_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

class LyricsEditorScreen extends ConsumerStatefulWidget {
  final TrackItem track;

  const LyricsEditorScreen({super.key, required this.track});

  @override
  ConsumerState<LyricsEditorScreen> createState() => _LyricsEditorScreenState();
}

class _LyricsEditorScreenState extends ConsumerState<LyricsEditorScreen> {
  late TextEditingController _lyricsController;

  @override
  void initState() {
    super.initState();
    _lyricsController = TextEditingController(text: widget.track.lyrics);
  }

  @override
  void dispose() {
    _lyricsController.dispose();
    super.dispose();
  }

  void _saveLyrics() async {
    final newLyrics = _lyricsController.text;
    if (newLyrics == widget.track.lyrics) {
      Navigator.pop(context);
      return;
    }

    final db = ref.read(appDatabaseProvider);
    await (db.update(db.tracks)..where((t) => t.id.equals(widget.track.id)))
        .write(TracksCompanion(lyrics: Value(newLyrics)));

    ref.invalidate(audioPlayerNotifierProvider);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lyrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLyrics,
            tooltip: 'Save Lyrics',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _lyricsController,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter lyrics here...',
          ),
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurface,
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
