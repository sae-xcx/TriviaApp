import 'dart:convert';
import 'package:flutter/material.dart';
import 'question.dart';
import 'trivia_api.dart';

void main() => runApp(const MaterialApp(home: TriviaScreen()));

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});
  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  bool _loading = true;
  String? _error;
  List<Question> _questions = [];
  int _index = 0;
  int _score = 0;
  String? _selected; // null = not answered yet

  // Phase 3: simulated score sync
  bool _syncing = false;
  bool _synced = false;
  String? _payloadText;

  @override
  void initState() {
    super.initState();
    _loadTriviaData();
  }

  Future<void> _loadTriviaData() async {
    setState(() {
      _loading = true;
      _error = null;
      _index = 0;
      _score = 0;
      _selected = null;
      _syncing = false;
      _synced = false;
      _payloadText = null;
    });
    try {
      final q = await fetchQuestions();
      setState(() { _questions = q; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Could not load questions: $e'; _loading = false; });
    }
  }

  void _answerQuestion(String option) {
    if (_selected != null) return; // already answered, ignore extra taps
    setState(() {
      _selected = option;
      if (option == _questions[_index].correctAnswer) _score++;
    });
  }

  void _nextQuestion() {
    setState(() {
      _index++;
      _selected = null;
    });
  }

  // SIMULATION ONLY: waits briefly and marks the score as synced.
  // It does NOT send anything to a server.
  Future<void> _syncScoreToCloud() async {
    if (_syncing || _synced) return;
    setState(() => _syncing = true);

    final payload = {
      'score': _score,
      'total_questions': _questions.length,
      'submitted_at': DateTime.now().toIso8601String(),
      'simulated': true,
    };

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _syncing = false;
      _synced = true;
      _payloadText = const JsonEncoder.withIndent('  ').convert(payload);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'SIMULATION: score $_score/${_questions.length} marked as synced. '
              'Nothing was sent to a server.',
        ),
      ),
    );
  }

  Color? _colorFor(String option, Question q) {
    if (_selected == null) return null;
    if (option == q.correctAnswer) return Colors.green;
    if (option == _selected) return Colors.red;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadTriviaData, child: const Text('Retry')),
          ],
        ),
      );
    } else if (_index >= _questions.length) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Round complete!', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
              Text('Score: $_score / ${_questions.length}',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (_syncing || _synced) ? null : _syncScoreToCloud,
                child: Text(_syncing
                    ? 'Syncing (simulation)...'
                    : _synced
                    ? 'Synced (simulation)'
                    : 'Sync Score to Leaderboard (Simulation)'),
              ),
              if (_synced && _payloadText != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Simulated payload (not sent to any server):',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(_payloadText!,
                    style: const TextStyle(fontFamily: 'monospace')),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadTriviaData, child: const Text('Play again')),
            ],
          ),
        ),
      );
    } else {
      final q = _questions[_index];
      final isLast = _index == _questions.length - 1;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(value: (_index + 1) / _questions.length),
          const SizedBox(height: 12),
          Text('Question ${_index + 1} of ${_questions.length}  •  Score: $_score'),
          const SizedBox(height: 12),
          Text(q.questionText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          for (final o in q.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => _answerQuestion(o),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorFor(o, q),
                  foregroundColor:
                  _colorFor(o, q) == null ? null : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(o),
              ),
            ),
          if (_selected != null)
            FilledButton(
              onPressed: _nextQuestion,
              child: Text(isLast ? 'See results' : 'Next question'),
            ),
        ],
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Trivia')), body: body);
  }
}