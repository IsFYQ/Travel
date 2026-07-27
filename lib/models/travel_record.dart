import 'dart:convert';

/// 旅行日记模型
class TravelRecord {
  final String id;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final int people;
  final String tripType; // 自然风光/历史人文/美食之旅/亲子游/情侣出行/独自旅行/休闲度假/冒险探索
  final String transportType; // 飞机/高铁/自驾/大巴/轮船/其他 (逗号分隔多选)
  final List<String> tags; // 自定义标签
  final String content; // JSON 格式的富文本内容 [{type: 'text', data: '...'}, {type: 'image', path: '...'}]
  final String? coverImagePath;
  final String? summary;
  final double totalCost;
  final double rating; // 综合评分 1-5
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  TravelRecord({
    required this.id,
    required this.destination,
    this.startDate,
    this.endDate,
    this.people = 1,
    this.tripType = '',
    this.transportType = '',
    this.tags = const [],
    this.content = '[]',
    this.coverImagePath,
    this.summary,
    this.totalCost = 0,
    this.rating = 0,
    this.isHidden = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'people': people,
      'trip_type': tripType,
      'transport_type': transportType,
      'tags': jsonEncode(tags),
      'content': content,
      'cover_image_path': coverImagePath,
      'summary': summary,
      'total_cost': totalCost,
      'rating': rating,
      'is_hidden': isHidden ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TravelRecord.fromMap(Map<String, dynamic> map) {
    return TravelRecord(
      id: map['id'] as String,
      destination: map['destination'] as String,
      startDate:
          map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      endDate:
          map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      people: map['people'] as int? ?? 1,
      tripType: map['trip_type'] as String? ?? '',
      transportType: map['transport_type'] as String? ?? '',
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags']))
          : [],
      content: map['content'] as String? ?? '[]',
      coverImagePath: map['cover_image_path'] as String?,
      summary: map['summary'] as String?,
      totalCost: (map['total_cost'] as num?)?.toDouble() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      isHidden: (map['is_hidden'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// 从富文本内容中提取纯文字摘要
  String get textSummary {
    try {
      final items = List<Map<String, dynamic>>.from(jsonDecode(content));
      final textParts = items
          .where((item) => item['type'] == 'text')
          .map((item) => item['data'] as String)
          .join('');
      return textParts.length > 100
          ? '${textParts.substring(0, 100)}...'
          : textParts;
    } catch (_) {
      return summary ?? '';
    }
  }

  TravelRecord copyWith({
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? people,
    String? tripType,
    String? transportType,
    List<String>? tags,
    String? content,
    String? coverImagePath,
    String? summary,
    double? totalCost,
    double? rating,
    bool? isHidden,
  }) {
    return TravelRecord(
      id: id,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      people: people ?? this.people,
      tripType: tripType ?? this.tripType,
      transportType: transportType ?? this.transportType,
      tags: tags ?? this.tags,
      content: content ?? this.content,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      summary: summary ?? this.summary,
      totalCost: totalCost ?? this.totalCost,
      rating: rating ?? this.rating,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// 可用的旅行类型标签
const List<String> kTripTypes = [
  '自然风景',
  '海岛度假',
  '人文古迹',
  '美食之旅',
  '城市漫步',
  '自驾游',
];

/// 可用的交通方式
const List<String> kTransportTypes = [
  '飞机',
  '高铁',
  '自驾',
  '大巴',
  '出租车',
  '地铁',
];
