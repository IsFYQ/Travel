import 'package:flutter_test/flutter_test.dart';
import 'package:travel/services/ai_service.dart';

void main() {
  group('AiService 纯函数', () {
    test('parseFollowUpSuggestions 提取追问', () {
      const content = '你好\n[suggestions]\n1. 推荐美食\n2. 交通方式\n[/suggestions]';
      final result = AiService.parseFollowUpSuggestions(content);
      expect(result, ['推荐美食', '交通方式']);
    });

    test('cleanContent 移除 itinerary JSON', () {
      const content = '正文\n```json\n{"itinerary": true, "destination": "成都"}\n```';
      final cleaned = AiService.cleanContent(content);
      expect(cleaned, '正文');
    });

    test('extractItineraryMeta 提取元数据', () {
      const content = '```json\n{"itinerary": true, "destination": "大理", "days": 3}\n```';
      final meta = AiService.extractItineraryMeta(content);
      expect(meta?['destination'], '大理');
      expect(meta?['days'], 3);
    });

    test('parseItineraryText 解析行程项', () {
      const text = '''
Day 1:
09:00 🏛 参观博物馆
🏨 住宿: 如家酒店 ¥200
''';
      final plans = AiService.parseItineraryText(text);
      expect(plans.length, 1);
      expect(plans.first.items.first.title, contains('参观博物馆'));
    });
  });
}
