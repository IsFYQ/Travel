import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../models/itinerary.dart';
import '../models/itinerary_item.dart';
import '../models/accommodation_info.dart';
import '../exceptions/missing_credential_exception.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import 'prompt_builder.dart';

/// DeepSeek API 服务
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  static const String _baseUrl = 'https://api.deepseek.com';
  static const String _chatEndpoint = '/chat/completions';
  static const _storage = FlutterSecureStorage();
  static const String _apiKeyKey = 'deepseek_api_key';
  static const String _homeCityKey = 'user_home_city';
  static const String _userProfileKey = 'user_profile_json';

  // Prompt 模板缓存
  final Map<String, String> _promptCache = {};

  /// 设置 API Key
  Future<void> setApiKey(String key) async {
    await _storage.write(key: _apiKeyKey, value: key);
  }

  /// 获取居住城市
  Future<String> getHomeCity() async {
    final city = await _storage.read(key: _homeCityKey);
    return city ?? '';
  }

  /// 保存居住城市
  Future<void> setHomeCity(String city) async {
    await _storage.write(key: _homeCityKey, value: city);
  }

  /// 读取完整用户画像
  Future<UserProfile> getUserProfile() async {
    final raw = await _storage.read(key: _userProfileKey);
    if (raw != null && raw.isNotEmpty) {
      return UserProfile.fromJsonString(raw);
    }
    // 迁移旧数据：从旧 key 读取居住城市
    final legacyCity = await _storage.read(key: _homeCityKey);
    return UserProfile(homeCity: legacyCity ?? '');
  }

  /// 持久化完整用户画像（同时同步旧 homeCity key）
  Future<void> saveUserProfile(UserProfile profile) async {
    await _storage.write(key: _userProfileKey, value: profile.toJsonString());
    // 同步旧 key，向后兼容
    await _storage.write(key: _homeCityKey, value: profile.homeCity);
  }

  /// P1-3.11：从 UserProfile 模型渲染画像 prompt 文本
  String renderProfilePrompt({
    required UserProfile profile,
    List<String> visitedPlaces = const [],
    double avgBudget = 0,
    int totalTrips = 0,
    int totalDays = 0,
    String lastTrip = '',
  }) {
    final buffer = StringBuffer('【用户旅行档案】\n');

    if (profile.nickname.isNotEmpty) {
      buffer.writeln('- 称呼：${profile.nickname}');
    }
    if (profile.homeCity.isNotEmpty) {
      buffer.writeln('- 居住城市（出发地）：${profile.homeCity}');
    }
    if (visitedPlaces.isNotEmpty) {
      buffer.writeln('- 去过的地方：${visitedPlaces.join('、')}');
    }
    if (totalTrips > 0) {
      buffer.writeln('- 累计旅行次数：$totalTrips次');
    }
    if (totalDays > 0) {
      buffer.writeln('- 累计旅行天数：$totalDays天');
    }
    if (lastTrip.isNotEmpty) {
      buffer.writeln('- 上次旅行：$lastTrip');
    }
    if (profile.travelStyles.isNotEmpty) {
      buffer.writeln('- 旅行风格：${profile.travelStyles.join('、')}');
    }
    if (profile.foodPrefs.isNotEmpty) {
      buffer.writeln('- 饮食偏好：${profile.foodPrefs.join('、')}');
    }
    if (profile.budgetLevel != null) {
      buffer.writeln('- 预算偏好：${profile.budgetLevel!.label}');
    } else if (avgBudget > 0) {
      buffer.writeln('- 平均单次预算：${avgBudget.toStringAsFixed(0)}元');
    }
    if (profile.groupSize != null) {
      buffer.writeln('- 常见出行人数：${profile.groupSize!.label}');
    }
    if (profile.companions.isNotEmpty) {
      buffer.writeln('- 同行对象：${profile.companions.join('、')}');
    }
    if (profile.avoidances.isNotEmpty) {
      buffer.writeln('- 忌讳事项：${profile.avoidances.join('、')}（请在推荐时主动规避）');
    }
    return buffer.toString();
  }

  /// 获取 API Key（P0-5：未配置时返回 null，不再回落硬编码值）
  Future<String?> getApiKey() async {
    final key = await _storage.read(key: _apiKeyKey);
    if (key == null || key.isEmpty) return null;
    return key;
  }

  /// 检查 API Key 是否已配置
  Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _apiKeyKey);
    return key != null && key.isNotEmpty;
  }

  /// 加载 Prompt 模板（优先使用用户自定义版本）
  Future<String> _loadPrompt(String filename) async {
    if (_promptCache.containsKey(filename)) {
      return _promptCache[filename]!;
    }
    // 优先读用户自定义版本
    final custom = await _storage.read(key: 'prompt_$filename');
    final content = (custom != null && custom.isNotEmpty)
        ? custom
        : await rootBundle.loadString('assets/prompts/$filename');
    _promptCache[filename] = content;
    return content;
  }

  /// 加载 Prompt（带用户自定义覆盖）
  Future<String> loadPromptWithOverride(String filename) async {
    return await _loadPrompt(filename);
  }

  /// 保存用户自定义提示词
  Future<void> saveCustomPrompt(String filename, String content) async {
    await _storage.write(key: 'prompt_$filename', value: content);
    // 清除缓存，下次调用立即生效
    _promptCache.remove(filename);
  }

  /// 重置提示词为默认版本
  Future<void> resetPrompt(String filename) async {
    await _storage.delete(key: 'prompt_$filename');
    _promptCache.remove(filename);
  }

  /// 判断是否有自定义版本
  Future<bool> hasCustomPrompt(String filename) async {
    final custom = await _storage.read(key: 'prompt_$filename');
    return custom != null && custom.isNotEmpty;
  }

  /// 获取攻略生成的任务指令（公开方法）
  Future<String> getItineraryTaskInstruction() async {
    return await _loadPrompt('generate_itinerary.txt');
  }

  /// 构建系统提示词（Layer 1 + Layer 2 + Layer 4 基础）
  Future<String> _buildSystemPrompt({
    String? userProfile,
    String? ragContext,
    String? taskInstruction,
  }) async {
    final systemPrompt = await _loadPrompt('system_prompt.txt');
    final followUpInstruction =
        await _loadPrompt('followup_suggestions.txt');

    return PromptBuilder.assemble(
      systemPersona: systemPrompt,
      profileText: userProfile,
      ragContext: ragContext,
      taskInstruction: taskInstruction,
      followUpInstruction: followUpInstruction,
    );
  }

  /// P1-2.11：API Key 连接测试（不写入 storage）
  Future<AiTestResult> testApiKey(String key) async {
    if (key.trim().isEmpty) {
      throw MissingCredentialException('DeepSeek', '请输入 API Key');
    }
    try {
      final json = await ApiClient().postJson(
        uri: Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${key.trim()}',
        },
        body: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': 'hi'},
          ],
          'max_tokens': 5,
        },
        retryOnFailure: false,
      );
      final model = json['model'] as String? ?? 'deepseek-chat';
      return AiTestResult(success: true, model: model);
    } on UnauthorizedException {
      return const AiTestResult(success: false, errorType: AiTestErrorType.invalidKey);
    } on InsufficientBalanceException {
      return const AiTestResult(success: false, errorType: AiTestErrorType.insufficientBalance);
    } on RateLimitException {
      return const AiTestResult(success: false, errorType: AiTestErrorType.rateLimit);
    } on TimeoutApiException {
      return const AiTestResult(success: false, errorType: AiTestErrorType.timeout);
    } on NetworkException {
      return const AiTestResult(success: false, errorType: AiTestErrorType.network);
    }
  }

  /// 构建消息列表，P0-10：防止 history 末条与 userMessage 重复
  List<Map<String, String>> _buildMessages({
    required String systemPrompt,
    required List<ChatMessage> history,
    required String userMessage,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.takeLast(20).map((msg) => {
            'role': msg.role,
            'content': msg.content,
          }),
    ];
    final last = history.isNotEmpty ? history.last : null;
    if (last == null ||
        last.role != 'user' ||
        last.content != userMessage) {
      messages.add({'role': 'user', 'content': userMessage});
    }
    return messages;
  }

  /// 发送对话请求（流式）
  Stream<String> sendMessageStream({
    required String userMessage,
    required List<ChatMessage> history,
    String? userProfile,
    String? ragContext,
    String? taskInstruction,
    double temperature = 0.5,
    int maxTokens = 2048,
  }) async* {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw MissingCredentialException('DeepSeek', '请先在"我的" → "API设置"中配置 DeepSeek API Key');
    }

    final systemPrompt = await _buildSystemPrompt(
      userProfile: userProfile,
      ragContext: ragContext,
      taskInstruction: taskInstruction,
    );

    final messages = _buildMessages(
      systemPrompt: systemPrompt,
      history: history,
      userMessage: userMessage,
    );

    final requestBody = {
      'model': 'deepseek-chat',
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    };

    try {
      final response = await ApiClient().postStream(
        uri: Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        throw ServerException(response.statusCode, 'API 请求失败 (${response.statusCode})');
      }

      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta'];
            final content = delta?['content'] as String?;
            if (content != null) yield content;
          } catch (_) {}
        }
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  /// 发送非流式请求（用于攻略生成等场景）
  Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
    String? userProfile,
    String? ragContext,
    String? taskInstruction,
    double temperature = 0.3,
    int maxTokens = 4096,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw MissingCredentialException('DeepSeek', '请先在"我的" → "API设置"中配置 DeepSeek API Key');
    }

    final systemPrompt = await _buildSystemPrompt(
      userProfile: userProfile,
      ragContext: ragContext,
      taskInstruction: taskInstruction,
    );

    final messages = _buildMessages(
      systemPrompt: systemPrompt,
      history: history,
      userMessage: userMessage,
    );

    try {
      final json = await ApiClient().postJson(
        uri: Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: {
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': false,
        },
      );
      return json['choices']?[0]?['message']?['content'] as String? ??
          'AI 未返回有效回复';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  /// 生成攻略
  Future<String> generateItinerary({
    required String userRequest,
    required List<ChatMessage> history,
    String? userProfile,
    String? ragContext,
  }) async {
    final taskInstruction =
        await _loadPrompt('generate_itinerary.txt');
    return await sendMessage(
      userMessage: userRequest,
      history: history,
      userProfile: userProfile,
      ragContext: ragContext,
      taskInstruction: taskInstruction,
      temperature: 0.3,
      maxTokens: 4096,
    );
  }

  /// 主动推荐目的地
  Future<String> recommendDestination({
    required String userProfile,
    String? ragContext,
  }) async {
    final taskInstruction =
        await _loadPrompt('recommend_destination.txt');
    return await sendMessage(
      userMessage: '请根据我的旅行档案，给我推荐一个下次旅行的目的地。',
      history: [],
      userProfile: userProfile,
      ragContext: ragContext,
      taskInstruction: taskInstruction,
      temperature: 0.7,
      maxTokens: 512,
    );
  }

  /// 攻略转日记
  Future<String> generateDiaryFromItinerary({
    required String itineraryItems,
    required String destination,
    required String dateRange,
    required int people,
  }) async {
    var taskInstruction =
        await _loadPrompt('diary_from_itinerary.txt');
    taskInstruction = taskInstruction
        .replaceAll('{itinerary_items}', itineraryItems)
        .replaceAll('{destination}', destination)
        .replaceAll('{date_range}', dateRange)
        .replaceAll('{people}', people.toString());

    final result = await sendMessage(
      userMessage: '请根据以上行程流水账，帮我改写成一篇生动、口语化的游记日记。',
      history: [],
      taskInstruction: taskInstruction,
      temperature: 0.7,
      maxTokens: 2048,
    );
    // 清理 AI 可能返回的 suggestions 标签
    return result.replaceAll(
        RegExp(r'\[suggestions\].*?\[/suggestions\]', dotAll: true),
        '').trim();
  }

  /// 从 AI 回复中提取追问建议
  static List<String> parseFollowUpSuggestions(String content) {
    final suggestions = <String>[];
    final regex = RegExp(
        r'\[suggestions\](.*?)\[/suggestions\]',
        dotAll: true);
    final match = regex.firstMatch(content);
    if (match != null) {
      final lines = match.group(1)!.split('\n');
      for (final line in lines) {
        final trimmed = line.trim().replaceAll(RegExp(r'^\d+\.\s*'), '');
        if (trimmed.isNotEmpty) {
          suggestions.add(trimmed);
        }
      }
    }
    return suggestions;
  }

  /// 仅移除追问建议标记，保留 itinerary JSON（用于存储）
  static String stripSuggestionsOnly(String content) {
    return content
        .replaceAll(
            RegExp(r'\[suggestions\].*?\[\/suggestions\]', dotAll: true),
            '')
        .trim();
  }

  /// 从 AI 回复中移除追问建议标记，返回干净的正文
  static String cleanContent(String content) {
    var result = stripSuggestionsOnly(content);

    // 移除包含 itinerary 的代码块（兼容有无 json 标签）
    final codeBlockRegex =
        RegExp(r'```(?:json)?\s*(\{[^{}]*\})\s*```', dotAll: true);
    for (final match in codeBlockRegex.allMatches(result)) {
      try {
        final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        if (json['itinerary'] == true) {
          result = result.replaceAll(match.group(0)!, '');
        }
      } catch (_) {}
    }

    // 移除裸 JSON 中包含 itinerary 的块
    final rawJsonRegex = RegExp(r'\{[^{}]*\}', dotAll: true);
    for (final match in rawJsonRegex.allMatches(result)) {
      try {
        final json = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        if (json['itinerary'] == true) {
          result = result.replaceAll(match.group(0)!, '');
        }
      } catch (_) {}
    }

    return result.trim();
  }

  /// 从 AI 回复中提取 itinerary JSON 元数据
  /// 返回 {destination, days, total_budget} 或 null
  static Map<String, dynamic>? extractItineraryMeta(String content) {
    // 尝试从代码块中提取（兼容有无 json 标签）
    final codeBlockRegex =
        RegExp(r'```(?:json)?\s*(\{[^{}]*\})\s*```', dotAll: true);
    for (final match in codeBlockRegex.allMatches(content)) {
      try {
        final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        if (json['itinerary'] == true) return json;
      } catch (_) {}
    }

    // 尝试从裸 JSON 中提取
    final rawJsonRegex = RegExp(r'\{[^{}]*\}', dotAll: true);
    for (final match in rawJsonRegex.allMatches(content)) {
      try {
        final json = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        if (json['itinerary'] == true) return json;
      } catch (_) {}
    }

    return null;
  }

  /// 将 AI 生成的攻略文本解析为结构化的 DayPlan 列表
  static List<DayPlan> parseItineraryText(String content) {
    // 使用 cleanContent 清理标记标签和 itinerary JSON
    final cleaned = cleanContent(content);

    final lines = cleaned.split('\n');
    final dayPlans = <DayPlan>[];
    DayPlan? currentDay;
    List<ItineraryItem> currentItems = [];
    AccommodationInfo? currentAccommodation;
    double currentDailyBudget = 0;
    int dayNumber = 0;

    // 匹配天标题：Day 1: / 第一天: / D1: 等（兼容 Markdown 加粗和标题标记）
    final dayHeaderRegex = RegExp(
      r'[#*\s]*(?:Day\s*(\d+)|D(\d+)|第\s*(\d+)\s*天)[：:\s]*(.*)',
    );
    // 匹配行程项：09:00 ✈️ 抵达成都  或  **09:00** ✈️ 抵达成都
    final itemRegex = RegExp(
      r'\*{0,2}(\d{1,2}[:：]\d{2})\*{0,2}\s*(.*)',
    );

    void commitDay() {
      if (currentDay != null) {
        // 如果未解析到当日预算，从行程项累加计算
        final dailyBudget = currentDailyBudget > 0
            ? currentDailyBudget
            : currentItems.fold<double>(0, (sum, item) => sum + item.cost);
        dayPlans.add(DayPlan(
          dayNumber: currentDay.dayNumber,
          items: currentItems,
          accommodation: currentAccommodation,
          dailyBudget: dailyBudget,
        ));
        currentItems = [];
        currentAccommodation = null;
        currentDailyBudget = 0;
      }
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final dayMatch = dayHeaderRegex.firstMatch(trimmed);
      if (dayMatch != null) {
        commitDay();
        final num = dayMatch.group(1) ??
            dayMatch.group(2) ??
            dayMatch.group(3);
        dayNumber = int.tryParse(num ?? '1') ?? dayNumber + 1;
        currentDay = DayPlan(dayNumber: dayNumber, items: []);
        continue;
      }

      if (currentDay == null) continue;

      // 住宿行
      if (trimmed.contains('🏨') ||
          trimmed.toLowerCase().contains('住宿')) {
        currentAccommodation = _parseAccommodationLine(trimmed);
        continue;
      }

      // 当日预算行
      if (trimmed.contains('💰') ||
          (trimmed.contains('当日预算') || trimmed.contains('日预算'))) {
        final costMatch = RegExp(r'(\d+)').firstMatch(trimmed);
        if (costMatch != null) {
          currentDailyBudget =
              double.tryParse(costMatch.group(1)!) ?? 0;
        }
        continue;
      }

      // 行程项行
      // 去除行首的列表标记和 Markdown 加粗标记 - * • # **
      final itemLine = trimmed
          .replaceAll(RegExp(r'^[-*•#]+\s*'), '')
          .trim();
      final itemMatch = itemRegex.firstMatch(itemLine);
      if (itemMatch != null) {
        final time = itemMatch.group(1)!.replaceAll('：', ':');
        final rest = itemMatch.group(2) ?? '';

        // 提取 emoji（首个非空白字符如果是非常规字符，含变体选择符）
        String emoji = '';
        String title = rest.trim();
        // 使用码点判断开头的 emoji（兼容单码点和带变体选择符的多码点 emoji）
        if (title.isNotEmpty) {
          final runes = title.runes.toList();
          final first = runes[0];
          bool isEmoji(int cp) =>
              (cp >= 0x1F000 && cp <= 0x1FFFF) ||
              (cp >= 0x2600 && cp <= 0x27BF) ||
              (cp >= 0x2190 && cp <= 0x21FF) ||
              (cp >= 0x2B00 && cp <= 0x2BFF);
          bool isVariationSelector(int cp) =>
              (cp >= 0xFE00 && cp <= 0xFE0F) ||
              (cp >= 0x1F3FB && cp <= 0x1F3FF);
          if (isEmoji(first)) {
            emoji = String.fromCharCodes([first]);
            if (runes.length > 1 && isVariationSelector(runes[1])) {
              emoji += String.fromCharCodes([runes[1]]);
            }
            title = title.substring(emoji.length).trim();
          }
        }

        // 去除 Markdown 加粗标记
        title = title.replaceAll('**', '').trim();

        // 提取括号内备注信息（如：（打车约30元）、（免费）、（约200元））
        String? note;
        final noteRegex = RegExp(r'[（(]([^）)]*)[）)]');
        final noteMatches = noteRegex.allMatches(title);
        if (noteMatches.isNotEmpty) {
          note = noteMatches.map((m) => m.group(1)!.trim()).join('；');
          // 从标题中移除括号内容
          title = title.replaceAll(noteRegex, '').trim();
        }

        // 从备注中提取费用
        double cost = 0;
        if (note != null) {
          final costMatch = RegExp(
            r'(?:约|~|大概|≈)?\s*(\d+)\s*元',
          ).firstMatch(note);
          if (costMatch != null) {
            cost = double.tryParse(costMatch.group(1)!) ?? 0;
          }
        }

        if (title.isNotEmpty) {
          currentItems.add(ItineraryItem(
            time: time,
            emoji: emoji,
            title: title,
            cost: cost,
            note: note,
          ));
        }
      }
    }

    commitDay();
    // 最后一天默认无住宿（旅行最后一天通常已返程，无需住宿）
    if (dayPlans.length > 1) {
      final lastDay = dayPlans.last;
      if (lastDay.accommodation != null) {
        dayPlans[dayPlans.length - 1] = DayPlan(
          dayNumber: lastDay.dayNumber,
          date: lastDay.date,
          items: lastDay.items,
          accommodation: null,
          dailyBudget: lastDay.dailyBudget,
        );
      }
    }
    return dayPlans;
  }

  /// 解析住宿行，提取酒店名称和价格，过滤掉预算汇总类文本
  static AccommodationInfo? _parseAccommodationLine(String line) {
    String text = line
        .replaceAll(RegExp(r'^[-*\s]*🏨\s*'), '')
        .replaceAll(RegExp(r'^[-*\s]*住宿[\s·・::：]*'), '')
        .trim();
    final hasBudgetCalc = text.contains('当日预算') ||
        text.contains('预算') ||
        RegExp(r'\d+\s*[+]\s*\d+').hasMatch(text) ||
        text.contains('车费') ||
        text.contains('餐费');
    if (hasBudgetCalc) return null;
    double cost = 0;
    final costMatch = RegExp(r'[¥￥]\s*(\d+)|(\d+)\s*元').firstMatch(text);
    if (costMatch != null) {
      cost = double.tryParse(costMatch.group(1) ?? costMatch.group(2) ?? '') ?? 0;
    }
    String type = '酒店';
    if (text.contains('民宿') || text.contains('客栈')) {
      type = '民宿';
    } else if (text.contains('青旅') || text.contains('青年旅舍')) {
      type = '青旅';
    }
    String name = text
        .replaceAll(RegExp(r'[¥￥]\d+[^\s）。]*'), '')
        .replaceAll(RegExp(r'\d+\s*元[/每]?[人晚夜]?'), '')
        .replaceAll(RegExp(r'[(（][^)）]*[)）]'), '')
        .replaceAll(RegExp(r'酒店|民宿|青旅|青年旅舍|客栈'), '')
        .trim();
    if (name.isEmpty) return null;
    return AccommodationInfo(type: type, name: name, cost: cost);
  }

}

/// P1-2.11：API 测试结果
enum AiTestErrorType { invalidKey, insufficientBalance, rateLimit, timeout, network, unknown }

class AiTestResult {
  final bool success;
  final String? model;
  final AiTestErrorType? errorType;

  const AiTestResult({required this.success, this.model, this.errorType});

  String get message {
    if (success) return '连接成功（$model）';
    switch (errorType) {
      case AiTestErrorType.invalidKey:
        return 'API 密钥无效或已过期';
      case AiTestErrorType.insufficientBalance:
        return '账户余额不足';
      case AiTestErrorType.rateLimit:
        return '请求过于频繁，请稍后再试';
      case AiTestErrorType.timeout:
        return '连接超时，请检查网络';
      case AiTestErrorType.network:
        return '网络连接失败';
      default:
        return '连接失败';
    }
  }
}

/// List 扩展用于取最近 N 条
extension _ListExtension<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
