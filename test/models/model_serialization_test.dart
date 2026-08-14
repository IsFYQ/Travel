import 'package:flutter_test/flutter_test.dart';
import 'package:travel/models/travel_record.dart';
import 'package:travel/models/itinerary.dart';
import 'package:travel/models/itinerary_item.dart';
import 'package:travel/models/accommodation_info.dart';
import 'package:travel/models/user_profile.dart';
import 'package:travel/models/chat_message.dart';
import 'package:travel/services/ai_service.dart';

void main() {
  group('TravelRecord 序列化', () {
    test('toMap/fromMap 往返一致', () {
      final record = TravelRecord(
        id: 'r1',
        destination: '贵阳',
        tags: ['美食'],
        ratingScenery: 4,
      );
      final restored = TravelRecord.fromMap(record.toMap());
      expect(restored.id, record.id);
      expect(restored.destination, record.destination);
      expect(restored.tags, record.tags);
      expect(restored.ratingScenery, 4);
    });

    test('缺字段时使用默认值', () {
      final restored = TravelRecord.fromMap({
        'id': 'r2',
        'destination': '成都',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      expect(restored.ratingScenery, 0);
      expect(restored.origin, 'local');
      expect(restored.tags, isEmpty);
    });
  });

  group('ItineraryItem 序列化', () {
    test('quickTags 与 sortOrder 兼容', () {
      final item = ItineraryItem(
        time: '09:00',
        title: '景点',
        sortOrder: 2,
        quickTags: ['值得再来'],
      );
      final map = item.toMap();
      final restored = ItineraryItem.fromMap(map);
      expect(restored.sortOrder, 2);
      expect(restored.quickTags, ['值得再来']);
    });

    test('缺失 sortOrder 时用 fallbackIndex', () {
      final restored = ItineraryItem.fromMap(
        {'title': '测试', 'time': '10:00'},
        fallbackIndex: 3,
      );
      expect(restored.sortOrder, 3);
      expect(restored.quickTags, isEmpty);
    });
  });

  group('Itinerary 序列化', () {
    test('dayPlans 往返', () {
      final it = Itinerary(
        id: 'i1',
        destination: '丽江',
        dayPlans: [
          DayPlan(
            dayNumber: 1,
            items: [ItineraryItem(time: '09:00', title: '古城')],
          ),
        ],
      );
      final restored = Itinerary.fromMap(it.toMap());
      expect(restored.destination, '丽江');
      expect(restored.dayPlans.first.items.first.title, '古城');
    });
  });

  group('AccommodationInfo', () {
    test('fromMap 兼容旧数据', () {
      final acc = AccommodationInfo.fromMap({'name': '如家'});
      expect(acc.name, '如家');
      expect(acc.actualCost, 0);
    });
  });

  group('ChatMessage', () {
    test('displayContent 序列化与 displayText 缓存', () {
      const raw = '你好\n```json\n{"itinerary": true}\n```';
      final msg = ChatMessage(
        id: 'm1',
        sessionId: 's1',
        role: 'assistant',
        content: raw,
        displayContent: '你好',
      );
      final restored = ChatMessage.fromMap(msg.toMap());
      expect(restored.displayContent, '你好');
      expect(restored.displayText(AiService.cleanContent), '你好');

      final uncached = ChatMessage(
        id: 'm2',
        sessionId: 's1',
        role: 'assistant',
        content: raw,
      );
      final cleaned = uncached.displayText(AiService.cleanContent);
      expect(cleaned, '你好');
      expect(uncached.displayText(AiService.cleanContent), cleaned);
    });
  });
}
