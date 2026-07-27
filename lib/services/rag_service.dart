import 'dart:math';
import 'embedding_service.dart';

/// RAG 检索服务
class RagService {
  static final RagService _instance = RagService._internal();
  factory RagService() => _instance;
  RagService._internal();

  final _embedding = EmbeddingService();

  // 本地向量存储（简化版，后续可迁移到专业向量数据库）
  final List<VectorDocument> _documents = [];

  /// 添加文档到知识库
  Future<void> addDocument(String content, {String? metadata}) async {
    final embedding = await _embedding.embed(content);
    if (embedding != null) {
      _documents.add(VectorDocument(
        content: content,
        embedding: embedding,
        metadata: metadata,
      ));
    }
  }

  /// 语义检索 Top-K
  Future<List<VectorDocument>> search(String query, {int topK = 3}) async {
    final queryEmbedding = await _embedding.embed(query);
    if (queryEmbedding == null || _documents.isEmpty) {
      return [];
    }

    // 计算余弦相似度并排序
    final scored = _documents.map((doc) {
      final score = _cosineSimilarity(queryEmbedding, doc.embedding);
      return (doc: doc, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topK).map((s) => s.doc).toList();
  }

  /// 构建 RAG 上下文文本
  String buildRagContext(List<VectorDocument> documents) {
    if (documents.isEmpty) return '';

    final buffer = StringBuffer('【相关旅行经历】\n');
    for (final doc in documents) {
      if (doc.metadata != null) {
        buffer.writeln('[${doc.metadata}]');
      }
      buffer.writeln(doc.content);
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// 余弦相似度
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    return denominator == 0 ? 0 : dotProduct / denominator;
  }

  /// 获取知识库文档数量
  int get documentCount => _documents.length;

  /// 清空知识库
  void clear() => _documents.clear();
}

/// 向量文档
class VectorDocument {
  final String content;
  final List<double> embedding;
  final String? metadata;

  VectorDocument({
    required this.content,
    required this.embedding,
    this.metadata,
  });
}
