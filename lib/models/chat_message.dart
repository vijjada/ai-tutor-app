import '../services/ai/chat_message_types.dart';

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final ModelUsed? modelUsed; // null for user messages
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.modelUsed,
    required this.createdAt,
  });

  Map<String, dynamic> toSupabaseRow(String conversationId, String userId) => {
        'id': id,
        'conversation_id': conversationId,
        'user_id': userId,
        'role': role.name,
        'content': content,
        'model_used': modelUsed?.name,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromSupabaseRow(Map<String, dynamic> row) => ChatMessage(
        id: row['id'],
        role: MessageRole.values.byName(row['role']),
        content: row['content'],
        modelUsed: row['model_used'] != null
            ? ModelUsed.values.byName(row['model_used'])
            : null,
        createdAt: DateTime.parse(row['created_at']),
      );
}
