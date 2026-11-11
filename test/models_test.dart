import 'package:flutter_test/flutter_test.dart';
import 'package:travelmate/models.dart';

void main() {
  test('Tính số ngày chuyến đi đúng', () {
    final trip = Trip(id: '1', name: 'Đà Nẵng', destination: 'Đà Nẵng',
      start: DateTime(2026, 12, 1), end: DateTime(2026, 12, 3));
    expect(trip.dayCount, 3);
  });

  test('Hoạt động được sắp theo giờ', () {
    final trip = Trip(id: '1', name: 'Trip', destination: 'Hanoi',
      start: DateTime(2026, 12, 1), end: DateTime(2026, 12, 3), activities: [
        Activity(id: 'a', title: 'Ăn trưa', at: DateTime(2026, 12, 1, 12)),
        Activity(id: 'b', title: 'Ăn sáng', at: DateTime(2026, 12, 1, 8)),
        Activity(id: 'c', title: 'Ngày khác', at: DateTime(2026, 12, 2, 8)),
      ]);
    expect(activitiesOn(trip, DateTime(2026, 12, 1)).map((e) => e.id).toList(), ['b', 'a']);
  });

  test('JSON giữ trạng thái checklist', () {
    final trip = Trip(id: '1', name: 'Trip', destination: 'Hanoi',
      start: DateTime(2026, 12, 1), end: DateTime(2026, 12, 1),
      packing: [PackingItem(id: 'p', name: 'Passport', done: true)]);
    final restored = Trip.fromJson(trip.toJson());
    expect(restored.packing.single.done, isTrue);
    expect(restored.packing.single.name, 'Passport');
  });

  test('Đọc được dữ liệu checklist phiên bản cũ', () {
    final json = <String, dynamic>{'id': '1', 'name': 'Trip', 'destination': 'Hanoi',
      'start': '2026-12-01T00:00:00.000', 'end': '2026-12-01T00:00:00.000',
      'activities': [], 'packing': ['Passport', 'Camera']};
    expect(Trip.fromJson(json).packing.map((e) => e.name).toList(), ['Passport', 'Camera']);
  });
}
