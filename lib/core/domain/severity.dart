enum Severity {
  none('none'),
  green('green'),
  yellow('yellow'),
  red('red');

  const Severity(this.value);
  final String value;

  static Severity fromString(String raw) {
    return Severity.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => Severity.none,
    );
  }

  bool get hasHeadache => this != Severity.none;
}
