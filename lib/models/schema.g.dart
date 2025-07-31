// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schema.dart';

// ignore_for_file: type=lint
class $MusicDirectoriesTable extends MusicDirectories
    with TableInfo<$MusicDirectoriesTable, MusicDirectory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MusicDirectoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 255),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _is_enabledMeta = const VerificationMeta(
    'is_enabled',
  );
  @override
  late final GeneratedColumn<bool> is_enabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _last_scannedMeta = const VerificationMeta(
    'last_scanned',
  );
  @override
  late final GeneratedColumn<int> last_scanned = GeneratedColumn<int>(
    'last_scanned',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scan_subdirectoriesMeta =
      const VerificationMeta('scan_subdirectories');
  @override
  late final GeneratedColumn<bool> scan_subdirectories = GeneratedColumn<bool>(
    'scan_subdirectories',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("scan_subdirectories" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _total_sizeMeta = const VerificationMeta(
    'total_size',
  );
  @override
  late final GeneratedColumn<int> total_size = GeneratedColumn<int>(
    'total_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _file_countMeta = const VerificationMeta(
    'file_count',
  );
  @override
  late final GeneratedColumn<int> file_count = GeneratedColumn<int>(
    'file_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _date_addedMeta = const VerificationMeta(
    'date_added',
  );
  @override
  late final GeneratedColumn<DateTime> date_added = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excluded_subdirectoriesMeta =
      const VerificationMeta('excluded_subdirectories');
  @override
  late final GeneratedColumn<String> excluded_subdirectories =
      GeneratedColumn<String>(
        'excluded_subdirectories',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    is_enabled,
    last_scanned,
    scan_subdirectories,
    total_size,
    file_count,
    date_added,
    excluded_subdirectories,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'music_directories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MusicDirectory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _is_enabledMeta,
        is_enabled.isAcceptableOrUnknown(data['is_enabled']!, _is_enabledMeta),
      );
    }
    if (data.containsKey('last_scanned')) {
      context.handle(
        _last_scannedMeta,
        last_scanned.isAcceptableOrUnknown(
          data['last_scanned']!,
          _last_scannedMeta,
        ),
      );
    }
    if (data.containsKey('scan_subdirectories')) {
      context.handle(
        _scan_subdirectoriesMeta,
        scan_subdirectories.isAcceptableOrUnknown(
          data['scan_subdirectories']!,
          _scan_subdirectoriesMeta,
        ),
      );
    }
    if (data.containsKey('total_size')) {
      context.handle(
        _total_sizeMeta,
        total_size.isAcceptableOrUnknown(data['total_size']!, _total_sizeMeta),
      );
    }
    if (data.containsKey('file_count')) {
      context.handle(
        _file_countMeta,
        file_count.isAcceptableOrUnknown(data['file_count']!, _file_countMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _date_addedMeta,
        date_added.isAcceptableOrUnknown(data['date_added']!, _date_addedMeta),
      );
    } else if (isInserting) {
      context.missing(_date_addedMeta);
    }
    if (data.containsKey('excluded_subdirectories')) {
      context.handle(
        _excluded_subdirectoriesMeta,
        excluded_subdirectories.isAcceptableOrUnknown(
          data['excluded_subdirectories']!,
          _excluded_subdirectoriesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MusicDirectory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MusicDirectory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      is_enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      last_scanned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_scanned'],
      ),
      scan_subdirectories: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}scan_subdirectories'],
      )!,
      total_size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_size'],
      )!,
      file_count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_count'],
      )!,
      date_added: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
      excluded_subdirectories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excluded_subdirectories'],
      ),
    );
  }

  @override
  $MusicDirectoriesTable createAlias(String alias) {
    return $MusicDirectoriesTable(attachedDatabase, alias);
  }
}

