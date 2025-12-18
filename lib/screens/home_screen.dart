import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/category_card.dart';
import '../widgets/responsive_wrapper.dart';
import 'quiz_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ResponsiveWrapper(
        maxWidth: 1000,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Choose Your Category',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Expanded(
                child: LayoutBuilder(
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
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
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
              ),
            ],
          ),
        ),
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
