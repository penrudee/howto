// database.dart
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "ChildDoseCalculator.db";
  static final _databaseVersion = 3;

  static final table = "medicines";
  static final columnId = "id";
  static final columnName = "name";
  static final columnDose = "dose";
  static final columnConcentration = "concentration";
  static final String columnFrequency = 'frequency';

  static final appSettingsTable = "app_settings";
  static final columnKey = "key";
  static final columnValue = "value";
  // Singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    print("Create database at path: $path");
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnDose REAL NOT NULL,
        $columnConcentration REAL NOT NULL,
        $columnFrequency INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE $appSettingsTable (
        $columnKey TEXT PRIMARY KEY,
        $columnValue TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE $table ADD COLUMN $columnFrequency INTEGER NOT NULL DEFAULT 1');
    }
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> setCSVUploaded(bool uploaded) async {
    Database db = await instance.database;
    await db.insert(
        appSettingsTable, {'key': 'csv_uploaded', 'value': uploaded.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> getCSVUploaded() async {
    Database db = await instance.database;
    final result = await db.query(appSettingsTable,
        where: '$columnKey = ?', whereArgs: ['csv_uploaded']);
    if (result.isNotEmpty) {
      return result.first['value'] == 'true';
    }
    return false;
  }

  Future<String> getDatabasePath(String databaseName) async {
    String path = '';
    try {
      String databasesPath = await getDatabasesPath();
      path = join(databasesPath, databaseName);
    } catch (e, stacktrace) {
      print('Error: $e');
      print('Stacktrace: $stacktrace');
    }
    return path;
  }

  Future<void> importBackupFile(File backupFile) async {
    String dbName = "ChildDoseCalculator.db";
    String databasePath = await DatabaseHelper.instance.getDatabasePath(dbName);
    File databaseFile = File(databasePath);

    await backupFile.copy(databaseFile.path);
  }
}
