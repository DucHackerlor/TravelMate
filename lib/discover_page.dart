import 'package:flutter/material.dart';
import 'fun_ui.dart';
import 'models.dart';
import 'trip_store.dart';

const _teal = Color(0xFF06A65F);
const _ink = Color(0xFF12352A);
const _muted = Color(0xFF6D8175);

class TripTemplate {
  final String destination;
  final String enDestination;
  final String headline;
  final String enHeadline;
  final String description;
  final String enDescription;
  final IconData icon;
  final List<TemplateActivity> activities;
  const TripTemplate({required this.destination, required this.enDestination,
    required this.headline, required this.enHeadline,
    required this.description, required this.enDescription,
    required this.icon, required this.activities});
}
class TemplateActivity {
  final int day;
  final int hour;
  final int minute;
  final String title;
  final String enTitle;
  final String category;
  const TemplateActivity(this.day, this.hour, this.minute, this.title, this.enTitle, this.category);
}

const templates = <TripTemplate>[
  TripTemplate(destination: 'Đà Nẵng', enDestination: 'Da Nang',
    headline: 'Biển xanh & bình minh', enHeadline: 'Blue sea & sunrise',
    description: '3 ngày khám phá biển, ẩm thực và phố cổ.',
    enDescription: '3 days of beaches, local food and the old town.',
    icon: Icons.beach_access_rounded, activities: [
      TemplateActivity(0, 8, 0, 'Ăn sáng và cà phê', 'Breakfast and coffee', 'food'),
      TemplateActivity(0, 15, 0, 'Tắm biển Mỹ Khê', 'My Khe beach', 'sightseeing'),
      TemplateActivity(1, 9, 0, 'Khám phá Ngũ Hành Sơn', 'Marble Mountains', 'sightseeing'),
      TemplateActivity(1, 17, 0, 'Dạo phố cổ Hội An', 'Walk around Hoi An', 'sightseeing'),
      TemplateActivity(2, 9, 0, 'Mua quà và trở về', 'Buy gifts and return', 'shopping'),
    ]),
  TripTemplate(destination: 'Đà Lạt', enDestination: 'Da Lat',
    headline: 'Chạm vào sương sớm', enHeadline: 'Misty mornings',
    description: '3 ngày cà phê, thiên nhiên và thư giãn.',
    enDescription: '3 days of coffee, nature and relaxation.',
    icon: Icons.forest_rounded, activities: [
      TemplateActivity(0, 9, 0, 'Cà phê ngắm thung lũng', 'Valley-view coffee', 'food'),
      TemplateActivity(0, 16, 0, 'Dạo Hồ Xuân Hương', 'Walk around Xuan Huong Lake', 'sightseeing'),
      TemplateActivity(1, 8, 0, 'Săn mây buổi sáng', 'Morning cloud watching', 'sightseeing'),
      TemplateActivity(1, 14, 0, 'Tham quan vườn hoa', 'Visit flower gardens', 'sightseeing'),
      TemplateActivity(2, 10, 0, 'Mua đặc sản', 'Shop for specialties', 'shopping'),
    ]),
  TripTemplate(destination: 'Hà Nội', enDestination: 'Hanoi',
    headline: 'Một vòng phố cổ', enHeadline: 'Old Quarter escape',
    description: '2 ngày khám phá văn hóa và ẩm thực.',
    enDescription: '2 days of culture and food discoveries.',
    icon: Icons.temple_buddhist_rounded, activities: [
      TemplateActivity(0, 8, 0, 'Ăn phở buổi sáng', 'Morning pho', 'food'),
      TemplateActivity(0, 10, 0, 'Dạo quanh Hồ Gươm', 'Walk around Hoan Kiem Lake', 'sightseeing'),
      TemplateActivity(0, 19, 0, 'Khám phá phố đi bộ', 'Explore walking streets', 'sightseeing'),
      TemplateActivity(1, 9, 0, 'Tham quan Văn Miếu', 'Temple of Literature', 'sightseeing'),
    ]),
  TripTemplate(destination: 'Phú Quốc', enDestination: 'Phu Quoc',
    headline: 'Nắng vàng đảo ngọc', enHeadline: 'Island sunshine',
    description: '3 ngày nghỉ dưỡng và khám phá biển đảo.',
    enDescription: '3 relaxing days of island adventures.',
    icon: Icons.waves_rounded, activities: [
      TemplateActivity(0, 9, 0, 'Nhận phòng nghỉ dưỡng', 'Resort check-in', 'stay'),
      TemplateActivity(0, 16, 0, 'Ngắm hoàng hôn', 'Watch the sunset', 'sightseeing'),
      TemplateActivity(1, 8, 0, 'Khám phá bãi biển', 'Explore the beach', 'sightseeing'),
      TemplateActivity(1, 18, 0, 'Ăn hải sản', 'Seafood dinner', 'food'),
      TemplateActivity(2, 10, 0, 'Mua quà lưu niệm', 'Buy souvenirs', 'shopping'),
    ]),
];

