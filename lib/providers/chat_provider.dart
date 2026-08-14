import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../data/repositories/chat_repository.dart';

/// P1-3.4：对话状态
class ChatProvider extends ChangeNotifier {
  final ChatRepository _repo;

  ChatProvider({ChatRepository? repo}) : _repo = repo ?? ChatRepository();

  Future<List<ChatSession>> getChatSessions() => _repo.getSessions();

  Future<void> saveChatSession(ChatSession session) =>
      _repo.saveSession(session);

  Future<void> saveMessage(ChatMessage message) => _repo.saveMessage(message);

  Future<List<ChatMessage>> getMessages(String sessionId) =>
      _repo.getMessages(sessionId);

  Future<void> deleteChatSession(String sessionId) =>
      _repo.deleteSession(sessionId);
}
