import 'package:flutter_test/flutter_test.dart';
import 'package:travelmate/discover_page.dart';
import 'package:travelmate/models.dart';

void main() {
  test('Mẫu lịch trình có đủ ngày và hoạt động', () {
    for (final t in templates) {
      expect(t.activities, isNotEmpty);
      expect(t.activities.every((a) => a.day >= 0 && a.hour >= 0 && a.hour < 24), isTrue);
    }
  });
  test('Giữ loại hoạt động khi chuyển JSON', () {
    final a = Activity(id: 'a', title: 'Ăn sáng', category: 'food',
      at: DateTime(2026, 12, 1, 8));
    final copy = Activity.fromJson(a.toJson());
    expect(copy.category, 'food');
  });
  test('Dữ liệu phiên bản cũ tự nhận loại hoạt động khác', () {
    final a = Activity.fromJson({'id': 'a', 'title': 'Đi chơi', 'location': '',
      'notes': '', 'at': '2026-12-01T08:00:00.000'});
    expect(a.category, 'other');
  });
}
