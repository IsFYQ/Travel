import 'dart:convert';

/// 对话消息模型
class ChatMessage {
  final String id;
  final String sessionId; // 对话会话ID
  final String role; // 'user' 或 'assistant'
  final String content; // 消息文本
  final List<String> followUpSuggestions; // AI 推荐的追问
  final DateTime timestamp;
  final bool isLoading; // 是否正在加载（流式响应中）

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.followUpSuggestions = const [],
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      'follow_up_suggestions': jsonEncode(followUpSuggestions),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      role: map['role'] as String,
      content: map['content'] as String,
      followUpSuggestions: map['follow_up_suggestions'] != null
          ? List<String>.from(jsonDecode(map['follow_up_suggestions']))
          : [],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  ChatMessage copyWith({
    String? content,
    List<String>? followUpSuggestions,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 对话会话模型
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    this.title = '新对话',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String? ?? '新对话',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
