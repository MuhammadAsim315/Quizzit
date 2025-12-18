import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/quiz_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String category;

  const QuizScreen({super.key, required this.category});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  String? selectedAnswer;
  bool isAnswered = false;

  // Quiz state
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;
  String? errorMessage;
  bool usingLocalQuestions = false; // Track if using local DB
  final QuizService _quizService = QuizService();

  // Adaptive difficulty system
  String currentDifficulty = 'easy'; // Start with easy
  final List<String> difficultyLevels = ['easy', 'medium', 'hard'];
  int consecutiveCorrect = 0;
  int consecutiveWrong = 0;
  final List<String> difficultyHistory =
      []; // Track difficulty of each question

  // Question pools for different difficulties to reduce API calls
  final List<Map<String, dynamic>> _easyQuestions = [];
  final List<Map<String, dynamic>> _mediumQuestions = [];
  final List<Map<String, dynamic>> _hardQuestions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  /// Adjusts difficulty based on user performance
  void _adjustDifficulty(bool isCorrect) {
    if (isCorrect) {
      consecutiveCorrect++;
      consecutiveWrong = 0;

      // Increase difficulty after 2 consecutive correct answers
      if (consecutiveCorrect >= 2) {
        final currentIndex = difficultyLevels.indexOf(currentDifficulty);
        if (currentIndex < difficultyLevels.length - 1) {
          setState(() {
            currentDifficulty = difficultyLevels[currentIndex + 1];
            consecutiveCorrect = 0; // Reset counter
          });
        }
      }
    } else {
      consecutiveWrong++;
      consecutiveCorrect = 0;

      // Decrease difficulty after 2 consecutive wrong answers
      if (consecutiveWrong >= 2) {
        final currentIndex = difficultyLevels.indexOf(currentDifficulty);
        if (currentIndex > 0) {
          setState(() {
            currentDifficulty = difficultyLevels[currentIndex - 1];
            consecutiveWrong = 0; // Reset counter
          });
        }
      }
    }
  }

  /// Gets a question from the appropriate pool or fetches new ones
  Map<String, dynamic>? _getQuestionFromPool(String difficulty) {
    List<Map<String, dynamic>> pool;
    switch (difficulty) {
      case 'easy':
        pool = _easyQuestions;
        break;
      case 'medium':
        pool = _mediumQuestions;
        break;
      case 'hard':
        pool = _hardQuestions;
        break;
      default:
        pool = _easyQuestions;
    }

    if (pool.isNotEmpty) {
      return pool.removeAt(0);
    }
    return null;
  }

  /// Preloads questions for a specific difficulty into the pool
  Future<void> _preloadQuestions(String difficulty, int amount) async {
    try {
      // Check if pool already has enough questions
      List<Map<String, dynamic>> pool;
      switch (difficulty) {
        case 'easy':
          pool = _easyQuestions;
          break;
        case 'medium':
          pool = _mediumQuestions;
          break;
        case 'hard':
          pool = _hardQuestions;
          break;
        default:
          return;
      }

      if (pool.length >= amount) return; // Already have enough

      final fetchedQuestions = await _quizService.fetchQuestions(
        category: widget.category,
        amount: amount,
        difficulty: difficulty,
      );

      if (mounted && fetchedQuestions.isNotEmpty) {
        pool.addAll(fetchedQuestions);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error preloading $difficulty questions: $e');
      }
    }
  }

  /// Loads the next question with adaptive difficulty
  Future<void> _loadNextQuestion() async {
    // Try to get question from pool first
    final questionFromPool = _getQuestionFromPool(currentDifficulty);
    if (questionFromPool != null) {
      if (mounted) {
        setState(() {
          questions.add(questionFromPool);
          difficultyHistory.add(currentDifficulty);
        });
      }

      // Preload more questions if pool is getting low
      if (_getPoolSize(currentDifficulty) < 2) {
        _preloadQuestions(currentDifficulty, 3);
      }
      return;
    }

    // Pool is empty, fetch new questions
    try {
      final fetchedQuestions = await _quizService.fetchQuestions(
        category: widget.category,
        amount: 3, // Fetch multiple to reduce API calls
        difficulty: currentDifficulty,
      );

      if (mounted && fetchedQuestions.isNotEmpty) {
        setState(() {
          questions.add(fetchedQuestions[0]);
          difficultyHistory.add(currentDifficulty);
          usingLocalQuestions = false; // Reset flag if API succeeded

          // Add remaining questions to pool
          for (var i = 1; i < fetchedQuestions.length; i++) {
            _addToPool(currentDifficulty, fetchedQuestions[i]);
          }
        });
      }
    } catch (e) {
      // Check if error message indicates local DB was used
      final errorStr = e.toString();
      if (errorStr.contains('local database') || errorStr.contains('Loaded')) {
        if (mounted) {
          setState(() {
            usingLocalQuestions = true;
          });
        }
      }
      if (kDebugMode) {
        print('Error loading next question: $e');
      }
      // If fetching with current difficulty fails, try easy as fallback
      if (currentDifficulty != 'easy') {
        final easyQuestion = _getQuestionFromPool('easy');
        if (easyQuestion != null) {
          if (mounted) {
            setState(() {
              questions.add(easyQuestion);
              difficultyHistory.add('easy');
              currentDifficulty = 'easy';
            });
          }
        } else {
          // Try to get from local DB as last resort
          _tryLoadFromLocalDB('easy');
        }
      } else {
        // Try to get from local DB as last resort
        _tryLoadFromLocalDB(currentDifficulty);
      }
    }
  }

  int _getPoolSize(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return _easyQuestions.length;
      case 'medium':
        return _mediumQuestions.length;
      case 'hard':
        return _hardQuestions.length;
      default:
        return 0;
    }
  }

  void _addToPool(String difficulty, Map<String, dynamic> question) {
    switch (difficulty) {
      case 'easy':
        _easyQuestions.add(question);
        break;
      case 'medium':
        _mediumQuestions.add(question);
        break;
      case 'hard':
        _hardQuestions.add(question);
        break;
    }
  }

  /// Try to load questions from local database
  Future<void> _tryLoadFromLocalDB(String difficulty) async {
    try {
      final localQuestions = await _quizService.getQuestionsFromLocal(
        category: widget.category,
        difficulty: difficulty,
        amount: 3,
      );

      if (mounted && localQuestions.isNotEmpty) {
        setState(() {
          questions.add(localQuestions[0]);
          difficultyHistory.add(difficulty);
          usingLocalQuestions = true;

          // Add remaining to pool
          for (var i = 1; i < localQuestions.length; i++) {
            _addToPool(difficulty, localQuestions[i]);
          }
        });
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'No questions available. Please check your internet connection.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load questions. Please try again later.';
        });
      }
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      questions = [];
      currentQuestion = 0;
      score = 0;
      currentDifficulty = 'easy';
      consecutiveCorrect = 0;
      consecutiveWrong = 0;
      difficultyHistory.clear();
      usingLocalQuestions = false;
      // Clear question pools
      _easyQuestions.clear();
      _mediumQuestions.clear();
      _hardQuestions.clear();
    });

    try {
      // Load initial batch of questions (5 questions to start)
      final fetchedQuestions = await _quizService.fetchQuestions(
        category: widget.category,
        amount: 5,
        difficulty: currentDifficulty,
      );

      if (mounted) {
        setState(() {
          questions = fetchedQuestions;
          // Track difficulty for initial questions
          for (var i = 0; i < fetchedQuestions.length; i++) {
            difficultyHistory.add(currentDifficulty);
          }
          isLoading = false;
        });

        // Preload questions for other difficulties in the background
        _preloadQuestions('medium', 3);
        _preloadQuestions('hard', 3);
      }
    } catch (e) {
      // Check if local DB was used (indicated in error message)
      final errorStr = e.toString();
      if (errorStr.contains('local database') || errorStr.contains('Loaded')) {
        // Questions were loaded from local DB, continue normally
        if (mounted) {
          setState(() {
            usingLocalQuestions = true;
            isLoading = false;
          });
        }
      } else {
        // Try local DB as fallback
        if (mounted) {
          setState(() {
            isLoading = false;
            final errorMsg = errorStr.replaceAll('Exception: ', '');
            if (errorMsg.contains('429') ||
                errorMsg.contains('Too many requests')) {
              // Try local DB when rate limited
              _tryLoadFromLocalDB(currentDifficulty);
            } else {
              errorMessage = errorMsg;
            }
          });
        }
      }
    }
  }

  void checkAnswer(String answer) {
    if (isAnswered || questions.isEmpty) return;

    final isCorrect = answer == questions[currentQuestion]['correct'];

    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      if (isCorrect) {
        score++;
      }
    });

    // Adjust difficulty based on answer
    _adjustDifficulty(isCorrect);

    // Preload next question if we're running low (only if we have less than 2 questions left)
    if (questions.length - currentQuestion <= 2 && currentQuestion < 9) {
      _loadNextQuestion();
    }
  }

  void nextQuestion() {
    if (currentQuestion < 9) {
      // 10 questions total (0-9)
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        isAnswered = false;
      });

      // If we're running low on questions, preload more
      if (questions.length - currentQuestion <= 2) {
        _loadNextQuestion();
      }
    } else {
      // Quiz complete - calculate average difficulty
      final avgDifficulty = _calculateAverageDifficulty();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: score,
            total: questions.length,
            category: widget.category,
            averageDifficulty: avgDifficulty,
          ),
        ),
      );
    }
  }

  /// Calculates the average difficulty level for the quiz
  String _calculateAverageDifficulty() {
    if (difficultyHistory.isEmpty) return 'easy';

    int easyCount = 0;
    int mediumCount = 0;
    int hardCount = 0;

    for (var diff in difficultyHistory) {
      if (diff == 'easy') {
        easyCount++;
      } else if (diff == 'medium') {
        mediumCount++;
      } else if (diff == 'hard') {
        hardCount++;
      }
    }

    // Return the most common difficulty
    if (hardCount >= mediumCount && hardCount >= easyCount) return 'hard';
    if (mediumCount >= easyCount) return 'medium';
    return 'easy';
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Loading questions...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
    if (errorMessage != null || questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 20),
                Text(
                  'Failed to Load Questions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage ?? 'No questions available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey[600],
                  ),
                ),
                if (errorMessage != null &&
                    (errorMessage!.contains('429') ||
                        errorMessage!.contains('Too many requests'))) ...[
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'The quiz API has rate limits. Please wait 10-15 seconds before trying again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _loadQuestions,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Quiz UI
    final question = questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          // Difficulty indicator
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _getDifficultyColor(currentDifficulty).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getDifficultyColor(currentDifficulty),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getDifficultyIcon(currentDifficulty),
                    size: 16,
                    color: _getDifficultyColor(currentDifficulty),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentDifficulty.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(currentDifficulty),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Question counter
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${currentQuestion + 1}/10',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ResponsiveWrapper(
              maxWidth: 800,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;

                  return Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  LinearProgressIndicator(
                    value: (currentQuestion + 1) / questions.length,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple,
                    ),
                    minHeight: 8,
                  ),
                  if (usingLocalQuestions) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.storage,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Using offline questions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 20.0 : 28.0),
                      child: Text(
                        question['question'],
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  Expanded(
                    child: ListView.builder(
                      itemCount: question['options'].length,
                      itemBuilder: (context, index) {
                        final option = question['options'][index];
                        final isCorrect = option == question['correct'];
                        final isSelected = option == selectedAnswer;

                        Color? cardColor;
                        if (isAnswered) {
                          if (isSelected) {
                            cardColor = isCorrect
                                ? Colors.green[100]
                                : Colors.red[100];
                          } else if (isCorrect) {
                            cardColor = Colors.green[100];
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Card(
                            elevation: isSelected ? 8 : 2,
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => checkAnswer(option),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 12.0 : 16.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: isSmallScreen ? 26 : 30,
                                      height: isSmallScreen ? 26 : 30,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.deepPurple
                                            : Theme.of(context).brightness == Brightness.dark
                                                ? Colors.grey[700]
                                                : Colors.grey[300],
                                      ),
                                      child: Center(
                                        child: Text(
                                          String.fromCharCode(65 + index),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 13 : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 12 : 16),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ),
                                    if (isAnswered && (isSelected || isCorrect))
                                      Icon(
                                        isCorrect
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.red,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isAnswered)
                    ElevatedButton(
                      onPressed: nextQuestion,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        currentQuestion < questions.length - 1
                            ? 'Next Question'
                            : 'View Results',
                        style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                      ),
                    ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Banner ad at the bottom
          const BannerAdWidget(),
        ],
      ),
    );
  }

  /// Gets color for difficulty level
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Gets icon for difficulty level
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Icons.trending_down;
      case 'medium':
        return Icons.trending_flat;
      case 'hard':
        return Icons.trending_up;
      default:
        return Icons.help_outline;
    }
  }
}
