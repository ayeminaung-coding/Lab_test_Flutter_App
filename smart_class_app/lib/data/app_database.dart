import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_session.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static const _webStorageKey = 'smart_class_sessions_web';
  static final List<ClassSession> _webMemorySessions = <ClassSession>[];

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_class.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id TEXT NOT NULL,
  check_in_timestamp TEXT NOT NULL,
  check_in_latitude REAL NOT NULL,
  check_in_longitude REAL NOT NULL,
  check_in_qr_code TEXT NOT NULL,
  previous_topic TEXT NOT NULL,
  expected_topic TEXT NOT NULL,
  mood_before_class INTEGER NOT NULL,
  check_out_timestamp TEXT,
  check_out_latitude REAL,
  check_out_longitude REAL,
  check_out_qr_code TEXT,
  learned_today TEXT,
  feedback TEXT
)
''');
  }

  Future<int> insertCheckIn({
    required String studentId,
    required DateTime checkInTimestamp,
    required double checkInLatitude,
    required double checkInLongitude,
    required String checkInQrCode,
    required String previousTopic,
    required String expectedTopic,
    required int moodBeforeClass,
  }) async {
    final data = <String, Object?>{
      'student_id': studentId,
      'check_in_timestamp': checkInTimestamp.toIso8601String(),
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_in_qr_code': checkInQrCode,
      'previous_topic': previousTopic,
      'expected_topic': expectedTopic,
      'mood_before_class': moodBeforeClass,
    };

    if (kIsWeb) {
      final allSessions = await _loadWebSessionsSafe();
      final newId = _nextSessionId(allSessions);
      final session = ClassSession.fromMap({
        ...data,
        'id': newId,
        'check_out_timestamp': null,
        'check_out_latitude': null,
        'check_out_longitude': null,
        'check_out_qr_code': null,
        'learned_today': null,
        'feedback': null,
      });
      allSessions.insert(0, session);
      await _persistWebSessionsSafe(allSessions);
      return newId;
    } else {
      final db = await instance.database;
      final newId = await db.insert('sessions', data);
      
      try {
        final allSessions = await _loadWebSessionsSafe();
        final session = ClassSession.fromMap({
          ...data,
          'id': newId,
          'check_out_timestamp': null,
          'check_out_latitude': null,
          'check_out_longitude': null,
          'check_out_qr_code': null,
          'learned_today': null,
          'feedback': null,
        });
        allSessions.insert(0, session);
        await _persistWebSessionsSafe(allSessions);
      } catch (e, st) {
        developer.log('Failed to save to shared_preferences', error: e, stackTrace: st);
      }
      
      return newId;
    }
  }

  Future<void> completeCheckOut({
    required int sessionId,
    required DateTime checkOutTimestamp,
    required double checkOutLatitude,
    required double checkOutLongitude,
    required String checkOutQrCode,
    required String learnedToday,
    required String feedback,
  }) async {
    final data = <String, Object?>{
      'check_out_timestamp': checkOutTimestamp.toIso8601String(),
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'check_out_qr_code': checkOutQrCode,
      'learned_today': learnedToday,
      'feedback': feedback,
    };

    if (kIsWeb) {
      final allSessions = await _loadWebSessionsSafe();
      final index = allSessions.indexWhere((s) => s.id == sessionId);
      if (index == -1) return;
      
      final existing = allSessions[index];
      final updated = ClassSession(
        id: existing.id,
        studentId: existing.studentId,
        checkInTimestamp: existing.checkInTimestamp,
        checkInLatitude: existing.checkInLatitude,
        checkInLongitude: existing.checkInLongitude,
        checkInQrCode: existing.checkInQrCode,
        previousTopic: existing.previousTopic,
        expectedTopic: existing.expectedTopic,
        moodBeforeClass: existing.moodBeforeClass,
        checkOutTimestamp: checkOutTimestamp,
        checkOutLatitude: checkOutLatitude,
        checkOutLongitude: checkOutLongitude,
        checkOutQrCode: checkOutQrCode,
        learnedToday: learnedToday,
        feedback: feedback,
      );
      allSessions[index] = updated;
      await _persistWebSessionsSafe(allSessions);
    } else {
      final db = await instance.database;
      await db.update('sessions', data, where: 'id = ?', whereArgs: [sessionId]);
      
      try {
        final allSessions = await _loadWebSessionsSafe();
        final index = allSessions.indexWhere((s) => s.id == sessionId);
        if (index != -1) {
          final existing = allSessions[index];
          final updated = ClassSession(
            id: existing.id,
            studentId: existing.studentId,
            checkInTimestamp: existing.checkInTimestamp,
            checkInLatitude: existing.checkInLatitude,
            checkInLongitude: existing.checkInLongitude,
            checkInQrCode: existing.checkInQrCode,
            previousTopic: existing.previousTopic,
            expectedTopic: existing.expectedTopic,
            moodBeforeClass: existing.moodBeforeClass,
            checkOutTimestamp: checkOutTimestamp,
            checkOutLatitude: checkOutLatitude,
            checkOutLongitude: checkOutLongitude,
            checkOutQrCode: checkOutQrCode,
            learnedToday: learnedToday,
            feedback: feedback,
          );
          allSessions[index] = updated;
          await _persistWebSessionsSafe(allSessions);
        }
      } catch (e, st) {
        developer.log('Failed to save to shared_preferences', error: e, stackTrace: st);
      }
    }
  }

  Future<List<ClassSession>> getAllSessions() async {
    if (kIsWeb) {
      return _loadWebSessionsSafe();
    } else {
      final db = await instance.database;
      final maps = await db.query('sessions', orderBy: 'id DESC');
      if (maps.isNotEmpty) return maps.map((map) => ClassSession.fromMap(map)).toList();
      return [];
    }
  }

  Future<List<ClassSession>> _loadWebSessionsSafe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await _loadWebSessions(prefs);
      _setMemorySessions(sessions);
      return sessions;
    } catch (error, stackTrace) {
      developer.log(
        'Web storage unavailable. Using in-memory session store.',
        name: 'AppDatabase',
        error: error,
        stackTrace: stackTrace,
      );
      return List<ClassSession>.from(_webMemorySessions);
    }
  }

  Future<void> _persistWebSessionsSafe(List<ClassSession> sessions) async {
    _setMemorySessions(sessions);
    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveWebSessions(prefs, sessions);
    } catch (error, stackTrace) {
      developer.log(
        'Persisting to web storage failed. Keeping in-memory copy only.',
        name: 'AppDatabase',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _setMemorySessions(List<ClassSession> sessions) {
    _webMemorySessions
      ..clear()
      ..addAll(sessions);
  }

  Future<List<ClassSession>> getActiveSessions() async {
    if (kIsWeb) {
      final allSessions = await getAllSessions();
      return allSessions.where((s) => s.checkOutTimestamp == null).toList();
    } else {
      final db = await instance.database;
      final maps = await db.query('sessions', where: 'check_out_timestamp IS NULL', orderBy: 'id DESC');
      if (maps.isNotEmpty) return maps.map((map) => ClassSession.fromMap(map)).toList();
      return [];
    }
  }

  Future<void> _saveWebSessions(SharedPreferences prefs, List<ClassSession> sessions) async {
    final List<Map<String, dynamic>> mapList = sessions.map((s) => {
      'id': s.id,
      'student_id': s.studentId,
      'check_in_timestamp': s.checkInTimestamp.toIso8601String(),
      'check_in_latitude': s.checkInLatitude,
      'check_in_longitude': s.checkInLongitude,
      'check_in_qr_code': s.checkInQrCode,
      'previous_topic': s.previousTopic,
      'expected_topic': s.expectedTopic,
      'mood_before_class': s.moodBeforeClass,
      'check_out_timestamp': s.checkOutTimestamp?.toIso8601String(),
      'check_out_latitude': s.checkOutLatitude,
      'check_out_longitude': s.checkOutLongitude,
      'check_out_qr_code': s.checkOutQrCode,
      'learned_today': s.learnedToday,
      'feedback': s.feedback,
    }).toList();
    final didSave = await prefs.setString(_webStorageKey, jsonEncode(mapList));
    if (!didSave) {
      throw Exception('Browser storage rejected the save request.');
    }
  }

  Future<List<ClassSession>> _loadWebSessions(SharedPreferences prefs) async {
    final jsonString = prefs.getString(_webStorageKey);
    if (jsonString == null || jsonString.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        throw const FormatException('Session payload is not a JSON list.');
      }

      final sessions = <ClassSession>[];
      for (final item in decoded) {
        if (item is! Map) continue;

        try {
          sessions.add(ClassSession.fromMap(Map<String, dynamic>.from(item)));
        } catch (error, stackTrace) {
          developer.log(
            'Skipping malformed session entry in web storage.',
            name: 'AppDatabase',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      return sessions;
    } catch (error, stackTrace) {
      developer.log(
        'Invalid web session payload detected. Resetting stored sessions.',
        name: 'AppDatabase',
        error: error,
        stackTrace: stackTrace,
      );
      await prefs.remove(_webStorageKey);
      return [];
    }
  }

  int _nextSessionId(List<ClassSession> sessions) {
    if (sessions.isEmpty) return 1;
    return sessions.fold<int>(0, (maxId, session) {
          return session.id > maxId ? session.id : maxId;
        }) +
        1;
  }
}