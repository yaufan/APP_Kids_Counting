import 'content.dart';

/// How numbers are said (docs/design.md 「語音」): counting goes 一、二、三;
/// an amount with a measure word says 兩 for 2 (「兩隻小雞」, never 「二隻」).
/// Every line the voice gets has its numbers written in characters, so the
/// phone's voice cannot read a digit the wrong way.
abstract final class Say {
  static const _digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  /// A number as counted: 1 一, 2 二, 10 十, 12 十二, 20 二十.
  static String count(int n) {
    if (n < 0 || n > 99) throw RangeError.range(n, 0, 99);
    if (n < 10) return _digits[n];
    final tens = n ~/ 10, ones = n % 10;
    return '${tens == 1 ? '' : _digits[tens]}十${ones == 0 ? '' : _digits[ones]}';
  }

  /// A number before a measure word: 2 is 兩 (12 and 20 stay 十二, 二十).
  static String amount(int n) => n == 2 ? '兩' : count(n);

  /// 「兩隻小雞」, 「七顆蛋」.
  static String qty(int n, Thing t) => '${amount(n)}${t.unit}${t.zh}';

  /// 「兩隻」 (the thing itself already said).
  static String units(int n, String unit) => '${amount(n)}$unit';

  /// Counting out loud up to [n]: 「一、二、三」.
  static String upTo(int n) => [for (var i = 1; i <= n; i++) count(i)].join('、');

  /// The parent's number sentence (shown, never said): 「4 ＋ 1 ＝ 5」.
  static String sentence(int start, int delta) => delta >= 0 ? '$start ＋ $delta ＝ ${start + delta}' : '$start － ${-delta} ＝ ${start + delta}';

  /// Whether [line] still has a digit in it (the voice must never get one).
  static bool hasDigit(String line) => RegExp(r'[0-9０-９]').hasMatch(line);
}
