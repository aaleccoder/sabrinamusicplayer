import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/theme.dart';

class SongListView extends StatefulWidget {
  const SongListView({super.key});

  @override
  _SongListViewState createState() => _SongListViewState();
}

class _SongListViewState extends State<SongListView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.paddingSm,
      child: ListView(children: [SongListViewItem()]),
    );
  }
}

class SongListViewItem extends StatefulWidget {
  const SongListViewItem({super.key});

  @override
  _SongListViewItemState createState() => _SongListViewItemState();
}

class _SongListViewItemState extends State<SongListViewItem> {
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
          Image.network(
            'https://placehold.co/800x800.png',
            height: 40,
            width: 40,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We will rock you",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text("Queen", textAlign: TextAlign.start),
            ],
          ),

          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
