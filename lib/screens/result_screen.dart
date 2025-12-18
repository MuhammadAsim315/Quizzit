import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/responsive_wrapper.dart';
import 'dashboard_screen.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  final String category;
  final String? averageDifficulty;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.category,
    this.averageDifficulty,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    if (_saved) return;
    _saved = true;

    final percentage = (widget.score / widget.total * 100).round();
    final user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('quiz_history').add({
        'userId': user?.uid ?? 'anonymous',
        'category': widget.category,
        'score': widget.score,
        'total': widget.total,
        'percentage': percentage,
        'difficulty': widget.averageDifficulty ?? 'easy',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error silently or show a message
      debugPrint('Error saving quiz history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.total * 100).round();
    final passed = percentage >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveWrapper(
        maxWidth: 600,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      passed
                          ? Icons.emoji_events
                          : Icons.sentiment_dissatisfied,
                      size: isSmallScreen ? 70 : 80,
                      color: passed ? Colors.amber : Colors.grey,
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 30),
                    Text(
                      passed ? 'Congratulations!' : 'Keep Trying!',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 26 : 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
                        child: Column(
                          children: [
                            Text(
                              'Your Score',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${widget.score}/${widget.total}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 38 : 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Category: ${widget.category}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (widget.averageDifficulty != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(
                                    widget.averageDifficulty!,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getDifficultyColor(
                                      widget.averageDifficulty!,
                                    ),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getDifficultyIcon(
                                        widget.averageDifficulty!,
                                      ),
                                      size: 16,
                                      color: _getDifficultyColor(
                                        widget.averageDifficulty!,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Difficulty: ${widget.averageDifficulty!.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.w500,
                                        color: _getDifficultyColor(
                                          widget.averageDifficulty!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 30 : 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 36 : 48,
                          vertical: isSmallScreen ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back to Dashboard',
                        style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        // Navigate to dashboard and switch to history tab (index 2)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const DashboardScreen(initialIndex: 2),
                          ),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'View History',
                        style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
