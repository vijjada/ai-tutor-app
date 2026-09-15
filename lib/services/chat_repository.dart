import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  Future<String> createConversation(String personaId) async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('conversations')
        .insert({'user_id': userId, 'persona_id': personaId})
        .select()
        .single();
    return row['id'];
  }

  Future<void> saveMessage(ChatMessage msg, String conversationId) async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('messages')
        .insert(msg.toSupabaseRow(conversationId, userId));
  }

  Future<List<ChatMessage>> loadHistory(String conversationId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return rows.map<ChatMessage>((r) => ChatMessage.fromSupabaseRow(r)).toList();
  }
}
