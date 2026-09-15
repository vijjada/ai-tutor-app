import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/chat_message.dart';
import '../../services/ai/ai_router.dart';
import '../../services/chat_repository.dart';
import '../../services/persona/persona.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Persona _persona = sherlockPersona;
  final _router = AiRouter();
  final _repo = ChatRepository();
  final _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  String? _conversationId;
  bool _sending = false;

  Future<void> _ensureConversation() async {
    _conversationId ??= await _repo.createConversation(_persona.id);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await _ensureConversation();

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _controller.clear();
    });
    await _repo.saveMessage(userMsg, _conversationId!);

    final history = _messages
        .map((m) => {'role': m.role == MessageRole.user ? 'user' : 'assistant', 'content': m.content})
        .toList();

    try {
      final result = await _router.route(
        systemPrompt: _persona.systemPrompt,
        history: history,
        latestUserMessage: text,
      );
      final aiMsg = ChatMessage(
        id: const Uuid().v4(),
        role: MessageRole.assistant,
        content: result.content,
        modelUsed: result.modelUsed,
        createdAt: DateTime.now(),
      );
      setState(() => _messages.add(aiMsg));
      await _repo.saveMessage(aiMsg, _conversationId!);
} catch (e) {
      setState(() => _messages.add(ChatMessage(
            id: const Uuid().v4(),
            role: MessageRole.assistant,
            content: 'All models are unavailable right now. Try again shortly.',
            createdAt: DateTime.now(),
          )));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<Persona>(
          value: _persona,
          dropdownColor: Theme.of(context).colorScheme.surface,
          items: personas
              .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
              .toList(),
          onChanged: (p) => setState(() {
            _persona = p!;
            _conversationId = null; // new persona -> new conversation
            _messages.clear();
          }),
        ),
      ),
      body: Column(
        children: [
          // Placeholder icon where the Rive character mounts in Phase 3
          Container(
            height: 120,
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 40,
              child: Text(_persona.displayName[0]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == MessageRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.content),
                        if (m.modelUsed != null)
                          Text(
                            '— ${m.modelUsed!.name}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Ask your tutor...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
