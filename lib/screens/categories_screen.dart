import 'package:flutter/material.dart';
import '../widgets/category_card.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/banner_ad_widget.dart';
import 'quiz_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [Color(0xFF121212), Color(0xFF0A0A0A)]
                      : [Colors.deepPurple.shade50, Colors.white],
                ),
              ),
              child: ResponsiveWrapper(
                maxWidth: 1000,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      const Text(
                        'Choose Your Category',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a category to start your quiz challenge',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),

                      // Categories Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount;
                          if (constraints.maxWidth < 600) {
                            crossAxisCount = 2;
                          } else if (constraints.maxWidth < 900) {
                            crossAxisCount = 3;
                          } else {
                            crossAxisCount = 4;
                          }

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            children: [
                              CategoryCard(
                                title: 'Science',
                                icon: Icons.science,
                                color: Colors.blue,
                                onTap: () => _startQuiz(context, 'Science'),
                              ),
                              CategoryCard(
                                title: 'History',
                                icon: Icons.history_edu,
                                color: Colors.orange,
                                onTap: () => _startQuiz(context, 'History'),
                              ),
                              CategoryCard(
                                title: 'Geography',
                                icon: Icons.public,
                                color: Colors.green,
                                onTap: () => _startQuiz(context, 'Geography'),
                              ),
                              CategoryCard(
                                title: 'Sports',
                                icon: Icons.sports_soccer,
                                color: Colors.red,
                                onTap: () => _startQuiz(context, 'Sports'),
                              ),
                              CategoryCard(
                                title: 'Technology',
                                icon: Icons.computer,
                                color: Colors.purple,
                                onTap: () => _startQuiz(context, 'Technology'),
                              ),
                              CategoryCard(
                                title: 'Entertainment',
                                icon: Icons.movie,
                                color: Colors.pink,
                                onTap: () => _startQuiz(context, 'Entertainment'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Banner ad at the bottom
          const BannerAdWidget(),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizScreen(category: category)),
    );
  }
}
