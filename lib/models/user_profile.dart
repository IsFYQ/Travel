import 'dart:convert';

/// 用户个人信息模型
class UserProfile {
  // ── 基本信息 ──────────────────────────────────
  final String homeCity;   // 居住城市（出发地）
  final String nickname;   // 昵称/称呼

  // ── 偏好标签（多选 + 可自定义） ──────────────
  final List<String> travelStyles; // 旅行风格
  final List<String> foodPrefs;    // 饮食偏好

  // ── 预算偏好（单选） ──────────────────────────
  final BudgetLevel? budgetLevel;

  // ── 出行习惯 ──────────────────────────────────
  final TravelGroupSize? groupSize; // 常见出行人数（单选）
  final List<String> companions;    // 同行对象（多选）

  // ── 忌讳事项（多选 + 可自定义） ──────────────
  final List<String> avoidances;

  const UserProfile({
    this.homeCity = '',
    this.nickname = '',
    this.travelStyles = const [],
    this.foodPrefs = const [],
    this.budgetLevel,
    this.groupSize,
    this.companions = const [],
    this.avoidances = const [],
  });

  factory UserProfile.empty() => const UserProfile();

  Map<String, dynamic> toJson() => {
        'homeCity': homeCity,
        'nickname': nickname,
        'travelStyles': travelStyles,
        'foodPrefs': foodPrefs,
        'budgetLevel': budgetLevel?.name,
        'groupSize': groupSize?.name,
        'companions': companions,
        'avoidances': avoidances,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        homeCity: (json['homeCity'] as String?) ?? '',
        nickname: (json['nickname'] as String?) ?? '',
        travelStyles: List<String>.from(json['travelStyles'] ?? []),
        foodPrefs: List<String>.from(json['foodPrefs'] ?? []),
        budgetLevel: json['budgetLevel'] != null
            ? BudgetLevel.values.byName(json['budgetLevel'] as String)
            : null,
        groupSize: json['groupSize'] != null
            ? TravelGroupSize.values.byName(json['groupSize'] as String)
            : null,
        companions: List<String>.from(json['companions'] ?? []),
        avoidances: List<String>.from(json['avoidances'] ?? []),
      );

  /// 解析 JSON 字符串
  factory UserProfile.fromJsonString(String raw) {
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return UserProfile.empty();
    }
  }

  String toJsonString() => jsonEncode(toJson());

  UserProfile copyWith({
    String? homeCity,
    String? nickname,
    List<String>? travelStyles,
    List<String>? foodPrefs,
    BudgetLevel? budgetLevel,
    bool clearBudgetLevel = false,
    TravelGroupSize? groupSize,
    bool clearGroupSize = false,
    List<String>? companions,
    List<String>? avoidances,
  }) {
    return UserProfile(
      homeCity: homeCity ?? this.homeCity,
      nickname: nickname ?? this.nickname,
      travelStyles: travelStyles ?? this.travelStyles,
      foodPrefs: foodPrefs ?? this.foodPrefs,
      budgetLevel: clearBudgetLevel ? null : (budgetLevel ?? this.budgetLevel),
      groupSize: clearGroupSize ? null : (groupSize ?? this.groupSize),
      companions: companions ?? this.companions,
      avoidances: avoidances ?? this.avoidances,
    );
  }

  /// 是否有有效内容（用于判断是否展示摘要）
  bool get hasContent =>
      homeCity.isNotEmpty ||
      travelStyles.isNotEmpty ||
      budgetLevel != null;

  /// 摘要文本，用于「我的」页面 subtitle
  String get summary {
    final parts = <String>[];
    if (homeCity.isNotEmpty) parts.add(homeCity);
    if (travelStyles.isNotEmpty) parts.add(travelStyles.first);
    if (budgetLevel != null) parts.add(budgetLevel!.shortLabel);
    return parts.isEmpty ? '点击填写个人信息，提升AI推荐准确度' : parts.join(' · ');
  }
}

// ── 预算等级（单选）────────────────────────────
enum BudgetLevel {
  economy,
  comfort,
  quality,
  luxury;

  String get label => const {
        BudgetLevel.economy: '经济型（500元以内）',
        BudgetLevel.comfort: '舒适型（500-1500元）',
        BudgetLevel.quality: '品质型（1500-3000元）',
        BudgetLevel.luxury: '豪华型（3000元以上）',
      }[this]!;

  String get shortLabel => const {
        BudgetLevel.economy: '经济型',
        BudgetLevel.comfort: '舒适型',
        BudgetLevel.quality: '品质型',
        BudgetLevel.luxury: '豪华型',
      }[this]!;
}

// ── 常见出行人数（单选）─────────────────────────
enum TravelGroupSize {
  solo,
  duo,
  small,
  group;

  String get label => const {
        TravelGroupSize.solo: '1人',
        TravelGroupSize.duo: '2人',
        TravelGroupSize.small: '3-4人',
        TravelGroupSize.group: '5人以上',
      }[this]!;
}

// ── 预设选项常量 ────────────────────────────────
class UserProfilePresets {
  static const List<String> travelStyles = [
    '自然风光', '历史人文', '美食探店', '休闲度假',
    '冒险探索', '亲子家庭', '独自旅行', '情侣出行',
  ];

  static const List<String> foodPrefs = [
    '无辣不欢', '清淡为主', '素食友好',
    '海鲜爱好者', '本地特色优先', '不挑食',
  ];

  static const List<String> companions = [
    '独自', '伴侣', '朋友', '家人带娃', '亲子',
  ];

  static const List<String> avoidances = [
    '不爱爬山', '不喜欢人多', '对海鲜过敏',
    '不喜欢长途驾车', '怕高', '晕船',
  ];
}
