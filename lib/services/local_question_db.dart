import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Local database service for storing and retrieving quiz questions
class LocalQuestionDB {
  static Database? _database;
  static const String _dbName = 'quiz_questions.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'questions';

  /// Get or create database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Create the questions table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correct TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        question_hash TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL,
        used_count INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_category_difficulty ON $_tableName(category, difficulty)
    ''');
    await db.execute('''
      CREATE INDEX idx_used_count ON $_tableName(used_count)
    ''');
  }

  /// Save questions to local database
  Future<void> saveQuestions(List<Map<String, dynamic>> questions) async {
    final db = await database;
    final batch = db.batch();

    for (var question in questions) {
      // Create a hash of the question to avoid duplicates
      final questionHash = _generateHash(question);
      
      try {
        batch.insert(
          _tableName,
          {
            'question': question['question'],
            'options': jsonEncode(question['options']),
            'correct': question['correct'],
            'category': question['category'] ?? 'Unknown',
            'difficulty': question['difficulty'] ?? 'easy',
            'question_hash': questionHash,
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'used_count': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore duplicates
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error saving question: $e');
        }
      }
    }

    await batch.commit(noResult: true);
    
    if (kDebugMode) {
      print('Saved ${questions.length} questions to local database');
    }
  }

  /// Get questions from local database
  Future<List<Map<String, dynamic>>> getQuestions({
    required String category,
    String? difficulty,
    int limit = 10,
    bool preferUnused = true,
  }) async {
    final db = await database;
    
    String whereClause = 'category = ?';
    List<dynamic> whereArgs = [category];
    
    if (difficulty != null) {
      whereClause += ' AND difficulty = ?';
      whereArgs.add(difficulty);
    }
    
    // Order by: prefer unused questions, then by creation date (newest first)
    String orderBy = preferUnused 
        ? 'used_count ASC, created_at DESC'
        : 'created_at DESC';
    
    final results = await db.query(
      _tableName,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );

    // Convert database rows back to question format
    final questions = results.map((row) {
      return {
        'question': row['question'],
        'options': jsonDecode(row['options'] as String) as List,
        'correct': row['correct'],
        'category': row['category'],
        'difficulty': row['difficulty'],
      };
    }).toList();

    // Mark questions as used
    if (questions.isNotEmpty) {
      final ids = results.map((r) => r['id'] as int).toList();
      await _incrementUsedCount(ids);
    }

    return questions;
  }

  /// Get count of available questions
  Future<int> getQuestionCount({
    required String category,
    String? difficulty,
  }) async {
    final db = await database;
    
    String whereClause = 'category = ?';
    List<dynamic> whereArgs = [category];
    
    if (difficulty != null) {
      whereClause += ' AND difficulty = ?';
      whereArgs.add(difficulty);
    }
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE $whereClause',
      whereArgs,
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Increment used count for questions
  Future<void> _incrementUsedCount(List<int> ids) async {
    if (ids.isEmpty) return;
    
    final db = await database;
    final placeholders = ids.map((_) => '?').join(',');
    
    await db.rawUpdate(
      'UPDATE $_tableName SET used_count = used_count + 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  /// Generate hash for question to detect duplicates
  String _generateHash(Map<String, dynamic> question) {
    final questionText = question['question'] as String? ?? '';
    final correct = question['correct'] as String? ?? '';
    return '${questionText.hashCode}_${correct.hashCode}';
  }

  /// Clear old questions (older than specified days)
  Future<void> clearOldQuestions({int daysOld = 30}) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;
    
    await db.delete(
      _tableName,
      where: 'created_at < ?',
      whereArgs: [cutoffTime],
    );
    
    if (kDebugMode) {
      print('Cleared old questions from local database');
    }
  }

  /// Clear all questions
  Future<void> clearAllQuestions() async {
    final db = await database;
    await db.delete(_tableName);
    
    if (kDebugMode) {
      print('Cleared all questions from local database');
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    final db = await database;
    
    final totalCount = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    final total = Sqflite.firstIntValue(totalCount) ?? 0;
    
    final categoryCount = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM $_tableName GROUP BY category'
    );
    
    final difficultyCount = await db.rawQuery(
      'SELECT difficulty, COUNT(*) as count FROM $_tableName GROUP BY difficulty'
    );
    
    return {
      'total': total,
      'by_category': {
        for (var row in categoryCount)
          row['category']: row['count']
      },
      'by_difficulty': {
        for (var row in difficultyCount)
          row['difficulty']: row['count']
      },
    };
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

