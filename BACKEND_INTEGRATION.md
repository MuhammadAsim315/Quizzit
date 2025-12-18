# Backend Integration Guide

This document explains how the quiz system fetches questions from the internet/backend API.

## Overview

The quiz system now dynamically fetches questions from an external API instead of using hardcoded questions. The integration is flexible and can work with different backend APIs.

## Current Implementation

### Default API: Open Trivia DB

By default, the app uses **Open Trivia DB** (https://opentdb.com/), a free, user-contributed trivia question database.

**Features:**
- ✅ Free and no API key required
- ✅ Thousands of questions across multiple categories
- ✅ Multiple difficulty levels
- ✅ Multiple choice questions

### How It Works

1. **Quiz Service** (`lib/services/quiz_service.dart`)
   - Handles all API communication
   - Formats questions for the app
   - Maps app categories to API categories

2. **Quiz Screen** (`lib/screens/quiz_screen.dart`)
   - Fetches questions when quiz starts
   - Shows loading state while fetching
   - Handles errors gracefully with retry option

3. **Question Flow:**
   ```
   User selects category → Quiz Screen loads → API request → Questions displayed
   ```

## Using Your Own Backend

To use your own backend API, you have two options:

### Option 1: Modify the Existing Service

Edit `lib/services/quiz_service.dart`:

1. **Change the base URL:**
   ```dart
   static const String baseUrl = 'https://your-backend.com/api';
   ```

2. **Update the `fetchQuestions` method** to match your API response format:
   ```dart
   Future<List<Map<String, dynamic>>> fetchQuestions({
     required String category,
     int amount = 10,
     String? difficulty,
   }) async {
     final response = await http.get(
       Uri.parse('$baseUrl/quiz?category=$category&amount=$amount'),
     );
     
     final data = json.decode(response.body);
     // Parse your API response format
     return data['questions'].map((q) => q as Map<String, dynamic>).toList();
   }
   ```

### Option 2: Use the Custom Backend Method

The service already includes a `fetchQuestionsFromCustomBackend` method. Update it with your backend details:

```dart
Future<List<Map<String, dynamic>>> fetchQuestionsFromCustomBackend({
  required String category,
  int amount = 10,
  String? difficulty,
}) async {
  const String customBackendUrl = 'https://your-backend.com/api/quiz/generate';
  
  final response = await http.post(
    Uri.parse(customBackendUrl),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'category': category,
      'amount': amount,
      if (difficulty != null) 'difficulty': difficulty,
    }),
  );
  
  final data = json.decode(response.body);
  return data['questions'].map((q) => q as Map<String, dynamic>).toList();
}
```

Then update `quiz_screen.dart` to use this method:
```dart
final fetchedQuestions = await _quizService.fetchQuestionsFromCustomBackend(
  category: widget.category,
  amount: 10,
);
```

## Expected Question Format

Your backend API should return questions in this format:

```json
{
  "questions": [
    {
      "question": "What is the capital of France?",
      "options": ["London", "Berlin", "Paris", "Madrid"],
      "correct": "Paris",
      "category": "Geography",
      "difficulty": "easy"
    }
  ]
}
```

**Required fields:**
- `question` (String): The question text
- `options` (List<String>): Array of 4 answer options
- `correct` (String): The correct answer (must match one of the options)

**Optional fields:**
- `category` (String): Question category
- `difficulty` (String): Question difficulty

## API Endpoint Examples

### GET Request Example
```
GET https://your-backend.com/api/quiz?category=Science&amount=10
```

### POST Request Example
```json
POST https://your-backend.com/api/quiz/generate
Content-Type: application/json

{
  "category": "Science",
  "amount": 10,
  "difficulty": "medium"
}
```

## Error Handling

The app handles various error scenarios:

1. **Network Errors**: Shows error message with retry button
2. **API Errors**: Displays specific error message from API
3. **Timeout**: 30-second timeout with user-friendly message
4. **Empty Results**: Shows "No questions available" message

## Testing

To test the backend integration:

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Select a category** from the home screen

3. **Check the console** for API request logs (in debug mode)

4. **Test error handling** by:
   - Turning off internet connection
   - Using an invalid API URL
   - Testing with empty responses

## Configuration

### Change Number of Questions

Edit `lib/screens/quiz_screen.dart`:
```dart
final fetchedQuestions = await _quizService.fetchQuestions(
  category: widget.category,
  amount: 15, // Change from 10 to 15
);
```

### Add Difficulty Level

Edit `lib/screens/quiz_screen.dart`:
```dart
final fetchedQuestions = await _quizService.fetchQuestions(
  category: widget.category,
  amount: 10,
  difficulty: 'medium', // 'easy', 'medium', or 'hard'
);
```

### Add Authentication Headers

If your backend requires authentication, edit `lib/services/quiz_service.dart`:

```dart
final response = await http.get(
  uri,
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json',
  },
);
```

## Troubleshooting

### Questions Not Loading

1. **Check internet connection**
2. **Verify API URL** is correct
3. **Check API response format** matches expected format
4. **Review console logs** for error messages

### Questions Loading Slowly

1. **Reduce question amount** (e.g., from 10 to 5)
2. **Check API server performance**
3. **Consider caching** questions locally

### Wrong Questions for Category

1. **Check category mapping** in `_getCategoryId()` method
2. **Verify API category IDs** match your backend
3. **Test API directly** with curl or Postman

## Next Steps

1. ✅ Backend integration is complete
2. 🔄 Test with your backend API
3. 🔄 Customize question format if needed
4. 🔄 Add authentication if required
5. 🔄 Implement caching for offline support (optional)

## Support

If you encounter issues:
1. Check the console logs for detailed error messages
2. Verify your API endpoint is accessible
3. Test your API with a tool like Postman
4. Review the error handling in `quiz_screen.dart`

