import 'package:uuid/uuid.dart';

/// 住宿信息模型
class AccommodationInfo {
  final String id; // P0-11：稳定 ID
  final String type; // 酒店、民宿、青旅
  final String name; // 名称
  final String area; // 区域
  final double cost; // 预计花费
  final double actualCost; // 实际花费
  final double rating; // 快评评分 1-5
  final String? feeling; // 一句话备注

  AccommodationInfo({
    String? id,
    this.type = '酒店',
    this.name = '',
    this.area = '',
    this.cost = 0,
    this.actualCost = 0,
    this.rating = 0,
    this.feeling,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'area': area,
      'cost': cost,
      'actual_cost': actualCost,
      'rating': rating,
      'feeling': feeling,
    };
  }

  factory AccommodationInfo.fromMap(Map<String, dynamic> map) {
    return AccommodationInfo(
      id: map['id'] as String? ?? const Uuid().v4(),
      type: map['type'] as String? ?? '酒店',
      name: map['name'] as String? ?? '',
      area: map['area'] as String? ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      actualCost: (map['actual_cost'] as num?)?.toDouble() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      feeling: map['feeling'] as String?,
    );
  }

  /// 从旧格式字符串解析（向后兼容）
  factory AccommodationInfo.fromString(String s) {
    return AccommodationInfo(name: s);
  }

  /// 显示文本
  String get displayText {
    final parts = <String>[];
    if (type.isNotEmpty) parts.add(type);
    if (name.isNotEmpty) parts.add(name);
    if (area.isNotEmpty) parts.add(area);
    final text = parts.join(' · ');
    if (cost > 0) return '$text ¥${cost.toStringAsFixed(0)}';
    return text;
  }

  AccommodationInfo copyWith({
    String? type,
    String? name,
    String? area,
    double? cost,
    double? actualCost,
    double? rating,
    String? feeling,
  }) {
    return AccommodationInfo(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      area: area ?? this.area,
      cost: cost ?? this.cost,
      actualCost: actualCost ?? this.actualCost,
      rating: rating ?? this.rating,
      feeling: feeling ?? this.feeling,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccommodationInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          name == other.name &&
          area == other.area &&
          cost == other.cost &&
          actualCost == other.actualCost &&
          rating == other.rating &&
          feeling == other.feeling;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        name,
        area,
        cost,
        actualCost,
        rating,
        feeling,
      );
}
