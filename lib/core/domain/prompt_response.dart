enum PromptResponse {
  yes('yes'),
  no('no'),
  ignored('ignored'),
  missed('missed');

  const PromptResponse(this.value);
  final String value;

  static PromptResponse? fromString(String? raw) {
    if (raw == null) return null;
    for (final r in PromptResponse.values) {
      if (r.value == raw) return r;
    }
    return null;
  }
}
