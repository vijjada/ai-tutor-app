import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> send({
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    final response = await http
        .post(
          Uri.parse(_url),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
'model': 'openai/gpt-oss-120b',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              ...history,
            ],
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Groq error ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
