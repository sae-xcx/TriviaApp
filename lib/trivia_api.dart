import 'dart:convert';
import 'package:http/http.dart' as http;
import 'question.dart';

Future<List<Question>> fetchQuestions() async {
  final uri = Uri.parse(
    'https://opentdb.com/api.php?amount=5&category=9&difficulty=easy&type=multiple',
  );

  final response = await http.get(uri).timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) {
    throw Exception('Server returned HTTP ${response.statusCode}.');
  }

  final data = json.decode(response.body) as Map<String, dynamic>;
  if (data['response_code'] != 0) {
    throw FormatException('Trivia API response_code: ${data['response_code']}');
  }

  final results = data['results'] as List<dynamic>;
  if (results.isEmpty) {
    throw const FormatException('No questions were returned.');
  }

  return results
      .map((q) => Question.fromJson(q as Map<String, dynamic>))
      .toList();
}