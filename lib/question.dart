class Question {
  final String questionText;
  final String correctAnswer;
  final List<String> options;

  Question({
    required this.questionText,
    required this.correctAnswer,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final correct = _decode(json['correct_answer'] as String);
    final incorrect = (json['incorrect_answers'] as List<dynamic>)
        .map((a) => _decode(a as String))
        .toList();
    final options = [...incorrect, correct]..shuffle();
    return Question(
      questionText: _decode(json['question'] as String),
      correctAnswer: correct,
      options: options,
    );
  }

  static String _decode(String s) {
    const named = {
      '&quot;': '"',
      '&apos;': "'",
      '&lt;': '<',
      '&gt;': '>',
      '&shy;': '', // soft hyphen: invisible, so remove it
      '&rsquo;': '’',
      '&lsquo;': '‘',
      '&rdquo;': '”',
      '&ldquo;': '“',
      '&eacute;': 'é',
      '&egrave;': 'è',
      '&aacute;': 'á',
      '&iacute;': 'í',
      '&oacute;': 'ó',
      '&uacute;': 'ú',
      '&ouml;': 'ö',
      '&uuml;': 'ü',
      '&auml;': 'ä',
      '&ntilde;': 'ñ',
      '&ccedil;': 'ç',
      '&deg;': '°',
      '&hellip;': '…',
      '&ndash;': '–',
      '&mdash;': '—',
      '&nbsp;': ' ',
    };
    var out = s;
    for (final e in named.entries) {
      out = out.replaceAll(e.key, e.value);
    }
    // numeric entities: decimal (&#039;) and hex (&#x27;)
    out = out.replaceAllMapped(
      RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m[1]!)),
    );
    out = out.replaceAllMapped(
      RegExp(r'&#[xX]([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
    );
    return out.replaceAll('&amp;', '&'); // last, to avoid double-decoding
  }
}