class PackingItem {
  final String id;
  String name;
  bool done;
  PackingItem({required this.id, required this.name, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'done': done};
  factory PackingItem.fromJson(Map<String, dynamic> json) => PackingItem(
        id: '${json['id'] ?? newId()}',
        name: '${json['name'] ?? ''}',
        done: json['done'] == true,
      );
}

class Activity {
  final String id;
  String title;
  String location;
  String notes;
  String category;
  DateTime at;
  Activity({required this.id, required this.title, required this.at,
    this.location = '', this.notes = '', this.category = 'other'});

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'location': location,
        'notes': notes, 'category': category, 'at': at.toIso8601String(),
      };
  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: '${json['id'] ?? newId()}',
        title: '${json['title'] ?? ''}',
        location: '${json['location'] ?? ''}',
        notes: '${json['notes'] ?? ''}',
        category: '${json['category'] ?? 'other'}',
        at: DateTime.parse(json['at'] as String),
      );
}

class Trip {
  final String id;
  String name;
  String destination;
  DateTime start;
  DateTime end;
  final List<Activity> activities;
  final List<PackingItem> packing;
  /// Số tiền VND dự kiến, chỉ dùng để lập kế hoạch chứ không ghi nhận giao dịch.
  final Map<String, int> plannedCosts;

  Trip({required this.id, required this.name, required this.destination,
    required this.start, required this.end,
    List<Activity>? activities, List<PackingItem>? packing,
    Map<String, int>? plannedCosts})
      : activities = activities ?? [], packing = packing ?? [],
        plannedCosts = plannedCosts ?? {};

  int get dayCount => dateOnly(end).difference(dateOnly(start)).inDays + 1;
  int get preparedCount => packing.where((x) => x.done).length;
  int get plannedTotal => plannedCosts.values.fold(0, (sum, amount) => sum + amount);

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'destination': destination,
        'start': start.toIso8601String(), 'end': end.toIso8601String(),
        'activities': activities.map((x) => x.toJson()).toList(),
        'packing': packing.map((x) => x.toJson()).toList(),
        'plannedCosts': plannedCosts,
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final packingRaw = (json['packing'] as List?) ?? [];
    return Trip(
      id: '${json['id'] ?? newId()}',
      name: '${json['name'] ?? ''}',
      destination: '${json['destination'] ?? ''}',
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      activities: ((json['activities'] as List?) ?? [])
          .map((x) => Activity.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList(),
      // Chi phí cũ chưa có trường này sẽ hiển thị các khoản bằng 0.
      plannedCosts: ((json['plannedCosts'] as Map?) ?? {}).map(
        (key, value) => MapEntry('$key', value is num && value >= 0 ? value.toInt() : 0),
      ),
      // Tương thích với phiên bản 1.0 lưu packing dưới dạng List<String>.
      packing: packingRaw.map((x) {
        if (x is String) return PackingItem(id: newId(), name: x);
        return PackingItem.fromJson(Map<String, dynamic>.from(x as Map));
      }).toList(),
    );
  }
}

int _nextId = 0;
String newId() => '${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String formatTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

List<Activity> activitiesOn(Trip trip, DateTime date) =>
    trip.activities.where((x) => sameDay(x.at, date)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
