import 'chat_message_types.dart' show ModelUsed;
import 'groq_service.dart';
import 'gemini_service.dart';
import 'deepseek_service.dart';

class AiRouteResult {
  final String content;
  final ModelUsed modelUsed;
  AiRouteResult(this.content, this.modelUsed);
}

class AiRouter {
  final _groq = GroqService();
  final _gemini = GeminiService();
  final _deepseek = DeepSeekService();

  // Simple keyword rule — expand this list as you see real query patterns.
  static const _mathPhysicsKeywords = [
    'solve', 'equation', 'derivative', 'integral', 'proof', 'velocity',
    'force', 'acceleration', 'physics', 'algebra', 'geometry', 'calculus',
    'logic', 'theorem', 'vector', 'matrix', 'probability',
  ];

  bool _isMathOrPhysics(String message) {
    final lower = message.toLowerCase();
    return _mathPhysicsKeywords.any((kw) => lower.contains(kw));
  }

  Future<AiRouteResult> route({
    required String systemPrompt,
    required List<Map<String, String>> history,
    required String latestUserMessage,
    String? base64Image,
  }) async {
    // Rule 1: image attached -> Gemini directly (vision only Gemini supports)
    if (base64Image != null) {
      final text = await _gemini.send(
        systemPrompt: systemPrompt,
        history: history,
        base64Image: base64Image,
      );
      return AiRouteResult(text, ModelUsed.gemini);
    }

    // Rule 2: math/physics/logic keyword -> DeepSeek, fallback Gemini, then Groq
    if (_isMathOrPhysics(latestUserMessage)) {
      try {
        final text = await _deepseek.send(
          systemPrompt: systemPrompt,
          history: history,
        );
        return AiRouteResult(text, ModelUsed.deepseek);
      } catch (e) {
        try {
          final text = await _gemini.send(
            systemPrompt: systemPrompt,
            history: history,
          );
          return AiRouteResult(text, ModelUsed.gemini);
        } catch (_) {
          final text = await _groq.send(
            systemPrompt: systemPrompt,
            history: history,
          );
          return AiRouteResult(text, ModelUsed.groq);
        }
      }
    }

    // Rule 3: default -> Groq (fast), fallback Gemini

    try {
      final text = await _groq.send(
        systemPrompt: systemPrompt,
        history: history,
      );
      return AiRouteResult(text, ModelUsed.groq);
    } catch (_) {
      final text = await _gemini.send(
        systemPrompt: systemPrompt,
        history: history,
      );
      return AiRouteResult(text, ModelUsed.gemini);
    }
  }
}
