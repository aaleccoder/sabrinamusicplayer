import 'package:drift/drift.dart' hide Column;
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/schema.dart';
import 'package:flutter_application_1/services/library_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<String> _excludedFolders = [];

  @override
  void initState() {
    super.initState();
    _loadExcludedFolders();
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
      body: Padding(
        padding: AppTheme.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          icon: const Icon(Icons.delete, color: AppTheme.error),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