class DiscoverPage extends StatelessWidget {
  final TripStore store;
  final VoidCallback onCreated;
  const DiscoverPage({super.key, required this.store, required this.onCreated});

  Future<void> _create(BuildContext context, TripTemplate template) async {
    final start = dateOnly(DateTime.now().add(const Duration(days: 7)));
    final days = template.activities.map((e) => e.day).reduce((a, b) => a > b ? a : b) + 1;
    final destination = store.english ? template.enDestination : template.destination;
    final name = store.english ? template.enHeadline : template.headline;
    final trip = Trip(id: newId(), name: name, destination: destination,
      start: start, end: start.add(Duration(days: days - 1)),
      activities: template.activities.map((a) {
        final day = start.add(Duration(days: a.day));
        return Activity(id: newId(), title: store.english ? a.enTitle : a.title,
          at: DateTime(day.year, day.month, day.day, a.hour, a.minute), category: a.category);
      }).toList(),
      packing: [
        PackingItem(id: newId(), name: store.tr('Giấy tờ tùy thân', 'ID / passport')),
        PackingItem(id: newId(), name: store.tr('Sạc điện thoại', 'Phone charger')),
        PackingItem(id: newId(), name: store.tr('Quần áo', 'Clothes')),
      ],
    );
    store.trips.add(trip);
    await store.persist();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(store.tr('Đã tạo lịch trình mẫu. Bạn có thể chỉnh sửa mọi hoạt động.',
          'Template created. You can edit every activity.'))));
      onCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = store.english;
    return LayoutBuilder(builder: (context, bounds) {
      final wide = bounds.maxWidth >= 730;
      return ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 110), children: [
        Text(store.tr('Cảm hứng hành trình 🌏', 'Travel inspiration 🌏'),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 7),
        Text(store.tr('Chọn một lịch trình mẫu và bắt đầu chuyến đi chỉ với một chạm.',
          'Choose a ready-made itinerary and get started in one tap.'),
          style: const TextStyle(color: _muted, height: 1.45)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: wide ? 2 : 1,
            mainAxisSpacing: 14, crossAxisSpacing: 14,
            mainAxisExtent: 285,
          ),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final item = templates[index];
            final title = isEnglish ? item.enHeadline : item.headline;
            final destination = isEnglish ? item.enDestination : item.destination;
            final pal = funPalettes[index % funPalettes.length];
            final emoji = emojiForDestination('${item.enDestination} ${item.destination}');
            return Pressable(child: Container(
              decoration: BoxDecoration(
                gradient: pal.gradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: pal.shadow, blurRadius: 22, offset: const Offset(0, 10))],
              ),
              child: Stack(children: [
                Positioned(right: -10, top: -6, child: Opacity(opacity: .28,
                  child: Transform.rotate(angle: .2,
                    child: Text(emoji, style: const TextStyle(fontSize: 120, height: 1))))),
                Padding(padding: const EdgeInsets.all(22), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    EmojiBadge(emoji: emoji, size: 52, color: Colors.white.withAlpha(60), angle: -.08),
                    const Spacer(),
                    Text(destination.toUpperCase(), style: const TextStyle(
                      fontSize: 12, letterSpacing: 1.8, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 5),
                    Text(title, style: const TextStyle(color: Colors.white,
                      fontSize: 23, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(isEnglish ? item.enDescription : item.description,
                      maxLines: 2, style: const TextStyle(color: Colors.white, height: 1.35)),
                    const SizedBox(height: 13),
                    SizedBox(width: double.infinity, child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white,
                        foregroundColor: pal.b, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => _create(context, item),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(store.tr('Dùng lịch trình này', 'Use this itinerary')),
                    )),
                  ])),
              ]),
            ));
          },
        ),
      ]);
    });
  }
}
