import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_1/services/metadata_service.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  _MetadataScreenState createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  final MetadataService _metadataService = MetadataService();
  Map<String, String?>? _metadata;
  String? _filePath;
  Uint8List? _albumArt;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _metadata = null;
        _albumArt = null;
      });
      if (_filePath != null) {
        final metadata = await _metadataService.getMetadata(_filePath!);
        setState(() {
          _metadata = metadata;
          if (metadata.containsKey('album_art')) {
            _albumArt = base64Decode(metadata['album_art']!);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metadata Extractor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Pick Audio File'),
            ),
            if (_filePath != null) ...[
              const SizedBox(height: 20),
              Text('File: $_filePath'),
            ],
            if (_albumArt != null) ...[
              const SizedBox(height: 20),
              Image.memory(_albumArt!, height: 200),
            ],
            if (_metadata != null) ...[
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: _metadata!.entries
                      .where((entry) => entry.key != 'album_art')
                      .map((entry) {
                        return ListTile(
                          title: Text(entry.key),
                          subtitle: Text(entry.value ?? 'N/A'),
                        );
                      })
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
