class TbdexError extends Error {
  final String message;
  final String? code;
  final dynamic details;

  TbdexError(this.message, {this.code, this.details});

  @override
  String toString() {
    return 'TbdexError: $message${code != null ? ' (Code: $code)' : ''}';
  }
}
