import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  Future<String> send({
    required String systemPrompt,
    required List<Map<String, String>> history,
    String? base64Image, // used later for notes/vision
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final url =

'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey';
    final parts = <Map<String, dynamic>>[
      {'text': systemPrompt},
      ...history.map((m) => {'text': '${m['role']}: ${m['content']}'}),
    ];
    if (base64Image != null) {
      parts.add({
        'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
      });
    }

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': parts}
            ]
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gemini error ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  }
}
