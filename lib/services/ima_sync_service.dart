import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/travel_record.dart';
import '../services/database_service.dart';
import '../exceptions/missing_credential_exception.dart';
import 'package:uuid/uuid.dart';

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
  static const _uuid = Uuid();

  final _db = DatabaseService();

  // ========== 凭证管理 ==========

  Future<void> saveCredentials({
    required String clientId,
    required String apiKey,
  }) async {
    await _storage.write(key: _clientIdKey, value: clientId);
    await _storage.write(key: _apiKeyKey, value: apiKey);
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

  Future<Map<String, String>> _buildHeaders() async {
    await _ensureApiCredentials();
    final creds = await getCredentials();
    return {
      'Content-Type': 'application/json',
      'ima-openapi-clientid': creds['clientId']!,
      'ima-openapi-apikey': creds['apiKey']!,
    };
  }

  // ========== HTTP 工具 ==========

  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _buildHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: utf8.encode(jsonEncode(body)),
    );
    return jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
  }

  // ========== 知识库模块 ==========

  /// 获取知识库列表（验证连接用）
  Future<ImaResult<List<ImaKnowledgeBase>>> getKnowledgeBaseList() async {
    try {
      await _ensureApiCredentials();
      final json = await _post(
          '/openapi/wiki/v1/get_addable_knowledge_base_list',
          {'cursor': '', 'limit': 50});
      if (json['code'] == 0) {
        final list =
            json['data']?['addable_knowledge_base_list'] as List?;
        final bases = (list ?? []).map((item) {
          return ImaKnowledgeBase(
            id: item['id'] as String,
            name: item['name'] as String,
          );
        }).toList();
        return ImaResult.success(bases);
      }
      return ImaResult.error('API 返回错误: ${json['msg']}');
    } on MissingCredentialException catch (e) {
      return ImaResult.error(e.toString());
    } catch (e) {
      return ImaResult.error('网络错误: $e');
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
    } catch (e) {
      return ImaResult.error('网络错误: $e');
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
    } catch (e) {
      return ImaResult.error('网络错误: $e');
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
    } catch (e) {
      return ImaResult.error('网络错误: $e');
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
    } catch (e) {
      return ImaResult.error('网络错误: $e');
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
    } catch (e) {
      return ImaResult.error('网络错误: $e');
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
      buffer.writeln('⭐ 评分：${record.rating}');
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
