import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/discipline_settings.dart';
import '../models/emotion_entry.dart';
import '../models/trade_model.dart';

/// Single source of truth for local persistence.
///
/// Phase 1 note on "encrypted local database": plain `sqflite` (used here)
/// stores an unencrypted file. For production, swap this for
/// `sqflite_sqlcipher` (drop-in API compatible) and pass a `password` in
/// `openDatabase`. That swap is intentionally isolated to this file so it
/// never touches the rest of the app.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sm_trading_discipline_pro.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trades (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            symbol TEXT NOT NULL,
            entryPrice REAL NOT NULL,
            exitPrice REAL,
            stopLoss REAL NOT NULL,
            target REAL NOT NULL,
            quantity INTEGER NOT NULL,
            strategy TEXT NOT NULL,
            screenshotPath TEXT,
            emotionBeforeTrade TEXT NOT NULL,
            mistakesMade TEXT,
            lessonsLearned TEXT,
            checklistCompleted INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE emotion_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            emotion TEXT NOT NULL,
            triggeredCooldown INTEGER NOT NULL DEFAULT 0,
            cooldownCompleted INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE discipline_settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            accountBalance REAL NOT NULL,
            maxTradesPerDay INTEGER NOT NULL,
            dailyMaxLossPercent REAL NOT NULL,
            dailyProfitTargetPercent REAL NOT NULL,
            cooldownMinutes INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE discipline_score_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            delta INTEGER NOT NULL,
            reason TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ---------------- Trades ----------------

  Future<int> insertTrade(TradeModel trade) async {
    final db = await database;
    return db.insert('trades', trade.toMap()
      ..remove('id'));
  }

  Future<int> updateTrade(TradeModel trade) async {
    final db = await database;
    return db.update('trades', trade.toMap(),
        where: 'id = ?', whereArgs: [trade.id]);
  }

  Future<List<TradeModel>> getAllTrades() async {
    final db = await database;
    final maps = await db.query('trades', orderBy: 'createdAt DESC');
    return maps.map((m) => TradeModel.fromMap(m)).toList();
  }

  Future<List<TradeModel>> getTradesForToday() async {
    final all = await getAllTrades();
    final now = DateTime.now();
    return all.where((t) =>
        t.createdAt.year == now.year &&
        t.createdAt.month == now.month &&
        t.createdAt.day == now.day).toList();
  }

  // ---------------- Emotion entries ----------------

  Future<int> insertEmotionEntry(EmotionEntry entry) async {
    final db = await database;
    return db.insert('emotion_entries', entry.toMap()..remove('id'));
  }

  Future<List<EmotionEntry>> getAllEmotionEntries() async {
    final db = await database;
    final maps = await db.query('emotion_entries', orderBy: 'createdAt DESC');
    return maps.map((m) => EmotionEntry.fromMap(m)).toList();
  }

  // ---------------- Discipline settings (single row) ----------------

  Future<void> saveDisciplineSettings(DisciplineSettings settings) async {
    final db = await database;
    final map = settings.toMap()..['id'] = 1;
    await db.insert(
      'discipline_settings',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DisciplineSettings?> getDisciplineSettings() async {
    final db = await database;
    final maps = await db.query('discipline_settings', where: 'id = 1');
    if (maps.isEmpty) return null;
    return DisciplineSettings.fromMap(maps.first);
  }

  // ---------------- Discipline score log ----------------

  Future<void> logScoreChange(int delta, String reason) async {
    final db = await database;
    await db.insert('discipline_score_log', {
      'delta': delta,
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getCumulativeScoreDelta() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT SUM(delta) as total FROM discipline_score_log');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getScoreLog() async {
    final db = await database;
    return db.query('discipline_score_log', orderBy: 'createdAt DESC');
  }
}
