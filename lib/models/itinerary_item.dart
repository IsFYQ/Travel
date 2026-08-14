import 'dart:convert';
import 'package:uuid/uuid.dart';

/// 行程项状态
enum ItemStatus {
  pending,
  completed,
  skipped,
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

/// P1-2.4：快评快捷标签常量
class QuickRateTags {
  static const positive = [
    '值得再来',
    '性价比高',
    '景色超美',
    '出片很棒',
    '超出预期',
  ];
  static const negative = [
    '排队久',
    '过度商业化',
    '人太多了',
    '不太推荐',
  ];
  static List<String> get all => [...positive, ...negative];
}

/// 行程项模型
class ItineraryItem {
  final String id;
  final String time;
  final String emoji;
  final String title;
  final double cost;
  final double actualCost;
  final String? note;
  final double rating;
  final ItemStatus status;
  final String? feeling;
  final int sortOrder; // P1-2.3：拖拽排序
  final List<String> quickTags; // P1-2.4：快评标签

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
    this.sortOrder = 0,
    this.quickTags = const [],
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
      'sort_order': sortOrder,
      'quick_tags': quickTags,
    };
  }

  factory ItineraryItem.fromMap(Map<String, dynamic> map, {int? fallbackIndex}) {
    List<String> tags = [];
    if (map['quick_tags'] != null) {
      if (map['quick_tags'] is List) {
        tags = List<String>.from(map['quick_tags']);
      } else if (map['quick_tags'] is String) {
        try {
          tags = List<String>.from(jsonDecode(map['quick_tags'] as String));
        } catch (_) {}
      }
    }
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
      sortOrder: map['sort_order'] as int? ?? fallbackIndex ?? 0,
      quickTags: tags,
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
    int? sortOrder,
    List<String>? quickTags,
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
      sortOrder: sortOrder ?? this.sortOrder,
      quickTags: quickTags ?? this.quickTags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItineraryItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 按 sortOrder 升序排列
List<ItineraryItem> sortItineraryItems(List<ItineraryItem> items) {
  final sorted = List<ItineraryItem>.from(items);
  sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return sorted;
}
