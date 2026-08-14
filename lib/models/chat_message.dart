import 'dart:convert';

/// 对话消息模型
class ChatMessage {
  final String id;
  final String sessionId;
  final String role;
  final String content;
  /// P1-3.10：落库时预计算的展示文本（去除 itinerary JSON 等）
  final String? displayContent;
  final List<String> followUpSuggestions;
  final DateTime timestamp;
  final bool isLoading;

  /// 运行时懒加载缓存，不参与序列化
  String? _cleanedCache;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.displayContent,
    this.followUpSuggestions = const [],
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  /// P1-3.10：优先用持久化 displayContent，否则懒加载 clean 结果
  String displayText(String Function(String) clean) {
    if (displayContent != null && displayContent!.isNotEmpty) {
      return displayContent!;
    }
    return _cleanedCache ??= clean(content);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role,
      'content': content,
      if (displayContent != null) 'display_content': displayContent,
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
      displayContent: map['display_content'] as String?,
      followUpSuggestions: map['follow_up_suggestions'] != null
          ? List<String>.from(jsonDecode(map['follow_up_suggestions']))
          : [],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  ChatMessage copyWith({
    String? content,
    String? displayContent,
    List<String>? followUpSuggestions,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      displayContent: displayContent ?? this.displayContent,
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
