import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/error_mapper.dart';
import '../exceptions/missing_credential_exception.dart';
import '../models/travel_record.dart';
import '../services/database_service.dart';

/// IMA 知识库同步服务
class ImaSyncService {
  static final ImaSyncService _instance = ImaSyncService._internal();
  factory ImaSyncService() => _instance;
  ImaSyncService._internal();

  static const String _baseUrl = 'https://ima.qq.com';
  static const _storage = FlutterSecureStorage();
  static const String _clientIdKey = 'ima_client_id';
  static const String _apiKeyKey = 'ima_api_key';
  static const String _knowledgeBaseIdKey = 'ima_knowledge_base_id';
  /// 官方 Skill 客户端必带；格式须为 skill_version=x.y.z（见 ima_api.cjs）
  static const String _openapiCtx = 'skill_version=1.1.7';
  static const _uuid = Uuid();

  final _db = DatabaseService();

  // ========== 凭证管理 ==========

  Future<void> saveCredentials({
    required String clientId,
    required String apiKey,
  }) async {
    // 去除首尾空格，避免复制凭证时带入不可见字符导致鉴权失败
    await _storage.write(key: _clientIdKey, value: clientId.trim());
    await _storage.write(key: _apiKeyKey, value: apiKey.trim());
  }

  Future<void> saveKnowledgeBaseId(String id) async {
    await _storage.write(key: _knowledgeBaseIdKey, value: id);
  }

  Future<String?> getTravelKnowledgeBaseId() async {
    final id = await _storage.read(key: _knowledgeBaseIdKey);
    return (id != null && id.isNotEmpty) ? id : null;
  }

  /// P0-5：未配置时返回 null 值，不再回落硬编码
  Future<Map<String, String?>> getCredentials() async {
    final clientId = await _storage.read(key: _clientIdKey);
    final apiKey = await _storage.read(key: _apiKeyKey);
    return {'clientId': clientId, 'apiKey': apiKey};
  }

  Future<bool> hasCredentials() async {
    final creds = await getCredentials();
    return creds['clientId'] != null &&
        creds['clientId']!.isNotEmpty &&
        creds['apiKey'] != null &&
        creds['apiKey']!.isNotEmpty;
  }

  Future<bool> hasFullConfig() async {
    if (!await hasCredentials()) return false;
    final kbId = await getTravelKnowledgeBaseId();
    return kbId != null && kbId.isNotEmpty;
  }

  Future<void> _ensureApiCredentials() async {
    if (!await hasCredentials()) {
      throw MissingCredentialException('IMA', '请先在 IMA 同步设置中配置 Client ID 与 API Key');
    }
  }

  Future<void> _ensureKnowledgeBaseId() async {
    await _ensureApiCredentials();
    if (!await hasFullConfig()) {
      throw MissingCredentialException('IMA', '请先在 IMA 同步设置中选择目标知识库');
    }
  }

  Future<Map<String, String>> _buildHeaders({
    String? clientId,
    String? apiKey,
  }) async {
    final creds = (clientId != null && apiKey != null)
        ? {'clientId': clientId.trim(), 'apiKey': apiKey.trim()}
        : await getCredentials();
    final storedClientId = creds['clientId']?.trim();
    final storedApiKey = creds['apiKey']?.trim();
    if (storedClientId == null ||
        storedClientId.isEmpty ||
        storedApiKey == null ||
        storedApiKey.isEmpty) {
      throw MissingCredentialException('IMA', '请先在 IMA 同步设置中配置 Client ID 与 API Key');
    }
    return {
      'Content-Type': 'application/json',
      'ima-openapi-clientid': storedClientId,
      'ima-openapi-apikey': storedApiKey,
      // BugFix: 缺少此 Header 时部分环境会直接鉴权失败
      'ima-openapi-ctx': _openapiCtx,
    };
  }

  /// 将 IMA 错误码转为可读提示
  String _formatApiError(Map<String, dynamic> json) {
    final code = json['code'];
    final msg = json['msg']?.toString() ?? '未知错误';
    // BugFix: 200002 = 凭证无效；官网 API Key 只展示一次，常因只填了 Client ID 或用了旧 Key
    if (code == 200002 ||
        code == 20004 ||
        msg.toLowerCase().contains('auth failed') ||
        msg.toLowerCase().contains('skill auth')) {
      return '鉴权失败（$msg）。请确认已同时填写 Client ID 与 API Key'
          '（API Key 生成后只显示一次；若页面只剩 Client ID，需点「删除」后「重新获取」并立刻复制两者）';
    }
    return 'API 返回错误: $msg';
  }

