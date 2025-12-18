import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/banner_ad_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Gets the history stream
  /// Uses a simple query without orderBy to avoid index requirements
  /// Sorting is done in memory after fetching
  Stream<QuerySnapshot<Map<String, dynamic>>> _getHistoryStream(String userId) {
    // Simple query that doesn't require a composite index
    // We'll sort the results in memory
    return FirebaseFirestore.instance
        .collection('quiz_history')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  /// Builds the error widget
  Widget _buildErrorWidget(BuildContext context, String error) {
    final isIndexError =
        error.contains('index') ||
        error.contains('requires an index') ||
        error.contains('The query requires an index');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 20),
            const Text(
              'Error Loading History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                isIndexError
                    ? 'Firestore index required. Check console for index creation link.'
                    : error.length > 100
                    ? '${error.substring(0, 100)}...'
                    : error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            if (isIndexError) ...[
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'To fix this:\n1. Check the console/terminal for the index creation link\n2. Click the link to create the required index\n3. Wait a few minutes for the index to build\n4. Try again',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Retry by rebuilding the widget
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz History'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: ResponsiveWrapper(
              maxWidth: 800,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _getHistoryStream(userId),
          builder: (context, snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle errors
            if (snapshot.hasError) {
              return _buildErrorWidget(context, snapshot.error.toString());
            }

            // Safely process the data
            try {
              var docs = snapshot.data?.docs ?? [];

              // Filter out any documents that don't have required fields
              docs = docs.where((doc) {
                final data = doc.data();
                return data.containsKey('category') &&
                    data.containsKey('score') &&
                    data.containsKey('total');
              }).toList();

              // Sort in memory by timestamp (newest first)
              if (docs.isNotEmpty) {
                docs = List.from(docs);
                try {
                  docs.sort((a, b) {
                    final aData = a.data();
                    final bData = b.data();
                    final aTs = aData['timestamp'];
                    final bTs = bData['timestamp'];

                    // Handle null timestamps
                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1; // Put nulls at the end
                    if (bTs == null) return -1;

                    // Handle FieldValue.serverTimestamp() that hasn't been resolved
                    // This happens when the document was just created
                    if (aTs.toString().contains('FieldValue') ||
                        bTs.toString().contains('FieldValue')) {
                      return 0; // Don't sort if timestamp not resolved yet
                    }

                    // Handle Timestamp objects
                    if (aTs is Timestamp && bTs is Timestamp) {
                      return bTs.compareTo(
                        aTs,
                      ); // Descending order (newest first)
                    }

                    // Fallback: compare by document ID (newer documents have later IDs)
                    return b.id.compareTo(a.id);
                  });
                } catch (e) {
                  // If sorting fails, just use the documents as-is
                  debugPrint('Error sorting history: $e');
                }
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No quiz history yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;

                  return ListView.builder(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      try {
                        final data = docs[index].data();
                        final score = (data['score'] ?? 0) as int;
                        final total = (data['total'] ?? 0) as int;
                        final percentage = total == 0
                            ? 0
                            : ((score / total) * 100).round();
                        final passed = percentage >= 60;
                        final category =
                            (data['category'] ?? 'Unknown') as String;
                        final difficulty =
                            (data['difficulty'] ?? 'easy') as String;
                        final ts = data['timestamp'];
                        DateTime? date;
                        if (ts is Timestamp) {
                          date = ts.toDate();
                        }
                        final dateStr = date != null
                            ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                            : '';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(
                              isSmallScreen ? 12 : 16,
                            ),
                            leading: CircleAvatar(
                              radius: isSmallScreen ? 22 : 26,
                              backgroundColor: passed
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              child: Icon(
                                passed ? Icons.check : Icons.close,
                                color: passed ? Colors.green : Colors.red,
                                size: isSmallScreen ? 22 : 26,
                              ),
                            ),
                            title: Text(
                              category,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  'Score: $score/$total ($percentage%)',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(
                                          difficulty,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getDifficultyColor(
                                            difficulty,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getDifficultyIcon(difficulty),
                                            size: 12,
                                            color: _getDifficultyColor(
                                              difficulty,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            difficulty.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 9 : 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getDifficultyColor(
                                                difficulty,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dateStr.isNotEmpty
                                            ? 'Date: $dateStr'
                                            : '',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                        );
                      } catch (e) {
                        // If there's an error rendering a single item, show a placeholder
                        debugPrint('Error rendering history item: $e');
                        return Card(
                          child: ListTile(
                            title: const Text('Error loading item'),
                            subtitle: Text('Error: $e'),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            } catch (e) {
              // If there's an error processing the data, show error widget
              debugPrint('Error processing history data: $e');
              return _buildErrorWidget(context, e.toString());
            }
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
