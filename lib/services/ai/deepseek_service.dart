import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeepSeekService {
  static const _url = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> send({
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    final response = await http
        .post(
          Uri.parse(_url),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'deepseek/deepseek-r1:free',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              ...history,
            ],
          }),
        )
        .timeout(const Duration(seconds: 25)); // R1 reasoning is slower

    if (response.statusCode != 200) {
      throw Exception('DeepSeek error ${response.statusCode}: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