  // ========== HTTP 工具 ==========

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body, {
    String? clientId,
    String? apiKey,
  }) async {
    final headers = await _buildHeaders(clientId: clientId, apiKey: apiKey);
    // P1-3.1：IMA 鉴权失败时 HTTP 401，业务错误码仍在 JSON body 中
    return ApiClient().postJsonLenient(
      uri: Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: body,
    );
  }

  // ========== 知识库模块 ==========

  /// 获取知识库列表（验证连接用）
  /// [clientId]/[apiKey] 可选：传入输入框中的凭证，避免未保存时读到旧值
  Future<ImaResult<List<ImaKnowledgeBase>>> getKnowledgeBaseList({
    String? clientId,
    String? apiKey,
  }) async {
    try {
      final json = await _post(
        '/openapi/wiki/v1/get_addable_knowledge_base_list',
        {'cursor': '', 'limit': 50},
        clientId: clientId,
        apiKey: apiKey,
      );
      if (json['code'] == 0) {
        final list =
            json['data']?['addable_knowledge_base_list'] as List?;
        final bases = (list ?? []).map((item) {
          return ImaKnowledgeBase(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
          );
        }).where((kb) => kb.id.isNotEmpty).toList();
        return ImaResult.success(bases);
      }
      return ImaResult.error(_formatApiError(json));
    } on MissingCredentialException catch (e) {
      return ImaResult.error(e.toString());
    } on ApiException catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    } catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    }
  }

  /// 获取知识库文件夹内容（根目录或子文件夹）
  Future<ImaResult<List<ImaKnowledgeItem>>> getKnowledgeList({
    String? folderId,
    int limit = 50,
  }) async {
    try {
      await _ensureKnowledgeBaseId();
      final kbId = await getTravelKnowledgeBaseId();
      final body = <String, dynamic>{
        'cursor': '',
        'limit': limit,
        'knowledge_base_id': kbId,
      };
      if (folderId != null && folderId.isNotEmpty) {
        body['folder_id'] = folderId;
      }
      final json =
          await _post('/openapi/wiki/v1/get_knowledge_list', body);
      if (json['code'] == 0) {
        final list = json['data']?['knowledge_list'] as List?;
        final items = (list ?? []).map((item) {
          return ImaKnowledgeItem(
            mediaId: item['media_id'] as String? ?? '',
            title: item['title'] as String? ?? '',
            mediaType: item['media_type'] as int? ?? 0,
            parentFolderId: item['parent_folder_id'] as String?,
          );
        }).toList();
        return ImaResult.success(items);
      }
      return ImaResult.error('API 返回错误: ${json['msg']}');
    } on MissingCredentialException catch (e) {
      return ImaResult.error(e.toString());
    } on ApiException catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    } catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    }
  }

  // ========== 笔记模块 ==========

  /// 获取笔记完整内容
  Future<ImaResult<String>> getNoteContent(
      {required String noteId}) async {
    try {
      await _ensureApiCredentials();
      final json = await _post('/openapi/note/v1/get_doc_content',
          {'note_id': noteId});
      if (json['code'] == 0) {
        return ImaResult.success(
            json['data']?['content'] as String? ?? '');
      }
      return ImaResult.error('API 返回错误: ${json['msg']}');
    } on MissingCredentialException catch (e) {
      return ImaResult.error(e.toString());
    } on ApiException catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    } catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    }
  }

  /// 创建笔记
  Future<ImaResult<String>> createNote({
    required String content,
    String? folderName,
  }) async {
    try {
      await _ensureApiCredentials();
      final body = <String, dynamic>{
        'content_format': 1,
        'content': content,
      };
      if (folderName != null && folderName.isNotEmpty) {
        body['folder_name'] = folderName;
      }
      final json = await _post('/openapi/note/v1/import_doc', body);
      if (json['code'] == 0) {
        return ImaResult.success(
            json['data']?['note_id'] as String? ?? '');
      }
      return ImaResult.error('API 返回错误: ${json['msg']}');
    } on MissingCredentialException catch (e) {
      return ImaResult.error(e.toString());
    } on ApiException catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    } catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    }
  }

  /// 将笔记添加到知识库
  Future<ImaResult<void>> addToKnowledgeBase({
    required String noteId,
    required String title,
    String? folderId,
  }) async {
    try {
      await _ensureKnowledgeBaseId();
      final kbId = await getTravelKnowledgeBaseId();
      final body = <String, dynamic>{
        'media_type': 11,
        'title': title,
        'knowledge_base_id': kbId,
        'note_info': {'content_id': noteId},
      };
      if (folderId != null && folderId.isNotEmpty) {
        body['folder_id'] = folderId;
      }
      final json =
          await _post('/openapi/wiki/v1/add_knowledge', body);
      if (json['code'] == 0) {
        return ImaResult.success(null);
      }
      return ImaResult.error('API 返回错误: ${json['msg']}');
    } on MissingCredentialException catch (e) {
      return ImaResult.error(e.toString());
    } on ApiException catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    } catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    }
  }

  /// 从知识库中删除条目
  Future<ImaResult<void>> deleteFromKnowledgeBase({
    required String mediaId,
  }) async {
    try {
      await _ensureKnowledgeBaseId();
      final kbId = await getTravelKnowledgeBaseId();
      final body = <String, dynamic>{
        'media_id_list': [mediaId],
        'knowledge_base_id': kbId,
      };
      final json =
          await _post('/openapi/wiki/v1/delete_knowledge', body);
      if (json['code'] == 0) {
        return ImaResult.success(null);
      }
      return ImaResult.error('API 返回错误: ${json['msg']}');
    } on MissingCredentialException catch (e) {
      return ImaResult.error(e.toString());
    } on ApiException catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    } catch (e) {
      return ImaResult.error(ErrorMapper.toUserMessage(e));
    }
  }

  // ========== 同步操作 ==========

  /// 从 IMA「旅游记录」知识库导入所有笔记到本地
  Future<ImaSyncResult> importFromIma({
    void Function(String message)? onProgress,
  }) async {
    int importedCount = 0;
    final errors = <String>[];

    try {
      await _ensureKnowledgeBaseId();
    } on MissingCredentialException catch (e) {
      return ImaSyncResult(importedCount: 0, errors: [e.toString()]);
    }

    onProgress?.call('正在获取知识库目录结构...');
    final rootResult = await getKnowledgeList();
    if (!rootResult.isSuccess) {
      return ImaSyncResult(
          importedCount: 0,
          errors: [rootResult.error ?? '获取目录失败']);
    }

    final rootItems = rootResult.data!;

    // 第二步：收集所有笔记
    final notesToImport = <_NoteTask>[];

    for (final item in rootItems) {
      if (item.isFolder) {
        onProgress?.call('正在扫描文件夹：${item.title}...');
        final folderResult =
            await getKnowledgeList(folderId: item.mediaId);
        if (folderResult.isSuccess) {
          for (final subItem in folderResult.data!) {
            if (subItem.isNote) {
              notesToImport.add(_NoteTask(
                mediaId: subItem.mediaId,
                title: subItem.title,
                destination: item.title,
              ));
            }
          }
        }
        await Future.delayed(const Duration(milliseconds: 200));
      } else if (item.isNote) {
        notesToImport.add(_NoteTask(
          mediaId: item.mediaId,
          title: item.title,
          destination: '',
        ));
      }
    }

    onProgress
        ?.call('发现 ${notesToImport.length} 条笔记，开始导入...');

    // 第三步：通过笔记模块获取每条笔记的完整内容
    for (int i = 0; i < notesToImport.length; i++) {
      final task = notesToImport[i];
      final label = task.destination.isNotEmpty
          ? '${task.destination} - ${task.title}'
          : task.title;
      onProgress?.call(
          '正在导入 (${i + 1}/${notesToImport.length}): $label');

      final noteId = _extractNoteId(task.mediaId);
      if (noteId == null) {
        errors.add('无法解析 note_id: ${task.title}');
        continue;
      }

      final contentResult =
          await getNoteContent(noteId: noteId);
      if (!contentResult.isSuccess) {
        errors.add(
            '读取失败: ${task.title} - ${contentResult.error}');
        continue;
      }

      final record = _parseContentToRecord(
        title: task.title,
        content: contentResult.data!,
        destination: task.destination,
      );

      try {
        await _db.insertRecord(record);
        importedCount++;
      } catch (e) {
        errors.add('保存失败: ${task.title} - $e');
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    onProgress?.call('导入完成！成功 $importedCount 条记录');
    return ImaSyncResult(
        importedCount: importedCount, errors: errors);
  }

  /// 从知识库 media_id 中提取笔记模块的 note_id
  /// media_id: note_{userHash}_{noteId}{folderSuffix}
  /// note_id 是 16 位纯数字
  String? _extractNoteId(String mediaId) {
    if (!mediaId.startsWith('note_')) return null;
    final remainder = mediaId.substring(5);
    final underscoreIdx = remainder.indexOf('_');
    if (underscoreIdx < 0) return null;
    final afterHash = remainder.substring(underscoreIdx + 1);
    final match = RegExp(r'^(\d{16})').firstMatch(afterHash);
    return match?.group(1);
  }

  /// 将笔记内容解析为旅行记录
  TravelRecord _parseContentToRecord({
    required String title,
    required String content,
    required String destination,
  }) {
    final dest = destination.isNotEmpty
        ? destination
        : _extractDestination(title) ?? title;

    final contentBlocks = jsonEncode([
      {'type': 'text', 'data': content},
    ]);

    final dateMatch = RegExp(r'(\d{4})[/\-年](\d{1,2})[/\-月](\d{1,2})')
        .firstMatch(content);
    DateTime? startDate;
    if (dateMatch != null) {
      startDate = DateTime.tryParse(
          '${dateMatch.group(1)}-${dateMatch.group(2)!.padLeft(2, '0')}-${dateMatch.group(3)!.padLeft(2, '0')}');
    }

    return TravelRecord(
      id: _uuid.v4(),
      destination: dest,
      startDate: startDate,
      content: contentBlocks,
      summary: content.length > 200
          ? content.substring(0, 200)
          : content,
    );
  }

  String? _extractDestination(String title) {
    final clean = title
        .replaceAll(RegExp(r'\d{4}[/\-年].*'), '')
        .replaceAll(
            RegExp(r'旅行|游记|攻略|之旅|旅游记录|旅游偏好'), '')
        .trim();
    return clean.isNotEmpty ? clean : null;
  }

  /// 将旅行记录同步到 IMA 知识库（写入）
  Future<ImaResult<void>> syncRecordToIma({
    required TravelRecord record,
    String? folderId,
  }) async {
    // 隐藏记录不参与同步
    if (record.isHidden) {
      return ImaResult.success(null);
    }
    final markdown = _formatRecordAsMarkdown(record);
    final noteResult = await createNote(
        content: markdown, folderName: record.destination);
    if (!noteResult.isSuccess) {
      return ImaResult.error(
          noteResult.error ?? '创建笔记失败');
    }
    return await addToKnowledgeBase(
      noteId: noteResult.data!,
      title:
          '${record.destination} ${record.startDate != null ? "${record.startDate!.year}/${record.startDate!.month}/${record.startDate!.day}" : ""}',
      folderId: folderId,
    );
  }

  String _formatRecordAsMarkdown(TravelRecord record) {
    final buffer = StringBuffer();
    buffer.writeln('# ${record.destination}');
    buffer.writeln();
    if (record.startDate != null) {
      buffer.writeln(
          '📅 时间：${record.startDate!.year}/${record.startDate!.month}/${record.startDate!.day}');
    }
    if (record.endDate != null) {
      buffer.writeln(
          '   ~ ${record.endDate!.year}/${record.endDate!.month}/${record.endDate!.day}');
    }
    buffer.writeln('👥 同行：${record.people}人');
    if (record.totalCost > 0) {
      buffer.writeln(
          '💰 总花费：¥${record.totalCost.toStringAsFixed(0)}');
    }
    if (record.rating > 0) {
      buffer.writeln('⭐ 综合评分：${record.rating}');
    }
    // P1-3.14：五维分项评分
    final dims = <String>[];
    if (record.ratingScenery > 0) dims.add('风景${record.ratingScenery.toInt()}');
    if (record.ratingFood > 0) dims.add('美食${record.ratingFood.toInt()}');
    if (record.ratingStay > 0) dims.add('住宿${record.ratingStay.toInt()}');
    if (record.ratingTransport > 0) dims.add('交通${record.ratingTransport.toInt()}');
    if (record.ratingValue > 0) dims.add('性价比${record.ratingValue.toInt()}');
    if (dims.isNotEmpty) {
      buffer.writeln('📊 分项评分：${dims.join(' ')}');
    }
    if (record.tripType.isNotEmpty) {
      buffer.writeln('🏷️ 类型：${record.tripType}');
    }
    if (record.transportType.isNotEmpty) {
      buffer.writeln('🚗 交通：${record.transportType}');
    }
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(record.textSummary);
    return buffer.toString();
  }

  /// 处理待删除的 IMA 知识库条目
  /// 遍历 pending_ima_deletions 表，尝试匹配知识库中的对应条目并删除
  Future<void> processImaDeletions({
    void Function(String message)? onProgress,
  }) async {
    final pendingIds = await _db.getPendingImaDeletions();
    if (pendingIds.isEmpty) return;

    onProgress?.call('发现 ${pendingIds.length} 条待删除记录，开始处理...');

    // 获取知识库当前内容
    final kbResult = await getKnowledgeList();
    if (!kbResult.isSuccess) {
      onProgress?.call('获取知识库列表失败，跳过删除操作');
      return;
    }

    // 构建标题到 mediaId 的映射
    final titleToMediaId = <String, String>{};
    for (final item in kbResult.data!) {
      titleToMediaId[item.title] = item.mediaId;
      if (item.isFolder) {
        // 获取文件夹内条目
        final folderResult = await getKnowledgeList(folderId: item.mediaId);
        if (folderResult.isSuccess) {
          for (final subItem in folderResult.data!) {
            titleToMediaId[subItem.title] = subItem.mediaId;
          }
        }
      }
    }

    for (final recordId in pendingIds) {
      // 尝试在知识库中找到匹配项
      // 由于本地已删除，我们只能通过 recordId 匹配标题模式
      String? matchedMediaId;
      for (final entry in titleToMediaId.entries) {
        if (entry.key.contains(recordId.substring(0, 8))) {
          matchedMediaId = entry.value;
          break;
        }
      }

      if (matchedMediaId != null) {
        final result = await deleteFromKnowledgeBase(mediaId: matchedMediaId);
        if (result.isSuccess) {
          onProgress?.call('已删除 IMA 知识库条目: $recordId');
        }
      }

      // 清除 pending 记录
      await _db.clearPendingImaDeletion(recordId);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    onProgress?.call('IMA 删除处理完成');
  }
}

// ========== 内部辅助类 ==========

class _NoteTask {
  final String mediaId;
  final String title;
  final String destination;
  _NoteTask({
    required this.mediaId,
    required this.title,
    required this.destination,
  });
}

// ========== 公共数据类 ==========

class ImaResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  ImaResult._({required this.isSuccess, this.data, this.error});
  factory ImaResult.success(T data) =>
      ImaResult._(isSuccess: true, data: data);
  factory ImaResult.error(String error) =>
      ImaResult._(isSuccess: false, error: error);
}

class ImaSyncResult {
  final int importedCount;
  final List<String> errors;
  ImaSyncResult(
      {required this.importedCount, required this.errors});
  bool get hasErrors => errors.isNotEmpty;
}

class ImaKnowledgeBase {
  final String id;
  final String name;
  ImaKnowledgeBase({required this.id, required this.name});
}

class ImaKnowledgeItem {
  final String mediaId;
  final String title;
  final int mediaType;
  final String? parentFolderId;

  bool get isFolder => mediaType == 99;
  bool get isNote =>
      mediaType == 11 || mediaType == 7 || mediaType == 13;

  ImaKnowledgeItem({
    required this.mediaId,
    required this.title,
    this.mediaType = 0,
    this.parentFolderId,
  });
}
