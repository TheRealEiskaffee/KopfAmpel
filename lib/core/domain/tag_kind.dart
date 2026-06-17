enum TagKind {
  trigger('trigger'),
  medication('medication');

  const TagKind(this.value);
  final String value;

  static TagKind fromString(String raw) {
    return TagKind.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => TagKind.trigger,
    );
  }
}
