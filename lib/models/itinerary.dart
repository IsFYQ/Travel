import 'dart:convert';
import 'itinerary_item.dart';
import 'accommodation_info.dart';

/// 攻略状态
enum ItineraryStatus {
  planning, // 规划中
  ongoing, // 进行中
  completed, // 已完成
}

extension ItineraryStatusExtension on ItineraryStatus {
  String get label {
    switch (this) {
      case ItineraryStatus.planning:
        return '规划中';
      case ItineraryStatus.ongoing:
        return '进行中';
      case ItineraryStatus.completed:
        return '已完成';
    }
  }

  String get value => name;

  static ItineraryStatus fromString(String value) {
    return ItineraryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItineraryStatus.planning,
    );
  }
}

/// 攻略模型
class Itinerary {
  final String id;
  final String destination;
  final ItineraryStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int days;
  final double totalBudget;
  final int people;
  final String rawContent; // AI 生成的原始文本
  final List<DayPlan> dayPlans;
  final String? sourceChatId; // 来源对话ID
  final String tripType; // 旅行类型
  final DateTime createdAt;
  final DateTime updatedAt;

  Itinerary({
    required this.id,
    required this.destination,
    this.status = ItineraryStatus.planning,
    this.startDate,
    this.endDate,
    this.days = 1,
    this.totalBudget = 0,
    this.people = 1,
    this.rawContent = '',
    this.dayPlans = const [],
    this.sourceChatId,
    this.tripType = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destination': destination,
      'status': status.value,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'days': days,
      'total_budget': totalBudget,
      'people': people,
      'raw_content': rawContent,
      'day_plans': jsonEncode(dayPlans.map((d) => d.toMap()).toList()),
      'source_chat_id': sourceChatId,
      'trip_type': tripType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Itinerary.fromMap(Map<String, dynamic> map) {
    final dayPlansJson = map['day_plans'] != null
        ? List<Map<String, dynamic>>.from(jsonDecode(map['day_plans']))
        : <Map<String, dynamic>>[];

    return Itinerary(
      id: map['id'] as String,
      destination: map['destination'] as String,
      status: ItineraryStatusExtension.fromString(map['status'] ?? 'planning'),
      startDate:
          map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      endDate:
          map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      days: map['days'] as int? ?? 1,
      totalBudget: (map['total_budget'] as num?)?.toDouble() ?? 0,
      people: map['people'] as int? ?? 1,
      rawContent: map['raw_content'] as String? ?? '',
      dayPlans: dayPlansJson.map((d) => DayPlan.fromMap(d)).toList(),
      sourceChatId: map['source_chat_id'] as String?,
      tripType: map['trip_type'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Itinerary copyWith({
    String? destination,
    ItineraryStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? days,
    double? totalBudget,
    int? people,
    String? rawContent,
    List<DayPlan>? dayPlans,
    String? tripType,
  }) {
    return Itinerary(
      id: id,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
      totalBudget: totalBudget ?? this.totalBudget,
      people: people ?? this.people,
      rawContent: rawContent ?? this.rawContent,
      dayPlans: dayPlans ?? this.dayPlans,
      sourceChatId: sourceChatId,
      tripType: tripType ?? this.tripType,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// 每日行程计划
class DayPlan {
  final int dayNumber;
  final DateTime? date;
  final List<ItineraryItem> items;
  final AccommodationInfo? accommodation;
  final double dailyBudget;

  DayPlan({
    required this.dayNumber,
    this.date,
    this.items = const [],
    this.accommodation,
    this.dailyBudget = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'day_number': dayNumber,
      'date': date?.toIso8601String(),
      'items': items.map((i) => i.toMap()).toList(),
      'accommodation': accommodation?.toMap(),
      'daily_budget': dailyBudget,
    };
  }

  factory DayPlan.fromMap(Map<String, dynamic> map) {
    final itemsJson = map['items'] != null
        ? List<Map<String, dynamic>>.from(map['items'])
        : <Map<String, dynamic>>[];

    final accData = map['accommodation'];
    AccommodationInfo? acc;
    if (accData is Map) {
      acc = AccommodationInfo.fromMap(Map<String, dynamic>.from(accData));
    } else if (accData is String && accData.isNotEmpty) {
      acc = AccommodationInfo.fromString(accData);
    }
    return DayPlan(
      dayNumber: map['day_number'] as int,
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      items: sortItineraryItems(itemsJson.asMap().entries
          .map((e) => ItineraryItem.fromMap(e.value, fallbackIndex: e.key))
          .toList()),
      accommodation: acc,
      dailyBudget: (map['daily_budget'] as num?)?.toDouble() ?? 0,
    );
  }
}
