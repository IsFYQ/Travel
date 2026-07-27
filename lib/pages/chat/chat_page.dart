import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_provider.dart';
import '../../models/chat_message.dart';
import '../../models/itinerary.dart';
import '../../services/ai_service.dart';
import '../../exceptions/missing_credential_exception.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../app/travel_icons.dart';

/// AI 对话页面
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ai = AiService();
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _uuid = const Uuid();

  String? _sessionId;
  List<ChatMessage> _messages = [];
  bool _isSending = false;
  String? _recommendation;
  bool _showRecommendation = true;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  /// 构建完整用户画像（含 UserProfile + 旅行记录统计）
  Future<String> _buildUserProfile() async {
    final provider = context.read<AppProvider>();
    final stats = provider.statistics;
    final records = provider.records;

    final totalCost = (stats['total_cost'] ?? 0.0) as double;
    final recordCount = (stats['record_count'] ?? 0) as int;
    final avgBudget = recordCount > 0 ? totalCost / recordCount : 0.0;
    final lastTrip = records.isNotEmpty ? records.first.destination : '';

    final profile = await _ai.getUserProfile();

    return _ai.buildUserProfileFromModel(
      profile: profile,
      visitedPlaces: provider.destinations,
      avgBudget: avgBudget,
      totalTrips: recordCount,
      totalDays: (stats['total_days'] ?? 0) as int,
      lastTrip: lastTrip,
    );
  }

  Future<void> _initSession() async {
    final provider = context.read<AppProvider>();
    final sessions = await provider.getChatSessions();

    if (sessions.isNotEmpty) {
      _sessionId = sessions.first.id;
      _messages = await provider.getMessages(_sessionId!);
    } else {
      _sessionId = _uuid.v4();
      await provider.saveChatSession(ChatSession(id: _sessionId!));
    }

    if (!mounted) return;
    _loadRecommendation();
    setState(() {});
  }

  /// 剥离 AI 回复中的 JSON/代码块和多余格式
  static String _cleanRecommendation(String raw) {
    // 移除 ```json ... ``` 代码块
    var result = raw.replaceAll(
      RegExp(r'```json\s*\{[\s\S]*?\}\s*```', multiLine: true),
      '',
    );
    // 移除其他代码块 ```...```
    result = result.replaceAll(
      RegExp(r'```[\s\S]*?```', multiLine: true),
      '',
    );
    // 移除可能的重复推荐（AI 有时返回两段）
    final lines = result.split('\n');
    final seen = <String>{};
    final uniqueLines = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) {
        uniqueLines.add(trimmed);
      }
    }
    return uniqueLines.join('\n').trim();
  }

  Future<void> _loadRecommendation() async {
    if (!await _ai.hasApiKey()) return;
    try {
      final result = await _ai.recommendDestination(
        userProfile: await _buildUserProfile(),
      );
      final cleaned = _cleanRecommendation(result);
      if (mounted && cleaned.isNotEmpty) {
        setState(() => _recommendation = cleaned);
      }
    } catch (_) {}
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    final provider = context.read<AppProvider>();

    if (!await _ai.hasApiKey()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在"我的" → "API设置"中配置 DeepSeek API Key')),
      );
      Navigator.pushNamed(context, AppRoutes.apiSettings);
      return;
    }

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sessionId: _sessionId!,
      role: 'user',
      content: text.trim(),
    );
    await provider.saveMessage(userMsg);

    // 首条用户消息时更新会话标题
    if (_messages.where((m) => m.isUser).length <= 1) {
      await _updateSessionTitle(text.trim());
    }

    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });

    _inputController.clear();
    _scrollToBottom();

    final isItineraryRequest = _isItineraryRequest(text);
    String? taskInstruction;
    if (isItineraryRequest) {
      taskInstruction = await _ai.getItineraryTaskInstruction();
    }

    final aiMsgId = _uuid.v4();
    setState(() {
      _messages.add(ChatMessage(
        id: aiMsgId,
        sessionId: _sessionId!,
        role: 'assistant',
        content: '',
        isLoading: true,
      ));
    });

    final fullResponse = StringBuffer();
    try {
      final stream = _ai.sendMessageStream(
        userMessage: text.trim(),
        // P0-10：排除本次 userMsg，避免请求体重复
        history: _messages
            .where((m) => !m.isLoading && m.id != userMsg.id)
            .toList(),
        userProfile: await _buildUserProfile(),
        taskInstruction: taskInstruction,
      );

      await for (final chunk in stream) {
        fullResponse.write(chunk);
        final currentContent = fullResponse.toString();
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == aiMsgId);
            if (index >= 0) {
              _messages[index] =
                  _messages[index].copyWith(content: currentContent);
            }
          });
          _scrollToBottom();
        }
      }

      final rawContent = fullResponse.toString();
      final suggestions = AiService.parseFollowUpSuggestions(rawContent);
      final storageContent = AiService.stripSuggestionsOnly(rawContent);

      final aiMsg = ChatMessage(
        id: aiMsgId,
        sessionId: _sessionId!,
        role: 'assistant',
        content: storageContent,
        followUpSuggestions: suggestions,
      );
      await provider.saveMessage(aiMsg);

      final meta = AiService.extractItineraryMeta(rawContent);
      if (meta != null) {
        final dest = meta['destination'] as String?;
        if (dest != null && dest.isNotEmpty) {
          await _updateSessionTitleTo(dest);
        }
      }

      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMsgId);
          if (index >= 0) _messages[index] = aiMsg;
        });
      }
    } on MissingCredentialException catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.id == aiMsgId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
        Navigator.pushNamed(context, AppRoutes.apiSettings);
      }
    } catch (e) {
      // P0-8：异常时替换为错误气泡，不持久化
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == aiMsgId);
          if (index >= 0) {
            _messages[index] = _messages[index].copyWith(
              content: '发送失败：$e',
              isLoading: false,
            );
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool _isItineraryRequest(String text) {
    final keywords = [
      '攻略', '行程', '规划', '帮我规划', '帮我生成',
      '安排行程', '旅行计划', '行程规划', '制定',
    ];
    return keywords.any((kw) => text.contains(kw));
  }

  // 旧版自动保存对话框已移除，现改用 _generateItineraryFromChat()

  String? _extractDestination(String response) {
    final jsonMatch =
        RegExp(r'"destination"\s*:\s*"([^"]+)"').firstMatch(response);
    if (jsonMatch != null) return jsonMatch.group(1);
    final textMatch = RegExp(r'推荐目的地[：:]\s*(.+)').firstMatch(response);
    if (textMatch != null) return textMatch.group(1)?.trim();
    return null;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Column(
        children: [
          // 自定义头部
          Container(
            padding: EdgeInsets.fromLTRB(16, top + 15, 16, 12),
            color: AppTheme.backgroundColor,
            child: Row(
              children: [
                // 查看历史对话
                GestureDetector(
                  onTap: _showHistoryDialog,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.inputBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.history, size: 18, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 生成攻略
                GestureDetector(
                  onTap: _generateItineraryFromChat,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.inputBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: TravelIcons.guideToDiary(size: 18, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'AI对话',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: _newSession,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.inputBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: TravelIcons.newChat(
                          size: 18, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 今日推荐卡片
          if (_recommendation != null && _showRecommendation)
            _buildRecommendationCard(),
          if (_recommendation != null && !_showRecommendation)
            _buildShowRecommendationButton(),
          // 消息列表
          Expanded(child: _buildMessageList()),
          // 输入框
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentMint.withOpacity(0.3), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('✨ ', style: TextStyle(fontSize: 16)),
                const Expanded(
                  child: Text(
                    '今日推荐',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showRecommendation = false),
                  child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.black54,
                  builder: (ctx) => Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      20 + MediaQuery.of(ctx).padding.bottom,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('✨ ', style: TextStyle(fontSize: 20)),
                            const Expanded(
                              child: Text(
                                '今日推荐',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Icon(Icons.close, size: 24, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _recommendation!,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.8,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Text(
                _recommendation!,
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowRecommendationButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: GestureDetector(
        onTap: () => setState(() => _showRecommendation = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC3E1FC), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(
                '显示每日推荐',
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI 欢迎气泡
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  '你好！我是你的旅行搭子。\n问我任何旅游相关的问题吧',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF333333),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 快捷建议
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  '推荐一个适合周末的去处',
                  '帮我规划桂林的行程',
                  '预算1500怎么玩',
                ].map((text) => _suggestionChip(text)).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC3E1FC), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: TravelIcons.aiAvatar(size: 20),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: Radius.circular(isUser ? 15 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 15),
                    ),
                  ),
                  child: message.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : isUser
                          ? Text(
                              message.content,
                              style: const TextStyle(
                                color: Color(0xFFF8FAFC),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            )
                          : MarkdownBody(
                              data: AiService.cleanContent(message.content),
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                                listBullet: const TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 14,
                                ),
                                h2: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                                h3: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),
          // 在 AI 消息气泡下方显示追问建议按钮
          if (!isUser && !message.isLoading && message.followUpSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.followUpSuggestions.map((s) => _suggestionChip(s)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          14, 7, 14, 7 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) => setState(() {}),
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasFocus ? AppTheme.primaryColor : AppTheme.borderColor,
                        width: hasFocus ? 1.5 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: '请输入你的问题',
                        hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: _sendMessage,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap:
                _isSending ? null : () => _sendMessage(_inputController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSending
                    ? Colors.grey.shade300
                    : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: TravelIcons.send(size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _newSession() async {
    final provider = context.read<AppProvider>();
    _sessionId = _uuid.v4();
    await provider.saveChatSession(ChatSession(id: _sessionId!));
    setState(() {
      _messages = [];
      _recommendation = null;
      _showRecommendation = true;
    });
    _loadRecommendation();
  }

  /// 从当前对话生成攻略（含冲突检测）
  Future<void> _generateItineraryFromChat() async {
    if (_messages.isEmpty) {
      _showSnackBar('当前没有对话内容');
      return;
    }

    // 从最后一条 assistant 消息中找攻略内容
    ChatMessage? itineraryMsg;
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.role == 'assistant' && !m.isLoading) {
        final meta = AiService.extractItineraryMeta(m.content);
        if (meta != null || _hasItineraryRaw(i)) {
          itineraryMsg = m;
          break;
        }
      }
    }

    if (itineraryMsg == null) {
      _showSnackBar('当前对话中没有攻略内容，请先让AI帮你规划行程');
      return;
    }

    // 解析攻略元数据
    final meta = AiService.extractItineraryMeta(itineraryMsg.content);
    String destination =
        meta?['destination'] as String? ??
        _extractDestination(itineraryMsg.content) ??
        '未命名';
    int days = meta?['days'] as int? ?? 1;
    double budget = (meta?['total_budget'] as num?)?.toDouble() ?? 0;

    // 解析结构化日计划
    final dayPlans = AiService.parseItineraryText(itineraryMsg.content);
    if (dayPlans.isNotEmpty && days <= 1) {
      days = dayPlans.length;
    }

    // 如果 AI 未提供总预算，从行程项和住宿中累加计算
    if (budget <= 0 && dayPlans.isNotEmpty) {
      budget = dayPlans.fold<double>(0, (sum, day) {
        final itemsCost = day.items.fold<double>(0, (s, item) => s + item.cost);
        final accCost = day.accommodation?.cost ?? 0;
        return sum + itemsCost + accCost;
      });
    }

    // 清理正文（去除 JSON 和 suggestions 标记）
    final cleanContent = AiService.cleanContent(itineraryMsg.content);

    // 冲突检测
    final provider = context.read<AppProvider>();
    await provider.loadItineraries();
    final existing = provider.itineraries.where(
      (it) => it.destination == destination,
    ).toList();

    if (existing.isNotEmpty && mounted) {
      // 存在同名攻略，询问用户
      final shouldOverwrite = await showModalBottomSheet<bool>(
        context: context,
        barrierColor: Colors.black54,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusModal)),
        ),
        builder: (ctx) {
          final bottom = MediaQuery.of(ctx).padding.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppTheme.warningSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 28, color: AppTheme.warning),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '攻略已存在',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '已存在「$destination」的攻略，请选择操作方式。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
                                side: const BorderSide(color: AppTheme.borderColor),
                              ),
                            ),
                            child: const Text('新增不覆盖', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusBtn),
                              ),
                            ),
                            child: const Text('覆盖攻略', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (shouldOverwrite == true) {
        // 覆盖
        final updated = existing.first.copyWith(
          rawContent: cleanContent,
          days: days,
          totalBudget: budget,
          dayPlans: dayPlans.isNotEmpty ? dayPlans : existing.first.dayPlans,
        );
        await provider.saveItinerary(updated);
        _showSnackBar('「$destination」攻略已更新！');
      } else if (shouldOverwrite == false) {
        // 新增
        final newIt = Itinerary(
          id: _uuid.v4(),
          destination: destination,
          rawContent: cleanContent,
          days: days,
          totalBudget: budget,
          dayPlans: dayPlans,
          sourceChatId: _sessionId,
        );
        await provider.saveItinerary(newIt);
        _showSnackBar('「$destination」攻略已新增！');
      } else {
        return; // 取消
      }
    } else {
      // 无冲突，直接保存
      final newIt = Itinerary(
        id: _uuid.v4(),
        destination: destination,
        rawContent: cleanContent,
        days: days,
        totalBudget: budget,
        dayPlans: dayPlans,
        sourceChatId: _sessionId,
      );
      await provider.saveItinerary(newIt);
      _showSnackBar('「$destination」攻略已保存到我的攻略！');
    }
  }

  bool _hasItineraryRaw(int index) {
    // 检查当前消息是否可能是攻略（基于关键词）
    if (index < 0 || index >= _messages.length) return false;
    final content = _messages[index].content;
    return content.contains('Day 1') || content.contains('第一天') ||
        content.contains('行程规划');
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  /// 显示历史对话列表
  Future<void> _showHistoryDialog() async {
    final provider = context.read<AppProvider>();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _HistorySessionsSheet(
        provider: provider,
        currentSessionId: _sessionId,
        onSelectSession: (sessionId) async {
          Navigator.pop(ctx);
          await _loadSession(sessionId);
        },
      ),
    );
  }

  /// 加载指定会话
  Future<void> _loadSession(String sessionId) async {
    final provider = context.read<AppProvider>();
    final messages = await provider.getMessages(sessionId);
    if (!mounted) return;
    setState(() {
      _sessionId = sessionId;
      _messages = messages;
    });
    _scrollToBottom();
  }

  /// 更新会话标题（用用户首条消息的前20字）
  Future<void> _updateSessionTitle(String firstUserMessage) async {
    final provider = context.read<AppProvider>();
    final sessions = await provider.getChatSessions();
    final current = sessions.where((s) => s.id == _sessionId).firstOrNull;
    if (current != null && (current.title.isEmpty || current.title == '新对话')) {
      final title = firstUserMessage.length > 20
          ? '${firstUserMessage.substring(0, 20)}...'
          : firstUserMessage;
      final updated = ChatSession(
        id: current.id,
        title: title,
        createdAt: current.createdAt,
      );
      await provider.saveChatSession(updated);
    }
  }

  /// 用目的地名称更新会话标题（AI生成攻略后调用）
  Future<void> _updateSessionTitleTo(String destination) async {
    final provider = context.read<AppProvider>();
    final sessions = await provider.getChatSessions();
    final current = sessions.where((s) => s.id == _sessionId).firstOrNull;
    if (current != null) {
      final updated = ChatSession(
        id: current.id,
        title: destination,
        createdAt: current.createdAt,
      );
      await provider.saveChatSession(updated);
    }
  }

  String _formatSessionTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}月${dt.day}日';
  }
}

/// P0-14：历史对话列表，删除后原地刷新而非递归重开弹窗
class _HistorySessionsSheet extends StatefulWidget {
  final AppProvider provider;
  final String? currentSessionId;
  final Future<void> Function(String sessionId) onSelectSession;

  const _HistorySessionsSheet({
    required this.provider,
    required this.currentSessionId,
    required this.onSelectSession,
  });

  @override
  State<_HistorySessionsSheet> createState() => _HistorySessionsSheetState();
}

class _HistorySessionsSheetState extends State<_HistorySessionsSheet> {
  late List<ChatSession> _sessions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await widget.provider.getChatSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  const Text('历史对话',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        size: 20, color: AppTheme.textTertiary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions.isEmpty
                      ? const Center(
                          child: Text('暂无历史对话',
                              style: TextStyle(
                                  fontSize: 14, color: AppTheme.textTertiary)),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _sessions.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (_, i) {
                            final s = _sessions[i];
                            final isCurrent = s.id == widget.currentSessionId;
                            return Dismissible(
                              key: Key(s.id),
                              direction: isCurrent
                                  ? DismissDirection.none
                                  : DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red.withOpacity(0.8),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                await widget.provider.deleteChatSession(s.id);
                                await _loadSessions();
                              },
                              child: ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppTheme.primaryColor
                                            .withOpacity(0.12)
                                        : AppTheme.inputBgColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                    color: isCurrent
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                title: Text(
                                  s.title.isEmpty ? '新对话' : s.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _formatChatSessionTime(s.updatedAt),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary),
                                ),
                                onTap: isCurrent
                                    ? () => Navigator.pop(context)
                                    : () => widget.onSelectSession(s.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatChatSessionTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
  if (diff.inDays < 1) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return '${dt.month}月${dt.day}日';
}
