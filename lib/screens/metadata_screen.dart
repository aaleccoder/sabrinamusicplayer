import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/metadata_service.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  _MetadataScreenState createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  final MetadataService _metadataService = MetadataService();
  List<Map<String, String?>>? _musicFiles;
  bool _isLoading = false;

  Future<void> _fetchMusicFiles() async {
    setState(() {
      _isLoading = true;
    });
    final files = await _metadataService.getAllMusicFiles();
    setState(() {
      _musicFiles = files;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Files')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                children: [
                  ElevatedButton(
                    onPressed: _fetchMusicFiles,
                    child: const Text('Fetch Music Files'),
                  ),
                  if (_musicFiles != null)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _musicFiles!.length,
                        itemBuilder: (context, index) {
                          final file = _musicFiles![index];
                          return ListTile(
                            title: Text(file['title'] ?? 'Unknown Title'),
                            subtitle: Text(file['artist'] ?? 'Unknown Artist'),
                            onTap: () {
                              // Optional: show more details in a dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(file['title'] ?? 'Details'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: file.entries
                                          .map(
                                            (e) => Text('${e.key}: ${e.value}'),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
