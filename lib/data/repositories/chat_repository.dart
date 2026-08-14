import '../../models/chat_message.dart';
import '../../services/database_service.dart';

/// P1-3.2：对话仓储
class ChatRepository {
  final DatabaseService _db;

  ChatRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  Future<List<ChatSession>> getSessions() => _db.getSessions();

  Future<void> saveSession(ChatSession session) => _db.insertSession(session);

  Future<void> touchSession(String sessionId) => _db.touchSession(sessionId);

  Future<void> deleteSession(String sessionId) =>
      _db.deleteSession(sessionId);

  Future<List<ChatMessage>> getMessages(String sessionId) =>
      _db.getMessages(sessionId);

  Future<void> saveMessage(ChatMessage message) =>
      _db.insertMessage(message);
}