class MusicDirectory extends DataClass implements Insertable<MusicDirectory> {
  final int id;
  final String path;
  final bool is_enabled;
  final int? last_scanned;
  final bool scan_subdirectories;
  final int total_size;
  final int file_count;
  final DateTime date_added;
  final String? excluded_subdirectories;
  const MusicDirectory({
    required this.id,
    required this.path,
    required this.is_enabled,
    this.last_scanned,
    required this.scan_subdirectories,
    required this.total_size,
    required this.file_count,
    required this.date_added,
    this.excluded_subdirectories,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['is_enabled'] = Variable<bool>(is_enabled);
    if (!nullToAbsent || last_scanned != null) {
      map['last_scanned'] = Variable<int>(last_scanned);
    }
    map['scan_subdirectories'] = Variable<bool>(scan_subdirectories);
    map['total_size'] = Variable<int>(total_size);
    map['file_count'] = Variable<int>(file_count);
    map['date_added'] = Variable<DateTime>(date_added);
    if (!nullToAbsent || excluded_subdirectories != null) {
      map['excluded_subdirectories'] = Variable<String>(
        excluded_subdirectories,
      );
    }
    return map;
  }

  MusicDirectoriesCompanion toCompanion(bool nullToAbsent) {
    return MusicDirectoriesCompanion(
      id: Value(id),
      path: Value(path),
      is_enabled: Value(is_enabled),
      last_scanned: last_scanned == null && nullToAbsent
          ? const Value.absent()
          : Value(last_scanned),
      scan_subdirectories: Value(scan_subdirectories),
      total_size: Value(total_size),
      file_count: Value(file_count),
      date_added: Value(date_added),
      excluded_subdirectories: excluded_subdirectories == null && nullToAbsent
          ? const Value.absent()
          : Value(excluded_subdirectories),
    );
  }

  factory MusicDirectory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MusicDirectory(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      is_enabled: serializer.fromJson<bool>(json['is_enabled']),
      last_scanned: serializer.fromJson<int?>(json['last_scanned']),
      scan_subdirectories: serializer.fromJson<bool>(
        json['scan_subdirectories'],
      ),
      total_size: serializer.fromJson<int>(json['total_size']),
      file_count: serializer.fromJson<int>(json['file_count']),
      date_added: serializer.fromJson<DateTime>(json['date_added']),
      excluded_subdirectories: serializer.fromJson<String?>(
        json['excluded_subdirectories'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'is_enabled': serializer.toJson<bool>(is_enabled),
      'last_scanned': serializer.toJson<int?>(last_scanned),
      'scan_subdirectories': serializer.toJson<bool>(scan_subdirectories),
      'total_size': serializer.toJson<int>(total_size),
      'file_count': serializer.toJson<int>(file_count),
      'date_added': serializer.toJson<DateTime>(date_added),
      'excluded_subdirectories': serializer.toJson<String?>(
        excluded_subdirectories,
      ),
    };
  }

  MusicDirectory copyWith({
    int? id,
    String? path,
    bool? is_enabled,
    Value<int?> last_scanned = const Value.absent(),
    bool? scan_subdirectories,
    int? total_size,
    int? file_count,
    DateTime? date_added,
    Value<String?> excluded_subdirectories = const Value.absent(),
  }) => MusicDirectory(
    id: id ?? this.id,
    path: path ?? this.path,
    is_enabled: is_enabled ?? this.is_enabled,
    last_scanned: last_scanned.present ? last_scanned.value : this.last_scanned,
    scan_subdirectories: scan_subdirectories ?? this.scan_subdirectories,
    total_size: total_size ?? this.total_size,
    file_count: file_count ?? this.file_count,
    date_added: date_added ?? this.date_added,
    excluded_subdirectories: excluded_subdirectories.present
        ? excluded_subdirectories.value
        : this.excluded_subdirectories,
  );
  MusicDirectory copyWithCompanion(MusicDirectoriesCompanion data) {
    return MusicDirectory(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      is_enabled: data.is_enabled.present
          ? data.is_enabled.value
          : this.is_enabled,
      last_scanned: data.last_scanned.present
          ? data.last_scanned.value
          : this.last_scanned,
      scan_subdirectories: data.scan_subdirectories.present
          ? data.scan_subdirectories.value
          : this.scan_subdirectories,
      total_size: data.total_size.present
          ? data.total_size.value
          : this.total_size,
      file_count: data.file_count.present
          ? data.file_count.value
          : this.file_count,
      date_added: data.date_added.present
          ? data.date_added.value
          : this.date_added,
      excluded_subdirectories: data.excluded_subdirectories.present
          ? data.excluded_subdirectories.value
          : this.excluded_subdirectories,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MusicDirectory(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('is_enabled: $is_enabled, ')
          ..write('last_scanned: $last_scanned, ')
          ..write('scan_subdirectories: $scan_subdirectories, ')
          ..write('total_size: $total_size, ')
          ..write('file_count: $file_count, ')
          ..write('date_added: $date_added, ')
          ..write('excluded_subdirectories: $excluded_subdirectories')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    path,
    is_enabled,
    last_scanned,
    scan_subdirectories,
    total_size,
    file_count,
    date_added,
    excluded_subdirectories,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MusicDirectory &&
          other.id == this.id &&
          other.path == this.path &&
          other.is_enabled == this.is_enabled &&
          other.last_scanned == this.last_scanned &&
          other.scan_subdirectories == this.scan_subdirectories &&
          other.total_size == this.total_size &&
          other.file_count == this.file_count &&
          other.date_added == this.date_added &&
          other.excluded_subdirectories == this.excluded_subdirectories);
}

class MusicDirectoriesCompanion extends UpdateCompanion<MusicDirectory> {
  final Value<int> id;
  final Value<String> path;
  final Value<bool> is_enabled;
  final Value<int?> last_scanned;
  final Value<bool> scan_subdirectories;
  final Value<int> total_size;
  final Value<int> file_count;
  final Value<DateTime> date_added;
  final Value<String?> excluded_subdirectories;
  const MusicDirectoriesCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.is_enabled = const Value.absent(),
    this.last_scanned = const Value.absent(),
    this.scan_subdirectories = const Value.absent(),
    this.total_size = const Value.absent(),
    this.file_count = const Value.absent(),
    this.date_added = const Value.absent(),
    this.excluded_subdirectories = const Value.absent(),
  });
  MusicDirectoriesCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    this.is_enabled = const Value.absent(),
    this.last_scanned = const Value.absent(),
    this.scan_subdirectories = const Value.absent(),
    this.total_size = const Value.absent(),
    this.file_count = const Value.absent(),
    required DateTime date_added,
    this.excluded_subdirectories = const Value.absent(),
  }) : path = Value(path),
       date_added = Value(date_added);
  static Insertable<MusicDirectory> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<bool>? is_enabled,
    Expression<int>? last_scanned,
    Expression<bool>? scan_subdirectories,
    Expression<int>? total_size,
    Expression<int>? file_count,
    Expression<DateTime>? date_added,
    Expression<String>? excluded_subdirectories,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (is_enabled != null) 'is_enabled': is_enabled,
      if (last_scanned != null) 'last_scanned': last_scanned,
      if (scan_subdirectories != null)
        'scan_subdirectories': scan_subdirectories,
      if (total_size != null) 'total_size': total_size,
      if (file_count != null) 'file_count': file_count,
      if (date_added != null) 'date_added': date_added,
      if (excluded_subdirectories != null)
        'excluded_subdirectories': excluded_subdirectories,
    });
  }

  MusicDirectoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<bool>? is_enabled,
    Value<int?>? last_scanned,
    Value<bool>? scan_subdirectories,
    Value<int>? total_size,
    Value<int>? file_count,
    Value<DateTime>? date_added,
    Value<String?>? excluded_subdirectories,
  }) {
    return MusicDirectoriesCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      is_enabled: is_enabled ?? this.is_enabled,
      last_scanned: last_scanned ?? this.last_scanned,
      scan_subdirectories: scan_subdirectories ?? this.scan_subdirectories,
      total_size: total_size ?? this.total_size,
      file_count: file_count ?? this.file_count,
      date_added: date_added ?? this.date_added,
      excluded_subdirectories:
          excluded_subdirectories ?? this.excluded_subdirectories,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (is_enabled.present) {
      map['is_enabled'] = Variable<bool>(is_enabled.value);
    }
    if (last_scanned.present) {
      map['last_scanned'] = Variable<int>(last_scanned.value);
    }
    if (scan_subdirectories.present) {
      map['scan_subdirectories'] = Variable<bool>(scan_subdirectories.value);
    }
    if (total_size.present) {
      map['total_size'] = Variable<int>(total_size.value);
    }
    if (file_count.present) {
      map['file_count'] = Variable<int>(file_count.value);
    }
    if (date_added.present) {
      map['date_added'] = Variable<DateTime>(date_added.value);
    }
    if (excluded_subdirectories.present) {
      map['excluded_subdirectories'] = Variable<String>(
        excluded_subdirectories.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MusicDirectoriesCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('is_enabled: $is_enabled, ')
          ..write('last_scanned: $last_scanned, ')
          ..write('scan_subdirectories: $scan_subdirectories, ')
          ..write('total_size: $total_size, ')
          ..write('file_count: $file_count, ')
          ..write('date_added: $date_added, ')
          ..write('excluded_subdirectories: $excluded_subdirectories')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MusicDirectoriesTable musicDirectories = $MusicDirectoriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [musicDirectories];
}

typedef $$MusicDirectoriesTableCreateCompanionBuilder =
    MusicDirectoriesCompanion Function({
      Value<int> id,
      required String path,
      Value<bool> is_enabled,
      Value<int?> last_scanned,
      Value<bool> scan_subdirectories,
      Value<int> total_size,
      Value<int> file_count,
      required DateTime date_added,
      Value<String?> excluded_subdirectories,
    });
typedef $$MusicDirectoriesTableUpdateCompanionBuilder =
    MusicDirectoriesCompanion Function({
      Value<int> id,
      Value<String> path,
      Value<bool> is_enabled,
      Value<int?> last_scanned,
      Value<bool> scan_subdirectories,
      Value<int> total_size,
      Value<int> file_count,
      Value<DateTime> date_added,
      Value<String?> excluded_subdirectories,
    });

class $$MusicDirectoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MusicDirectoriesTable> {
  $$MusicDirectoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get is_enabled => $composableBuilder(
    column: $table.is_enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get last_scanned => $composableBuilder(
    column: $table.last_scanned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get scan_subdirectories => $composableBuilder(
    column: $table.scan_subdirectories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total_size => $composableBuilder(
    column: $table.total_size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get file_count => $composableBuilder(
    column: $table.file_count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date_added => $composableBuilder(
    column: $table.date_added,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excluded_subdirectories => $composableBuilder(
    column: $table.excluded_subdirectories,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MusicDirectoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MusicDirectoriesTable> {
  $$MusicDirectoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get is_enabled => $composableBuilder(
    column: $table.is_enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get last_scanned => $composableBuilder(
    column: $table.last_scanned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get scan_subdirectories => $composableBuilder(
    column: $table.scan_subdirectories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total_size => $composableBuilder(
    column: $table.total_size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get file_count => $composableBuilder(
    column: $table.file_count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date_added => $composableBuilder(
    column: $table.date_added,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excluded_subdirectories => $composableBuilder(
    column: $table.excluded_subdirectories,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MusicDirectoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MusicDirectoriesTable> {
  $$MusicDirectoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get is_enabled => $composableBuilder(
    column: $table.is_enabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get last_scanned => $composableBuilder(
    column: $table.last_scanned,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get scan_subdirectories => $composableBuilder(
    column: $table.scan_subdirectories,
    builder: (column) => column,
  );

  GeneratedColumn<int> get total_size => $composableBuilder(
    column: $table.total_size,
    builder: (column) => column,
  );

  GeneratedColumn<int> get file_count => $composableBuilder(
    column: $table.file_count,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date_added => $composableBuilder(
    column: $table.date_added,
    builder: (column) => column,
  );

  GeneratedColumn<String> get excluded_subdirectories => $composableBuilder(
    column: $table.excluded_subdirectories,
    builder: (column) => column,
  );
}

class $$MusicDirectoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MusicDirectoriesTable,
          MusicDirectory,
          $$MusicDirectoriesTableFilterComposer,
          $$MusicDirectoriesTableOrderingComposer,
          $$MusicDirectoriesTableAnnotationComposer,
          $$MusicDirectoriesTableCreateCompanionBuilder,
          $$MusicDirectoriesTableUpdateCompanionBuilder,
          (
            MusicDirectory,
            BaseReferences<
              _$AppDatabase,
              $MusicDirectoriesTable,
              MusicDirectory
            >,
          ),
          MusicDirectory,
          PrefetchHooks Function()
        > {
  $$MusicDirectoriesTableTableManager(
    _$AppDatabase db,
    $MusicDirectoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MusicDirectoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MusicDirectoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MusicDirectoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<bool> is_enabled = const Value.absent(),
                Value<int?> last_scanned = const Value.absent(),
                Value<bool> scan_subdirectories = const Value.absent(),
                Value<int> total_size = const Value.absent(),
                Value<int> file_count = const Value.absent(),
                Value<DateTime> date_added = const Value.absent(),
                Value<String?> excluded_subdirectories = const Value.absent(),
              }) => MusicDirectoriesCompanion(
                id: id,
                path: path,
                is_enabled: is_enabled,
                last_scanned: last_scanned,
                scan_subdirectories: scan_subdirectories,
                total_size: total_size,
                file_count: file_count,
                date_added: date_added,
                excluded_subdirectories: excluded_subdirectories,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                Value<bool> is_enabled = const Value.absent(),
                Value<int?> last_scanned = const Value.absent(),
                Value<bool> scan_subdirectories = const Value.absent(),
                Value<int> total_size = const Value.absent(),
                Value<int> file_count = const Value.absent(),
                required DateTime date_added,
                Value<String?> excluded_subdirectories = const Value.absent(),
              }) => MusicDirectoriesCompanion.insert(
                id: id,
                path: path,
                is_enabled: is_enabled,
                last_scanned: last_scanned,
                scan_subdirectories: scan_subdirectories,
                total_size: total_size,
                file_count: file_count,
                date_added: date_added,
                excluded_subdirectories: excluded_subdirectories,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MusicDirectoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MusicDirectoriesTable,
      MusicDirectory,
      $$MusicDirectoriesTableFilterComposer,
      $$MusicDirectoriesTableOrderingComposer,
      $$MusicDirectoriesTableAnnotationComposer,
      $$MusicDirectoriesTableCreateCompanionBuilder,
      $$MusicDirectoriesTableUpdateCompanionBuilder,
      (
        MusicDirectory,
        BaseReferences<_$AppDatabase, $MusicDirectoriesTable, MusicDirectory>,
      ),
      MusicDirectory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MusicDirectoriesTableTableManager get musicDirectories =>
      $$MusicDirectoriesTableTableManager(_db, _db.musicDirectories);
}
