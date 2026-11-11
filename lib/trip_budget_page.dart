import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'trip_store.dart';

const _green = Color(0xFF06A65F);
const _dark = Color(0xFF12352A);
const _muted = Color(0xFF6D8175);

/// Chỉ là BẢNG DỰ KIẾN cho một chuyến đi. Không có giao dịch, thu/chi hay ví tiền.
class PlannedCostCategory {
  final String id;
  final String vi;
  final String en;
  final IconData icon;
  const PlannedCostCategory(this.id, this.vi, this.en, this.icon);
}

const plannedCostCategories = <PlannedCostCategory>[
  PlannedCostCategory('transport', 'Di chuyển', 'Transport', Icons.directions_car_outlined),
  PlannedCostCategory('food', 'Ăn uống', 'Food & drinks', Icons.restaurant_outlined),
  PlannedCostCategory('stay', 'Lưu trú', 'Accommodation', Icons.hotel_outlined),
  PlannedCostCategory('sightseeing', 'Tham quan', 'Sightseeing', Icons.photo_camera_outlined),
  PlannedCostCategory('other', 'Khác', 'Other', Icons.more_horiz_rounded),
];

String formatVnd(int value) {
  final digits = value.toString();
  final result = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) result.write('.');
    result.write(digits[i]);
  }
  return '${result.toString()} ₫';
}

class TripBudgetView extends StatelessWidget {
  final TripStore store;
  final Trip trip;
  const TripBudgetView({super.key, required this.store, required this.trip});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F7EA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBDEED0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.payments_outlined, color: _green),
                const SizedBox(width: 9),
                Text(store.tr('Tổng chi phí dự kiến', 'Estimated trip cost'),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _dark)),
              ]),
              const SizedBox(height: 10),
              Text(formatVnd(trip.plannedTotal),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 30, color: _dark)),
              const SizedBox(height: 5),
              Text(store.tr('Chỉ để lên kế hoạch, không phải theo dõi thu chi.',
                'For planning only — not an expense tracker.'),
                style: const TextStyle(color: _muted, fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(store.tr('Dự toán theo hạng mục', 'Budget by category'),
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(height: 10),
        ...plannedCostCategories.map((category) {
          final amount = trip.plannedCosts[category.id] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _editPlannedCost(context, category),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F7EB),
                        borderRadius: BorderRadius.circular(15)),
                      child: Icon(category.icon, color: _green),
                    ),
                    const SizedBox(width: 13),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.tr(category.vi, category.en),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _dark)),
                        const SizedBox(height: 4),
                        Text(formatVnd(amount),
                          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600)),
                      ],
                    )),
                    const Icon(Icons.edit_outlined, color: _green, size: 21),
                  ]),
                ),
              ),
            ),
          );
        }),
      ],
      ),
    );
  }

  Future<void> _editPlannedCost(BuildContext context, PlannedCostCategory category) async {
    final controller = TextEditingController(
      text: (trip.plannedCosts[category.id] ?? 0).toString(),
    );
    final key = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(store.tr('Dự kiến: ${category.vi}', 'Estimate: ${category.en}')),
          content: SizedBox(
            width: 390,
            child: Form(
              key: key,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: store.tr('Số tiền dự kiến (VND)', 'Planned amount (VND)'),
                  prefixIcon: const Icon(Icons.currency_exchange_outlined),
                  suffixText: '₫',
                ),
                validator: (v) {
                  final amount = int.tryParse((v ?? '').trim());
                  if (amount == null || amount < 0 || amount > 1000000000) {
                    return store.tr('Nhập từ 0 đến 1 tỷ đồng', 'Enter 0 to 1 billion VND');
                  }
                  return null;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(store.tr('Hủy', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (!(key.currentState?.validate() ?? false)) return;
                trip.plannedCosts[category.id] = int.parse(controller.text.trim());
                store.persist();
                Navigator.pop(dialogContext);
              },
              child: Text(store.tr('Lưu dự kiến', 'Save estimate')),
            ),
          ],
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      controller.dispose();
    }
  }
}
