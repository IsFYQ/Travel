import 'dart:convert';

/// 旅行日记模型
class TravelRecord {
  final String id;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final int people;
  final String tripType;
  final String transportType;
  final List<String> tags;
  final String content;
  final String? coverImagePath;
  final String? summary;
  final double totalCost;
  final double rating;
  // P1-3.14：五维评分
  final double ratingScenery;
  final double ratingFood;
  final double ratingStay;
  final double ratingTransport;
  final double ratingValue;
  final bool isHidden;
  // P1-3.5：同步与软删字段
  final String origin;
  final String? contentHash;
  final DateTime? deletedAt;
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
    this.ratingScenery = 0,
    this.ratingFood = 0,
    this.ratingStay = 0,
    this.ratingTransport = 0,
    this.ratingValue = 0,
    this.isHidden = false,
    this.origin = 'local',
    this.contentHash,
    this.deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// P1-3.14：五维评分映射
  Map<String, double> get dimensionRatings => {
        'scenery': ratingScenery,
        'food': ratingFood,
        'stay': ratingStay,
        'transport': ratingTransport,
        'value': ratingValue,
      };

  /// 有效综合分：五维有值时用均值，否则回退 rating
  double get effectiveRating {
    final dims = dimensionRatings.values.where((v) => v > 0).toList();
    if (dims.isNotEmpty) {
      return dims.reduce((a, b) => a + b) / dims.length;
    }
    return rating;
  }

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
      'rating_scenery': ratingScenery,
      'rating_food': ratingFood,
      'rating_stay': ratingStay,
      'rating_transport': ratingTransport,
      'rating_value': ratingValue,
      'is_hidden': isHidden ? 1 : 0,
      'origin': origin,
      'content_hash': contentHash,
      'deleted_at': deletedAt?.toIso8601String(),
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
      ratingScenery: (map['rating_scenery'] as num?)?.toDouble() ?? 0,
      ratingFood: (map['rating_food'] as num?)?.toDouble() ?? 0,
      ratingStay: (map['rating_stay'] as num?)?.toDouble() ?? 0,
      ratingTransport: (map['rating_transport'] as num?)?.toDouble() ?? 0,
      ratingValue: (map['rating_value'] as num?)?.toDouble() ?? 0,
      isHidden: (map['is_hidden'] as int?) == 1,
      origin: map['origin'] as String? ?? 'local',
      contentHash: map['content_hash'] as String?,
      deletedAt: map['deleted_at'] != null
          ? DateTime.tryParse(map['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

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
    double? ratingScenery,
    double? ratingFood,
    double? ratingStay,
    double? ratingTransport,
    double? ratingValue,
    bool? isHidden,
    String? origin,
    String? contentHash,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
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
      ratingScenery: ratingScenery ?? this.ratingScenery,
      ratingFood: ratingFood ?? this.ratingFood,
      ratingStay: ratingStay ?? this.ratingStay,
      ratingTransport: ratingTransport ?? this.ratingTransport,
      ratingValue: ratingValue ?? this.ratingValue,
      isHidden: isHidden ?? this.isHidden,
      origin: origin ?? this.origin,
      contentHash: contentHash ?? this.contentHash,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
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
