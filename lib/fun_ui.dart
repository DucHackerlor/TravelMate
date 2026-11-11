import 'package:flutter/material.dart';

/// Bang mau + widget "vui nhon" dung chung cho toan app.
/// Khong dung package ngoai; chi dung emoji va animation huu han
/// (khong lap vo han de khong lam treo pumpAndSettle trong test).

const sunYellow = Color(0xFFFFC83D);
const sunSoft = Color(0xFFFFE9A8);
const coral = Color(0xFFFF6B6B);
const skyBlue = Color(0xFF4DABF7);
const grape = Color(0xFF9B6BFF);
const bubblegum = Color(0xFFFF7EB6);
const tangerine = Color(0xFFFF9F43);

/// Mot bo mau gom 2 mau chuyen sac, mau nen nhat va mau bong do.
class FunPalette {
  final Color a;
  final Color b;
  final Color soft;
  final Color shadow;
  const FunPalette(this.a, this.b, this.soft, this.shadow);

  LinearGradient get gradient => LinearGradient(
        colors: [a, b],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

const funPalettes = <FunPalette>[
  FunPalette(Color(0xFF1FD18A), Color(0xFF08995A), Color(0xFFDDF7E8), Color(0x5506A65F)), // xanh la
  FunPalette(Color(0xFF5CC0FF), Color(0xFF2F80ED), Color(0xFFDCEEFF), Color(0x552F80ED)), // xanh troi
  FunPalette(Color(0xFFFF9A3C), Color(0xFFFF5E62), Color(0xFFFFE6D2), Color(0x55FF5E62)), // hoang hon
  FunPalette(Color(0xFFB18CFF), Color(0xFF6C5CE7), Color(0xFFEBE3FF), Color(0x556C5CE7)), // tim
  FunPalette(Color(0xFFFF8FC0), Color(0xFFE8478F), Color(0xFFFFE0EE), Color(0x55E8478F)), // hong
  FunPalette(Color(0xFF3CD6C9), Color(0xFF0E9AA7), Color(0xFFD9F7F4), Color(0x550E9AA7)), // ngoc
];

int _hash(String s) =>
    s.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff);

/// Cung mot diem den luon ra cung mot bo mau.
FunPalette paletteFor(String seed) => funPalettes[_hash(seed) % funPalettes.length];

const _fallbackEmojis = ['🧳', '🌍', '🎒', '📸', '🌴', '🚀'];

const _emojiRules = <List<Object>>[
  [['đà lạt', 'da lat', 'sapa', 'sa pa', 'hà giang', 'ha giang', 'tà xùa', 'ta xua', 'núi', 'nui', 'mountain', 'fansipan', 'mộc châu', 'moc chau', 'rừng', 'forest', 'camping'], '🏔️'],
  [['biển', 'bien', 'beach', 'sea', 'đà nẵng', 'da nang', 'nha trang', 'vũng tàu', 'vung tau', 'quy nhơn', 'quy nhon', 'mũi né', 'mui ne'], '🏖️'],
  [['phú quốc', 'phu quoc', 'côn đảo', 'con dao', 'đảo', 'island', 'cát bà', 'cat ba'], '🏝️'],
  [['hà nội', 'ha noi', 'hanoi', 'huế', 'hue', 'hội an', 'hoi an', 'temple', 'chùa', 'đền'], '🏯'],
  [['sài gòn', 'sai gon', 'hồ chí minh', 'ho chi minh', 'saigon', 'city', 'thành phố'], '🌆'],
  [['tokyo', 'japan', 'nhật', 'osaka', 'kyoto'], '🗼'],
  [['seoul', 'korea', 'hàn quốc', 'busan'], '🌸'],
  [['paris', 'france', 'pháp'], '🥐'],
  [['bangkok', 'thái', 'thailand', 'phuket'], '🛕'],
  [['singapore'], '🦁'],
];

/// Chon emoji hop voi diem den (theo tu khoa), khong khop thi chon theo hash.
String emojiForDestination(String text) {
  final t = text.toLowerCase();
  for (final rule in _emojiRules) {
    final keywords = rule[0] as List<String>;
    if (keywords.any(t.contains)) return rule[1] as String;
  }
  return _fallbackEmojis[_hash(t) % _fallbackEmojis.length];
}

/// Nhan nhe khi cham: co lai mot chut roi bat ra (hieu ung "boing").
class Pressable extends StatefulWidget {
  final Widget child;
  final double scale;
  const Pressable({super.key, required this.child, this.scale = .96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      );
}

/// Hieu ung hien ra: truot len + mo dan, co nay nhe (easeOutBack).
/// `index` cang lon thi xuat hien cang tre (khong dung Timer).
class PopIn extends StatelessWidget {
  final int index;
  final Widget child;
  const PopIn({super.key, this.index = 0, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + index * 110),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(offset: Offset(0, (1 - v) * 28), child: child),
        ),
        child: child,
      );
}

/// O vuong bo goc chua mot emoji, nghieng nhe nhu mieng sticker.
class EmojiBadge extends StatelessWidget {
  final String emoji;
  final double size;
  final Color color;
  final double angle;
  const EmojiBadge({
    super.key,
    required this.emoji,
    this.size = 52,
    this.color = sunSoft,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size * .34),
          ),
          child: Text(emoji, style: TextStyle(fontSize: size * .52, height: 1)),
        ),
      );
}

/// Mau + emoji cho tung loai hoat dong.
Color activityTone(String category) {
  switch (category) {
    case 'food':
      return const Color(0xFFE8730C);
    case 'sightseeing':
      return const Color(0xFF1C7ED6);
    case 'transport':
      return const Color(0xFF7048E8);
    case 'stay':
      return const Color(0xFFD6336C);
    case 'shopping':
      return const Color(0xFFC77D00);
    default:
      return const Color(0xFF06A65F);
  }
}

String activityEmoji(String category) {
  switch (category) {
    case 'food':
      return '🍜';
    case 'sightseeing':
      return '🏞️';
    case 'transport':
      return '🚗';
    case 'stay':
      return '🏨';
    case 'shopping':
      return '🛍️';
    default:
      return '📌';
  }
}
