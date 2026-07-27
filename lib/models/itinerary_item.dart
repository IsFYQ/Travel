import 'package:uuid/uuid.dart';

/// 行程项状态
enum ItemStatus {
  pending, // 待完成
  completed, // 已完成
  skipped, // 已跳过
}

extension ItemStatusExtension on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.pending:
        return '待完成';
      case ItemStatus.completed:
        return '已完成';
      case ItemStatus.skipped:
        return '已跳过';
    }
  }

  String get value => name;

  static ItemStatus fromString(String value) {
    return ItemStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemStatus.pending,
    );
  }
}

/// 行程项模型
class ItineraryItem {
  final String id; // P0-11：稳定 ID，用于保存时按 id 合并执行期字段
  final String time; // 时间字符串，如 "09:00"
  final String emoji; // emoji图标
  final String title; // 活动名称
  final double cost; // 预估费用
  final double actualCost; // 实际花费
  final String? note; // 备注
  final double rating; // 快评评分 1-5
  final ItemStatus status; // 状态
  final String? feeling; // 执行过程中的实时感受（一句话备注）

  ItineraryItem({
    String? id,
    required this.time,
    this.emoji = '',
    required this.title,
    this.cost = 0,
    this.actualCost = 0,
    this.note,
    this.rating = 0,
    this.status = ItemStatus.pending,
    this.feeling,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'emoji': emoji,
      'title': title,
      'cost': cost,
      'actual_cost': actualCost,
      'note': note,
      'rating': rating,
      'status': status.value,
      'feeling': feeling,
    };
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'] as String? ?? const Uuid().v4(),
      time: map['time'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '',
      title: map['title'] as String,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      actualCost: (map['actual_cost'] as num?)?.toDouble() ?? 0,
      note: map['note'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      status: ItemStatusExtension.fromString(map['status'] ?? 'pending'),
      feeling: map['feeling'] as String?,
    );
  }

  ItineraryItem copyWith({
    String? time,
    String? emoji,
    String? title,
    double? cost,
    double? actualCost,
    String? note,
    double? rating,
    ItemStatus? status,
    String? feeling,
  }) {
    return ItineraryItem(
      id: id,
      time: time ?? this.time,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      cost: cost ?? this.cost,
      actualCost: actualCost ?? this.actualCost,
      note: note ?? this.note,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      feeling: feeling ?? this.feeling,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          time == other.time &&
          emoji == other.emoji &&
          title == other.title &&
          cost == other.cost &&
          actualCost == other.actualCost &&
          note == other.note &&
          rating == other.rating &&
          status == other.status &&
          feeling == other.feeling;

  @override
  int get hashCode => Object.hash(
        id,
        time,
        emoji,
        title,
        cost,
        actualCost,
        note,
        rating,
        status,
        feeling,
      );
}
