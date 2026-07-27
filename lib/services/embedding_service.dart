import 'dart:convert';
import 'package:http/http.dart' as http';
import 'ai_service.dart';

/// DeepSeek Embedding API 服务
class EmbeddingService {
  static final EmbeddingService _instance = EmbeddingService._internal();
  factory EmbeddingService() => _instance;
  EmbeddingService._internal();

  static const String _baseUrl = 'https://api.deepseek.com';
  final _ai = AiService();

  /// 将文本转换为向量
  Future<List<double>?> embed(String text) async {
    final apiKey = await _ai.getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat', // 使用可用的 embedding 模型
          'input': text,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final embedding = json['data']?[0]?['embedding'] as List?;
        return embedding?.cast<double>();
      }
    } catch (e) {
      // 静默处理
    }
    return null;
  }

  /// 批量向量化
  Future<List<List<double>>?> embedBatch(List<String> texts) async {
    final apiKey = await _ai.getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'input': texts,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List;
        return data
            .map((item) => (item['embedding'] as List).cast<double>())
            .toList();
      }
    } catch (_) {}
    return null;
  }
}
