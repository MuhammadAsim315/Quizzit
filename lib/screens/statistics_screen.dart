import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/banner_ad_widget.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: ResponsiveWrapper(
              maxWidth: 800,
              child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quiz_history')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No statistics available yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete some quizzes to see your stats',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;
            return _buildStatistics(docs);
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

  Widget _buildStatistics(List<QueryDocumentSnapshot> docs) {
    // Calculate statistics
    int totalQuizzes = docs.length;
    int totalScore = 0;
    int totalQuestions = 0;
    int passedQuizzes = 0;
    Map<String, int> categoryCount = {};
    Map<String, int> categoryScore = {};
    Map<String, int> categoryTotal = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final score = (data['score'] ?? 0) as int;
      final total = (data['total'] ?? 0) as int;
      final category = (data['category'] ?? 'Unknown') as String;
      final percentage = (data['percentage'] ?? 0) as int;

      totalScore += score;
      totalQuestions += total;
      if (percentage >= 60) passedQuizzes++;

      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      categoryScore[category] = (categoryScore[category] ?? 0) + score;
      categoryTotal[category] = (categoryTotal[category] ?? 0) + total;
    }

    final avgScore = totalQuestions > 0
        ? ((totalScore / totalQuestions) * 100).round()
        : 0;
    final passRate = totalQuizzes > 0
        ? ((passedQuizzes / totalQuizzes) * 100).round()
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Stats
          _buildOverallStats(
            totalQuizzes: totalQuizzes,
            avgScore: avgScore,
            passRate: passRate,
            totalQuestions: totalQuestions,
          ),
          const SizedBox(height: 24),

          // Category Performance
          const Text(
            'Category Performance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...categoryCount.entries.map((entry) {
            final category = entry.key;
            final count = entry.value;
            final score = categoryScore[category] ?? 0;
            final total = categoryTotal[category] ?? 0;
            final avg = total > 0 ? ((score / total) * 100).round() : 0;

            return _buildCategoryCard(category, count, avg);
          }),
        ],
      ),
    );
  }

  Widget _buildOverallStats({
    required int totalQuizzes,
    required int avgScore,
    required int passRate,
    required int totalQuestions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Statistics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Quizzes',
                value: totalQuizzes.toString(),
                icon: Icons.quiz,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Avg Score',
                value: '$avgScore%',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Pass Rate',
                value: '$passRate%',
                icon: Icons.check_circle,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Questions',
                value: totalQuestions.toString(),
                icon: Icons.help_outline,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category, int count, int avgScore) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  category[0],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count quizzes completed',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$avgScore%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(avgScore),
                  ),
                ),
                Text(
                  'Average',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
