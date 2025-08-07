import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/library_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<String> _excludedFolders = [];
  final TextEditingController _geniusApiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExcludedFolders();
    _loadGeniusApiKey();
  }

  Future<void> _loadGeniusApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geniusApiKeyController.text = prefs.getString('geniusApiKey') ?? '';
    });
  }

  Future<void> _saveGeniusApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geniusApiKey', _geniusApiKeyController.text);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Genius API Key saved!')));
    }
  }

  Future<void> _loadExcludedFolders() async {
    final database = ref.read(appDatabaseProvider);
    final directories = await database
        .select(database.excludedDirectories)
        .get();
    setState(() {
      _excludedFolders = directories.map((d) => d.path).toList();
    });
  }

  Future<void> _addExcludedFolder() async {
    final database = ref.read(appDatabaseProvider);
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final exists = await (database.select(
        database.excludedDirectories,
      )..where((u) => u.path.equals(selectedDirectory))).get();
      if (exists.isEmpty) {
        await LibraryService().addExcludedDirectoryAndRemoveTracks(
          ref,
          selectedDirectory,
        );
        developer.log('Excluded folder added: $selectedDirectory');
        await _loadExcludedFolders();
      }
    }
  }

  Future<void> _removeExcludedFolder(String path) async {
    final database = ref.read(appDatabaseProvider);
    await (database.delete(
      database.excludedDirectories,
    )..where((tbl) => tbl.path.equals(path))).go();
    developer.log('Excluded folder removed: $path');
    await _loadExcludedFolders();
  }

  Future<void> _scanLibrary() async {
    await LibraryService().scanLibrary(ref);
  }

  Future<void> _clearAndRescan() async {
    final database = ref.read(appDatabaseProvider);
    await database.clearDatabase();
    await _scanLibrary();
  }

  Future<void> _exportDatabase() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    if (await Permission.manageExternalStorage.isGranted) {
      try {
        final dbFolder = await getApplicationSupportDirectory();
        final dbFile = File('${dbFolder.path}/my_database');

        if (await dbFile.exists()) {
          final downloadsDir = await getExternalStorageDirectory();
          if (downloadsDir != null) {
            final newFile = File(
              '${downloadsDir.path}/Download/my_database_export',
            );
            await dbFile.copy(newFile.path);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Database exported to ${newFile.path}')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Database file not found.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error exporting database: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission not granted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppTheme.onSurface),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.onSurface),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppTheme.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Settings',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.radiusMd,
                ),
                padding: AppTheme.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _geniusApiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Genius API Key',
                        hintText: 'Enter your Genius API Key',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveGeniusApiKey,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Excluded Folders',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.radiusMd,
                ),
                padding: AppTheme.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _excludedFolders.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppTheme.secondary, height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _excludedFolders[index],
                            style: AppTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppTheme.error,
                            ),
                            onPressed: () =>
                                _removeExcludedFolder(_excludedFolders[index]),
                            tooltip: 'Remove',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm,
                          ),
                          padding: AppTheme.paddingMd,
                        ),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Exclude Folder'),
                        onPressed: _addExcludedFolder,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Library Management',
                style: AppTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.radiusMd,
                ),
                padding: AppTheme.paddingMd,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: AppTheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm,
                          ),
                          padding: AppTheme.paddingMd,
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Library Now'),
                        onPressed: _scanLibrary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: AppTheme.onError,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm,
                          ),
                          padding: AppTheme.paddingMd,
                        ),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Clear and Rescan Library'),
                        onPressed: _clearAndRescan,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.radiusSm,
                          ),
                          padding: AppTheme.paddingMd,
                        ),
                        icon: const Icon(Icons.download),
                        label: const Text('Export Database'),
                        onPressed: _exportDatabase,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
