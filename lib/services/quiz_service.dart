import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'local_question_db.dart';

class QuizService {
  // Base URL for your backend API
  // Change this to your backend URL
  static const String baseUrl = 'https://opentdb.com/api.php';
  
  // Alternative: Use your own backend
  // static const String baseUrl = 'https://your-backend.com/api';
  
  // Rate limiting - track last request time
  DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 1000); // 1 second between requests
  
  // Local database instance
  final LocalQuestionDB _localDB = LocalQuestionDB();
  
  /// Fetches quiz questions from the API based on category
  /// 
  /// [category] - The quiz category (e.g., 'Science', 'History')
  /// [amount] - Number of questions to fetch (default: 10)
  /// [difficulty] - Question difficulty: 'easy', 'medium', 'hard' (optional)
  /// [retryCount] - Number of retries for rate limit errors (default: 3)
  /// 
  /// Returns a list of formatted questions ready for the quiz
  Future<List<Map<String, dynamic>>> fetchQuestions({
    required String category,
    int amount = 10,
    String? difficulty,
    int retryCount = 3,
  }) async {
    // Rate limiting - ensure minimum time between requests
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }
    
    int attempt = 0;
    while (attempt <= retryCount) {
      try {
        _lastRequestTime = DateTime.now();
        
        // Map your app categories to API category IDs
        final categoryId = _getCategoryId(category);
        
        // Build the API URL
        final uri = Uri.parse(baseUrl).replace(queryParameters: {
          'amount': amount.toString(),
          'category': categoryId.toString(),
          'type': 'multiple', // Multiple choice questions
          if (difficulty != null) 'difficulty': difficulty,
        });
        
        if (kDebugMode) {
          print('Fetching questions from: $uri (Attempt ${attempt + 1})');
        }
        
        // Make the API request
        final response = await http.get(uri).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout. Please check your internet connection.');
          },
        );
        
        // Handle rate limiting (429)
        if (response.statusCode == 429) {
          if (attempt < retryCount) {
            // Exponential backoff: wait 2^attempt seconds
            final waitTime = Duration(seconds: (2 << attempt).clamp(1, 10));
            if (kDebugMode) {
              print('Rate limited (429). Waiting ${waitTime.inSeconds} seconds before retry...');
            }
            await Future.delayed(waitTime);
            attempt++;
            continue;
          } else {
            throw Exception('Too many requests. Please wait a moment and try again.');
          }
        }
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
        if (data['response_code'] == 0) {
          // Success - format the questions
          final results = data['results'] as List;
          final formattedQuestions = results.map((question) => _formatQuestion(question)).toList();
          
          // Save questions to local database in the background
          _saveQuestionsToLocal(formattedQuestions, category);
          
          return formattedQuestions;
        } else {
          throw Exception('API Error: ${data['response_code']} - ${_getErrorMessage(data['response_code'])}');
        }
      } else {
        throw Exception('Failed to load questions. Status code: ${response.statusCode}');
      }
      } catch (e) {
        // If it's a rate limit error and we have retries left, continue the loop
        if (e.toString().contains('429') && attempt < retryCount) {
          attempt++;
          continue;
        }
        
        if (kDebugMode) {
          print('Error fetching questions: $e');
        }
        
        // On final attempt, try to get questions from local database
        if (attempt >= retryCount) {
          if (kDebugMode) {
            print('API failed, trying to load from local database...');
          }
          
          try {
            final localQuestions = await _localDB.getQuestions(
              category: category,
              difficulty: difficulty,
              limit: amount,
            );
            
            if (localQuestions.isNotEmpty) {
              if (kDebugMode) {
                print('Loaded ${localQuestions.length} questions from local database');
              }
              return localQuestions;
            }
          } catch (dbError) {
            if (kDebugMode) {
              print('Error loading from local database: $dbError');
            }
          }
          
          // If local DB also fails, rethrow the original error
          rethrow;
        }
        
        attempt++;
      }
    }
    
    throw Exception('Failed to load questions after $retryCount retries');
  }
  
  /// Save questions to local database (non-blocking)
  /// Note: sqflite doesn't work on web, so we skip database operations on web platform
  void _saveQuestionsToLocal(List<Map<String, dynamic>> questions, String category) {
    // Skip database operations on web platform
    if (kIsWeb) {
      return;
    }
    
    // Add category to each question if not present
    final questionsWithCategory = questions.map((q) {
      if (!q.containsKey('category') || q['category'] == null) {
        q['category'] = category;
      }
      return q;
    }).toList();
    
    // Save in background without blocking
    _localDB.saveQuestions(questionsWithCategory).catchError((error) {
      if (kDebugMode) {
        print('Error saving questions to local DB: $error');
      }
    });
  }
  
  /// Get questions from local database only
  /// Note: Returns empty list on web platform since sqflite doesn't work on web
  Future<List<Map<String, dynamic>>> getQuestionsFromLocal({
    required String category,
    String? difficulty,
    int amount = 10,
  }) async {
    if (kIsWeb) {
      return [];
    }
    return await _localDB.getQuestions(
      category: category,
      difficulty: difficulty,
      limit: amount,
    );
  }
  
  /// Check if local database has questions available
  /// Note: Returns false on web platform since sqflite doesn't work on web
  Future<bool> hasLocalQuestions({
    required String category,
    String? difficulty,
    int minCount = 1,
  }) async {
    if (kIsWeb) {
      return false;
    }
    final count = await _localDB.getQuestionCount(
      category: category,
      difficulty: difficulty,
    );
    return count >= minCount;
  }
  
  /// Formats API question data into app-friendly format
  Map<String, dynamic> _formatQuestion(Map<String, dynamic> question) {
    // Decode HTML entities in question and answers
    final questionText = _decodeHtml(question['question'] as String);
    final correctAnswer = _decodeHtml(question['correct_answer'] as String);
    final incorrectAnswers = (question['incorrect_answers'] as List)
        .map((answer) => _decodeHtml(answer as String))
        .toList();
    
    // Combine all answers and shuffle them
    final allAnswers = [correctAnswer, ...incorrectAnswers];
    allAnswers.shuffle();
    
    return {
      'question': questionText,
      'options': allAnswers,
      'correct': correctAnswer,
      'category': question['category'],
      'difficulty': question['difficulty'],
    };
  }
  
  /// Maps app category names to Open Trivia DB category IDs
  int _getCategoryId(String category) {
    final categoryMap = {
      'Science': 17, // Science & Nature
      'History': 23, // History
      'Geography': 22, // Geography
      'Sports': 21, // Sports
      'Technology': 18, // Computers
      'Entertainment': 14, // Television
    };
    
    return categoryMap[category] ?? 9; // Default to General Knowledge
  }
  
  /// Decodes HTML entities in text
  String _decodeHtml(String html) {
    return html
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&uuml;', 'ü');
  }
  
  /// Gets error message from response code
  String _getErrorMessage(int code) {
    switch (code) {
      case 1:
        return 'No results found';
      case 2:
        return 'Invalid parameter';
      case 3:
        return 'Token not found';
      case 4:
        return 'Token empty';
      default:
        return 'Unknown error';
    }
  }
  
  /// Alternative method: Fetch from your own custom backend
  /// 
  /// Example API endpoint structure:
  /// POST /api/quiz/generate
  /// Body: { "category": "Science", "amount": 10 }
  /// Response: { "questions": [...] }
  Future<List<Map<String, dynamic>>> fetchQuestionsFromCustomBackend({
    required String category,
    int amount = 10,
    String? difficulty,
  }) async {
    try {
      // Replace with your backend URL
      const String customBackendUrl = 'https://your-backend.com/api/quiz/generate';
      
      final response = await http.post(
        Uri.parse(customBackendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'amount': amount,
          if (difficulty != null) 'difficulty': difficulty,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final questions = data['questions'] as List;
        return questions.map((q) => q as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load questions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching questions from custom backend: $e');
      }
      rethrow;
    }
  }
}

