import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackItem {
  final String title;
  final String artist;
  final String cover;
  final String fileuri;

  TrackItem({
    required this.title,
    required this.artist,
    required this.cover,
    required this.fileuri,
  });
}

class SongListView extends ConsumerWidget {
  const SongListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(tracksProvider);

    return Padding(
      padding: AppTheme.paddingSm,
      child: tracksAsync.when(
        data: (tracks) => ListView.separated(
          itemCount: tracks.length,
          itemBuilder: (context, index) =>
              SongListViewItem(track: tracks[index]),
          separatorBuilder: (context, index) =>
              const Divider(height: 10, color: Colors.transparent),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class SongListViewItem extends ConsumerStatefulWidget {
  final TrackItem track;

  const SongListViewItem({super.key, required this.track});

  @override
  _SongListViewItemState createState() => _SongListViewItemState();
}

class _SongListViewItemState extends ConsumerState<SongListViewItem> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppTheme.paddingSm,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppTheme.radiusMd,
      ),
      child: Row(
        spacing: 10,
        children: [
          File(widget.track.cover).existsSync()
              ? Image.file(
                  File(widget.track.cover),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey,
                  child: Icon(Icons.music_note, color: Colors.white),
                ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.track.title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  widget.track.artist,
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(CupertinoIcons.ellipsis),
          ),
        ],
      ),
    );
  }
}
